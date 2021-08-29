## Overview

This repository adds a build profile for [OpenWRT firmware for the TP-Link TL-WPA8630P v2](https://openwrt.org/toh/tp-link/tp-link_tl-wpa8630p_v2) to use all available flash memory. It irreversibly overwrites built-in device-specific stock partitions. After installing this image, reverting to stock firmware can only be done with a specially crafted firmware image, or restoring a full flash backup using an SPI flash programmer.

**!!! DO NOT USE - CURRENTLY BEING TESTED - WILL BRICK YOUR DEVICE !!!**


## Supported Devices

| Hardware Version |
| --- |
| `Model: TL-WPA8630(CA) Ver: 2.0` |
| `Model: TL-WPA8630(EU) Ver: 2.0` |
| `Model: TL-WPA8630(US) Ver: 2.0` |
| `Model: TL-WPA8630P(AU) Ver: 2.0` |
| `Model: TL-WPA8630P(DE) Ver: 2.0` |
| `Model: TL-WPA8630P(EU) Ver: 2.0` |
| `Model: TL-WPA8630P(AU) Ver: 2.1` |
| `Model: TL-WPA8630P(EU) Ver: 2.1` |


Where to find this information:

* Hardware Version 
  * Where: On the barcode sticker on the back of the device.
  * Example: `Model: TL-WPA8630P(EU) Ver: 2.0`


## Downloads

See the **Releases** section for the latest builds.

These are built with the OpenWRT ImageBuilder using [this Github workflow](./.github/workflows/build_release_images.yml). You can see the build logs (including checksums) in the **Actions** section.


## Upgrades

When new OpenWRT releases are made, you will need to get the latest build from here, or build it yourself following the [Building](#Building) section below. The official images have different partition layouts, and forcibly flashing them after flashing this image will brick your device.


## Details

### Partition layout

7.8 Mb is available for OpenWRT using this image versus 5.9 Mb using the stock-compatible images (`tl-wpa8630p-v2-int`, `tl-wpa8630p-v2.0-eu`, etc).

The factory upgrade firmware contains these partitions:

| Partition |
| --- |
| `partition-table` |
| `soft-version` |
| `support-list` |
| `os-image` |
| `file-system` |
| `default-mac` |

After installing, the device flash layout will look like:

| Partition | Base | Size |
| --- | ---: | ---: |
| `factory-uboot` | `0x00000` | `0x20000` |
| `os-image` | `0x20000` | `...` |
| `file-system` | `...` | `...` |
| `soft-version` | `0x7e0000` | `0x01000` |
| `partition-table` | `0x7e1000` | `0x02000` |
| `support-list` | `0x7e3000` | `0x01000` |
| `default-mac` | `0x7e4000` | `0x00020` |
| `radio` | `0x7f0000` | `0x10000` |

Only these original stock partitions will be preserved:

| Partition | Base | Size |
| --- | ---: | ---: |
| `factory-uboot` | `0x00000` | `0x20000` |
| `radio` | `0x7f0000` | `0x10000` |

These partitions containing data unique to your device will be irretrievably overwritten:

| Partition |
| --- |
| `default-mac` |
| `pin` |
| `device-id` |
| `product-info` |

**!!! Make sure you have a full memory backup before proceeding !!!**


### Default MAC address

Unfortunately, your devices original `defaul-mac` partition will need to be overwritten. A replacement one is included with the address `02:BC:DE:39:E8:32`.

To set your own MAC address, do the following:

```bash
echo -en "\x02\xBC\xDE\x39\xE8\x32" | dd of=default-mac oflag=seek_bytes seek=8 conv=notrunc
make
```


## Building

If you want to build the firmwares yourself, checkout this repo and do the following:

```bash
make
```


## Issues

Please use the **Issues** section to log any issues, questions or feedback you have on these images.


## Development

Feel free to fork this repository for other devices. This uses Github to build and distribute custom OpenWRT images with small changes. It has the following benefits:

* Uses [ImageBuilder](https://openwrt.org/docs/guide-user/additional-software/imagebuilder) and official OpenWRT signed kernel
* Uses existing OpenWRT firmware Makefile recipes
* Automated building and file serving with GitHub (just add a new git tag to make a build)
* Public build logs (with checksums)
* Open-source patches compatible with upstream OpenWRT source
* User reproducible builds for people wary of random binaries from the internet
* Others can fork the repo if maintainer is no longer available

Patches for new devices should always be [sent to OpenWRT](https://openwrt.org/submitting-patches) for official support. For custom builds that aren't suitable there (e.g. custom partition layouts, hardware mods, etc), this approach is a good alternative.


## Contact

* OpenWRT forum: [jwmullally](https://forum.openwrt.org/u/jwmullally)
* GitHub project: <https://github.com/jwmullally/openwrt_wpa8630p_v2_fullmem>
