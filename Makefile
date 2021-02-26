# This Makefile downloads the OpenWRT Image Builder and builds an image
# for the TL-WPA8630 v2 with a custom partition layout and DTS file. As
# the Image Builder doesn't support building DTS files, we do that step
# manually.

# Specific to this Makefile
ALL_CURL_OPTS := ${CURL_OPTS} -L --fail --create-dirs
BUILDER := openwrt-imagebuilder-ath79-generic.Linux-x86_64
SOC := qca9563
PROFILE := tplink_tl-wpa8630p-v2-fullmem
PACKAGES = iw luci luci-app-commands open-plc-utils-plctool open-plc-utils-plcrate open-plc-utils-hpavkeys
EXTRA_IMAGE_NAME := custom

# OpenWRT Makefile variables
KDIR := ${BUILDER}/build_dir/target-mips_24kc_musl/linux-ath79_generic/
LINUX_DIR = ${KDIR}/linux-${LINUX_VERSION}
STAGING_DIR_HOST := ${BUILDER}/staging_dir/host/
VERSION_DIST := OpenWRT
REVISION = $(shell sed -n -e '/REVISION:=/ {s/REVISION:=//p;q}' ${BUILDER}/include/version.mk)
LINUX_VERSION = $(shell sed -n -e '/Linux-Version: / {s/Linux-Version: //p;q}' ${BUILDER}/.targetinfo)

# Expanded from Device/tplink_tl-wpa8630p-v2
KERNEL_LOADADDR := 0x80060000
TPLINK_HEADER_VERSION := 1
TPLINK_HWID := 0x0
TPLINK_HWREV := 0x0


all: images


${BUILDER}.tar.xz:
	curl ${ALL_CURL_OPTS} -C - -L -O https://downloads.openwrt.org/snapshots/targets/ath79/generic/${BUILDER}.tar.xz
	

${BUILDER}: ${BUILDER}.tar.xz
	tar -xf ${BUILDER}.tar.xz
	curl ${ALL_CURL_OPTS} -O "https://git.openwrt.org/?p=openwrt/openwrt.git;hb=refs/heads/master;a=blob_plain;f=tools/firmware-utils/src/tplink-safeloader.c"
	curl ${ALL_CURL_OPTS} -O "https://git.openwrt.org/?p=openwrt/openwrt.git;hb=refs/heads/master;a=blob_plain;f=tools/firmware-utils/src/md5.h"
	patch -p0 < fullmem.patch
	gcc -Wall -o ${STAGING_DIR_HOST}/bin/tplink-safeloader tplink-safeloader.c -lcrypto -lssl


linux-include:
	curl ${ALL_CURL_OPTS} --create-dirs -L "https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/plain/include/dt-bindings/clock/ath79-clk.h?h=v${LINUX_VERSION}" -o linux-include/dt-bindings/clock/ath79-clk.h
	curl ${ALL_CURL_OPTS} --create-dirs -L "https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/plain/include/dt-bindings/gpio/gpio.h?h=v${LINUX_VERSION}" -o linux-include/dt-bindings/gpio/gpio.h
	curl ${ALL_CURL_OPTS} --create-dirs -L "https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/plain/include/dt-bindings/input/input.h?h=v${LINUX_VERSION}" -o linux-include/dt-bindings/input/input.h
	curl ${ALL_CURL_OPTS} --create-dirs -L "https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/plain/include/uapi/linux/input-event-codes.h?h=v${LINUX_VERSION}" -o linux-include/dt-bindings/input/linux-event-codes.h


${KDIR}/${PROFILE}-kernel.bin: ${BUILDER} linux-include
	rm -f ${KDIR}/*.tmp
	# Image/BuildDTB
	cpp -nostdinc -x assembler-with-cpp \
		-I linux-include \
		-undef -D__DTS__ \
		-o ${KDIR}/${SOC}_${PROFILE}.dts.tmp ${BUILDER}/target/linux/ath79/dts/${SOC}_${PROFILE}.dts
	$(LINUX_DIR)/scripts/dtc/dtc -O dtb \
		-o ${KDIR}/image-${SOC}_${PROFILE}.dtb ${KDIR}/${SOC}_${PROFILE}.dts.tmp
	# Expanded from Device/tplink-safeloader
	# Build/append-dtb
	cat ${KDIR}/vmlinux ${KDIR}/image-${SOC}_${PROFILE}.dtb > ${KDIR}/${PROFILE}-kernel-dtb.tmp
	# Build/lzma
	$(STAGING_DIR_HOST)/bin/lzma e -lc1 -lp2 -pb2 \
		${KDIR}/${PROFILE}-kernel-dtb.tmp ${KDIR}/${PROFILE}-kernel-dtb-lzma.tmp
	# Build/tplink-v1-header
	$(STAGING_DIR_HOST)/bin/mktplinkfw \
		-c -O -H $(TPLINK_HWID) -W $(TPLINK_HWREV) -L $(KERNEL_LOADADDR) \
		-E $(KERNEL_LOADADDR) -m $(TPLINK_HEADER_VERSION) \
		-N "$(VERSION_DIST)" -V $(REVISION) \
		-k ${KDIR}/${PROFILE}-kernel-dtb-lzma.tmp \
		-o ${KDIR}/${PROFILE}-kernel.bin


images: ${BUILDER} ${KDIR}/${PROFILE}-kernel.bin
	cd ${BUILDER} && make image PROFILE="${PROFILE}" EXTRA_IMAGE_NAME="${EXTRA_IMAGE_NAME}" PACKAGES="${PACKAGES}"
	cat ${BUILDER}/bin/targets/ath79/generic/sha256sums 
	ls -hs ${BUILDER}/bin/targets/ath79/generic/openwrt-${EXTRA_IMAGE_NAME}-*-factory.bin


clean:
	rm -rf openwrt-imagebuilder-ath79-generic.Linux-x86_64
	rm -rf linux-include
	rm -f openwrt-imagebuilder-ath79-generic.Linux-x86_64.tar.xz
	rm -f md5.h
	rm -f tplink-safeloader.c
