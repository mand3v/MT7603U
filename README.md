# MT7603U driver
**Warning: there are still many bugs in this project, and welcome to join me
to improve it.**

## Build and Install
```bash
sudo make && sudo make install
```

Test it:
```
insmod mt7603u_sta
depmod
```

You may also want to update existing old driver:
```
rmmod mt7603u*
insmod mt7603u
depmod
```

## Vendor driver
**MT7603U_DPA_LinuxSTA_3.0.0.4_20140825**

The original vendor driver can be downloaded from [here](http://www.ogemray.com/include/upload/download/_20151027134607312.rar).

and you can also refer the document for [Ogemray GWF-1D07 300Mbps 802.11b/g/n MediaTek MT7603U WIFI USB Adapter](http://www.ogemray.com/product/download/GWF-1D07_xz.pdf). (It's in Chinese.)
