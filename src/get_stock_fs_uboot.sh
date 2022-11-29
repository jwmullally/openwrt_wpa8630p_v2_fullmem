#!/bin/sh
set -ex

# Extract "fs-uboot" from an OEM firmware release that loads "os-image" from 0x40000.
# Hardware Model: TP-Link TL-WPA8630P(AU) v2.0
# Firmware Version: 2.0.0 Build 20170608 Rel.64411 

curl $CURL_OPTS --fail -LO "https://static.tp-link.com/TL-WPA8630P%20KIT(AU)_V2_170608.zip"
filemd5="$(md5sum 'TL-WPA8630P%20KIT(AU)_V2_170608.zip' | awk '{print $1}')"
if [ "$filemd5" != "1cb80fb680d8189076ecec4011ea9355" ]; then
	echo "Error: Invalid md5sum" 1>&2
	exit 1
fi
unzip -j "TL-WPA8630P%20KIT(AU)_V2_170608.zip" "*.bin"
dd if="wpa8630pv2_au-up-ver2-0-0-P1-20170608-rel64411-APPLC.bin" of="fs-uboot" iflag=skip_bytes skip=8272 bs=68076 count=1
rm -f "TL-WPA8630P%20KIT(AU)_V2_170608.zip" "wpa8630pv2_au-up-ver2-0-0-P1-20170608-rel64411-APPLC.bin"
