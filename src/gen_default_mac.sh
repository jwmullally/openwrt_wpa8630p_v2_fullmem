#!/bin/sh
set -ex

# Generate a "default-mac" partition for TL-WPA8630P v2.0

printf '%b' '\x00\x00\x00\x06\x00\x00\x00\x00' > default-mac
printf '%b' '\x02\xBC\xDE\x39\xE8\x32' | dd of=default-mac oflag=seek_bytes seek=8 conv=notrunc
hexdump -C default-mac
