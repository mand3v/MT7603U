# This Project is intented to support only for PC and some ARM based Linux Device
#

# Configuration Options
CONFIG_MODULE_SIG=n

# WIFI Mode
ifeq ($(WIFI_MODE),)
#RT28xx_MODE = APSTA
RT28xx_MODE  = STA
else
RT28xx_MODE = $(WIFI_MODE)
endif

ifeq ($(TARGET),)
TARGET = LINUX
endif

# CHIPSET
# mt7603u
ifeq ($(CHIPSET),)
CHIPSET = mt7603u
endif

MODULE = $(word 1, $(CHIPSET))

#OS ABL - YES or NO
OSABL = NO

#Build Prealloc ko
PREALLOC = NO

ifneq ($(TARGET),THREADX)
#RT28xx_DIR = home directory of RT28xx source code
RT28xx_DIR = $(shell pwd)
endif

include $(RT28xx_DIR)/os/linux/config.mk

RTMP_SRC_DIR = $(RT28xx_DIR)/RT$(MODULE)

#PLATFORM: Target platform
PLATFORM = PC

#APSOC
ifeq ($(MODULE),3050)
PLATFORM = RALINK_3050
endif
ifeq ($(MODULE),3052)
PLATFORM = RALINK_3052
endif
ifeq ($(MODULE),3350)
PLATFORM = RALINK_3050
endif
ifeq ($(MODULE),3352)
PLATFORM = RALINK_3352
endif
ifeq ($(CHIPSET),mt7628)
PLATFORM = MT7628
endif

#RELEASE Package
RELEASE = DPA


ifeq ($(TARGET),LINUX)
MAKE = make
endif

ifeq ($(TARGET), UCOS)
MAKE = make
endif
ifeq ($(TARGET),THREADX)
MAKE = gmake
endif

ifeq ($(TARGET), ECOS)
MAKE = make
MODULE = $(shell pwd | sed "s/.*\///" ).o
export MODULE
endif

ifeq ($(PLATFORM),BB_SOC)
LINUX_SRC = $(KERNEL_DIR)
#CROSS_COMPILE = /opt/trendchip/mips-linux-uclibc/usr/bin/mips-linux-uclibc-
endif


ifeq ($(PLATFORM),PC)
# Linux 2.6
LINUX_SRC = /lib/modules/$(shell uname -r)/build
# Linux 2.4 Change to your local setting
#LINUX_SRC = /usr/src/linux-2.4
LINUX_SRC_MODULE = /lib/modules/$(shell uname -r)/kernel/drivers/net/wireless/
CROSS_COMPILE = 
endif


export OSABL RT28xx_DIR RT28xx_MODE LINUX_SRC CROSS_COMPILE CROSS_COMPILE_INCLUDE PLATFORM RELEASE CHIPSET MODULE RTMP_SRC_DIR LINUX_SRC_MODULE TARGET HAS_WOW_SUPPORT

# The targets that may be used.
PHONY += all build_tools test UCOS THREADX LINUX release prerelease clean uninstall install libwapi osabl sdk_build_tools

ifeq ($(TARGET),LINUX)
all: build_tools $(TARGET) plug_in
else
all: $(TARGET)
endif 

build_tools:
	$(MAKE) -C tools
	$(RT28xx_DIR)/tools/bin2h

sdk_build_tools:
	if [ -f $(RT28xx_DIR)/eeprom_log ]; then \
		rm -f $(RT28xx_DIR)/eeprom_log
	fi
	echo $(EE_TYPE) >> eeprom_log
	echo $(CHIPSET) >> eeprom_log
	if [ -f $(RT28xx_DIR)/eeprom/SA/MT7603E_EEPROM.bin ]; then \
		echo 'find SA/MT7603E_EEPROM.bin' >> eeprom_log ; \
		cp -f $(RT28xx_DIR)/eeprom/SA/MT7603E_EEPROM.bin $(RT28xx_DIR)/eeprom/MT7603E_EEPROM.bin ; \
	else \
		cp -f $(RT28xx_DIR)/eeprom/$(EE_TYPE)/MT7603E_EEPROM.bin $(RT28xx_DIR)/eeprom/MT7603E_EEPROM.bin ; \
	fi
	$(MAKE) -C tools
	$(RT28xx_DIR)/tools/bin2h
#	rm -f $(RT28xx_DIR)/eeprom/SA/MT7603E_EEPROM.bin
	
test:
	$(MAKE) -C tools test

UCOS:
	$(MAKE) -C os/ucos/ MODE=$(RT28xx_MODE)
	echo $(RT28xx_MODE)

ECOS:
	$(MAKE) -C os/ecos/ MODE=$(RT28xx_MODE)
	cp -f os/ecos/$(MODULE) $(MODULE)

THREADX:
	$(MAKE) -C $(RT28xx_DIR)/os/Threadx -f $(RT28xx_DIR)/os/ThreadX/Makefile

LINUX:
ifneq (,$(findstring 2.4,$(LINUX_SRC)))

ifeq ($(OSABL),YES)
	cp -f os/linux/Makefile.4.util $(RT28xx_DIR)/os/linux/Makefile
	$(MAKE) -C $(RT28xx_DIR)/os/linux/
endif

	cp -f os/linux/Makefile.4 $(RT28xx_DIR)/os/linux/Makefile
	$(MAKE) -C $(RT28xx_DIR)/os/linux/

ifeq ($(OSABL),YES)
	cp -f os/linux/Makefile.4.netif $(RT28xx_DIR)/os/linux/Makefile
	$(MAKE) -C $(RT28xx_DIR)/os/linux/
endif

else

ifeq ($(OSABL),YES)
	cp -f os/linux/Makefile.6.util $(RT28xx_DIR)/os/linux/Makefile
	$(MAKE) -C $(LINUX_SRC) SUBDIRS=$(RT28xx_DIR)/os/linux modules
endif
ifeq ($(PREALLOC), YES)
	cp -f PREALLOC/os/linux/Makefile.6.prealloc PREALLOC/os/linux/Makefile
	$(MAKE) -C $(LINUX_SRC) SUBDIRS=$(RT28xx_DIR)/PREALLOC/os/linux modules
	$(SHELL) cp_prealloc.sh
endif
	cp -f os/linux/Makefile.6 $(RT28xx_DIR)/os/linux/Makefile
ifeq ($(PLATFORM),DM6446)
	$(MAKE)  ARCH=arm CROSS_COMPILE=arm_v5t_le- -C  $(LINUX_SRC) SUBDIRS=$(RT28xx_DIR)/os/linux modules
else
ifeq ($(PLATFORM),FREESCALE8377)
	$(MAKE) ARCH=powerpc CROSS_COMPILE=$(CROSS_COMPILE) -C  $(LINUX_SRC) SUBDIRS=$(RT28xx_DIR)/os/linux modules
else
	$(MAKE) -C $(LINUX_SRC) SUBDIRS=$(RT28xx_DIR)/os/linux modules
endif
endif

ifeq ($(OSABL),YES)
	cp -f os/linux/Makefile.6.netif $(RT28xx_DIR)/os/linux/Makefile
	$(MAKE) -C $(LINUX_SRC) SUBDIRS=$(RT28xx_DIR)/os/linux modules
endif
endif

plug_in:
	$(MAKE) -C $(LINUX_SRC) SUBDIRS=$(RT28xx_DIR)/tools/plug_in MODULE_FLAGS="$(WFLAGS)"

release: build_tools
	$(MAKE) -C $(RT28xx_DIR)/striptool -f Makefile.release clean
	$(MAKE) -C $(RT28xx_DIR)/striptool -f Makefile.release
	striptool/striptool.out
ifeq ($(RELEASE), DPO)
	gcc -o striptool/banner striptool/banner.c
	./striptool/banner -b striptool/copyright.gpl -s DPO/ -d DPO_GPL -R
	./striptool/banner -b striptool/copyright.frm -s DPO_GPL/include/firmware.h
endif

prerelease:
ifeq ($(MODULE), 2880)
	$(MAKE) -C $(RT28xx_DIR)/os/linux -f Makefile.release.2880 prerelease
else
	$(MAKE) -C $(RT28xx_DIR)/os/linux -f Makefile.release prerelease
endif
	cp $(RT28xx_DIR)/os/linux/Makefile.DPB $(RTMP_SRC_DIR)/os/linux/.
	cp $(RT28xx_DIR)/os/linux/Makefile.DPA $(RTMP_SRC_DIR)/os/linux/.
	cp $(RT28xx_DIR)/os/linux/Makefile.DPC $(RTMP_SRC_DIR)/os/linux/.
ifeq ($(RT28xx_MODE),STA)
	cp $(RT28xx_DIR)/os/linux/Makefile.DPD $(RTMP_SRC_DIR)/os/linux/.
	cp $(RT28xx_DIR)/os/linux/Makefile.DPO $(RTMP_SRC_DIR)/os/linux/.
endif	

clean:
ifeq ($(TARGET), LINUX)
	cp -f os/linux/Makefile.clean os/linux/Makefile
	$(MAKE) -C os/linux clean
	rm -rf os/linux/Makefile
ifeq ($(PREALLOC), YES)
	cp -f PREALLOC/os/linux/Makefile.clean PREALLOC/os/linux/Makefile
	$(MAKE) -C PREALLOC/os/linux clean
	rm -rf PREALLOC/os/linux/Makefile
endif
endif	
ifeq ($(TARGET), UCOS)
	$(MAKE) -C os/ucos clean MODE=$(RT28xx_MODE)
endif
ifeq ($(TARGET), ECOS)
	$(MAKE) -C os/ecos clean MODE=$(RT28xx_MODE)
endif

uninstall:
ifeq ($(TARGET), LINUX)
ifneq (,$(findstring 2.4,$(LINUX_SRC)))
	$(MAKE) -C $(RT28xx_DIR)/os/linux -f Makefile.4 uninstall
else
	$(MAKE) -C $(RT28xx_DIR)/os/linux -f Makefile.6 uninstall
endif
endif

install:
ifeq ($(TARGET), LINUX)
ifneq (,$(findstring 2.4,$(LINUX_SRC)))
	$(MAKE) -C $(RT28xx_DIR)/os/linux -f Makefile.4 install
else
	$(MAKE) -C $(RT28xx_DIR)/os/linux -f Makefile.6 install
endif
endif

libwapi:
ifneq (,$(findstring 2.4,$(LINUX_SRC)))
	cp -f os/linux/Makefile.libwapi.4 $(RT28xx_DIR)/os/linux/Makefile
	$(MAKE) -C $(RT28xx_DIR)/os/linux/
else
	cp -f os/linux/Makefile.libwapi.6 $(RT28xx_DIR)/os/linux/Makefile	
	$(MAKE) -C  $(LINUX_SRC) SUBDIRS=$(RT28xx_DIR)/os/linux modules	
endif	

osutil:
ifeq ($(OSABL),YES)
ifneq (,$(findstring 2.4,$(LINUX_SRC)))
	cp -f os/linux/Makefile.4.util $(RT28xx_DIR)/os/linux/Makefile
	$(MAKE) -C $(RT28xx_DIR)/os/linux/
else
	cp -f os/linux/Makefile.6.util $(RT28xx_DIR)/os/linux/Makefile
	$(MAKE) -C $(LINUX_SRC) SUBDIRS=$(RT28xx_DIR)/os/linux modules
endif
endif

osnet:
ifeq ($(OSABL),YES)
ifneq (,$(findstring 2.4,$(LINUX_SRC)))
	cp -f os/linux/Makefile.4.netif $(RT28xx_DIR)/os/linux/Makefile
	$(MAKE) -C $(RT28xx_DIR)/os/linux/
else
	cp -f os/linux/Makefile.6.netif $(RT28xx_DIR)/os/linux/Makefile
	$(MAKE) -C $(LINUX_SRC) SUBDIRS=$(RT28xx_DIR)/os/linux modules
endif
endif

osdrv:
ifneq (,$(findstring 2.4,$(LINUX_SRC)))
	cp -f os/linux/Makefile.4 $(RT28xx_DIR)/os/linux/Makefile
	$(MAKE) -C $(RT28xx_DIR)/os/linux/
else
	cp -f os/linux/Makefile.6 $(RT28xx_DIR)/os/linux/Makefile
	$(MAKE) -C $(LINUX_SRC) SUBDIRS=$(RT28xx_DIR)/os/linux modules
endif

# Declare the contents of the .PHONY variable as phony.  We keep that information in a variable
.PHONY: $(PHONY)

