## Overview

This repository adds a build profile for [OpenWRT firmware for the TP-Link TL-WPA8630P v2](https://openwrt.org/toh/tp-link/tp-link_tl-wpa8630p_v2) to use all available flash memory. It irreversibly overwrites built-in device-specific stock partitions. After installing this image, reverting to stock firmware can only be done with a specially crafted firmware image, or restoring a full flash backup using an SPI flash programmer.

**!!! DO NOT USE - CURRENTLY BEING TESTED - WILL BRICK YOUR DEVICE !!!**


## Partition layout

7.8 Mb is available for OpenWRT versus 5.9 Mb using the stock-compatible images (tl-wpa8630p-v2-int, tl-wpa8630p-v2.0-eu, etc).


The upgrade firmware contains these partitions:

```
partition-table
soft-version
support-list
os-image
file-system
default-mac
```

After installing, the device flash layout will look like:

```
partition factory-uboot base 0x00000 size 0x20000
partition os-image base 0x20000 size ...
partition file-system base ... size ...
partition soft-version base 0x7ebf00 size 0x01000
partition partition-table base 0x7ecf00 size 0x02000
partition support-list base 0x7eef00 size 0x01000
partition default-mac base 0x7eff00 size 0x00020
partition radio base 0x7f0000 size 0x10000
```

Only these original stock partitions will be preserved:

```
partition factory-uboot base 0x00000 size 0x20000
partition radio base 0x7f0000 size 0x10000
```

These partitions containing data unique to your device will be irretrievably overwritten:

```
default-mac
pin
device-id
product-info
```

** !!! Make sure you have a full memory backup before proceeding !!! **
