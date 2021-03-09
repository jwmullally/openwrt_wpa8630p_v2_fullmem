# This Makefile downloads the OpenWRT Image Builder and builds an image
# for the TL-WPA8630 v2 with a custom partition layout and DTS file.

ALL_CURL_OPTS := ${CURL_OPTS} -L --fail --create-dirs

BOARD := ath79
SUBTARGET := generic
SOC := qca9563
BUILDER := openwrt-imagebuilder-${BOARD}-${SUBTARGET}.Linux-x86_64
PROFILE := tplink_tl-wpa8630p-v2-fullmem
PACKAGES = iw luci luci-app-commands open-plc-utils-plctool open-plc-utils-plcrate open-plc-utils-hpavkeys
EXTRA_IMAGE_NAME := custom

TOPDIR := ${CURDIR}/${BUILDER}
KDIR := ${TOPDIR}/build_dir/target-mips_24kc_musl/linux-${BOARD}_${SUBTARGET}
PATH := ${TOPDIR}/staging_dir/host/bin:${PATH}
LINUX_VERSION = $(shell sed -n -e '/Linux-Version: / {s/Linux-Version: //p;q}' ${BUILDER}/.targetinfo)


all: images


${BUILDER}.tar.xz:
	curl ${ALL_CURL_OPTS} -O https://downloads.openwrt.org/snapshots/targets/${BOARD}/${SUBTARGET}/${BUILDER}.tar.xz
	

${BUILDER}: ${BUILDER}.tar.xz
	tar -xf ${BUILDER}.tar.xz
	
	# Fetch firmware utility sources to apply patches
	curl ${ALL_CURL_OPTS} "https://git.openwrt.org/?p=openwrt/openwrt.git;hb=refs/heads/master;a=blob_plain;f=tools/firmware-utils/src/tplink-safeloader.c" -o ${BUILDER}/tools/firmware-utils/src/tplink-safeloader.c
	curl ${ALL_CURL_OPTS} "https://git.openwrt.org/?p=openwrt/openwrt.git;hb=refs/heads/master;a=blob_plain;f=tools/firmware-utils/src/md5.h" -o ${BUILDER}/tools/firmware-utils/src/md5.h
	
	# Apply all patches
	cd ${BUILDER} && patch -p0 < ../${PROFILE}.patch
	gcc -Wall -o ${TOPDIR}/staging_dir/host/bin/tplink-safeloader ${BUILDER}/tools/firmware-utils/src/tplink-safeloader.c -lcrypto -lssl
	
	# Regenerate .targetinfo
	cd ${BUILDER} && make -f include/toplevel.mk TOPDIR="${TOPDIR}" prepare-tmpinfo || true
	cp -f ${BUILDER}/tmp/.targetinfo ${BUILDER}/.targetinfo


linux-include: ${BUILDER}
	# Fetch DTS include dependencies
	curl ${ALL_CURL_OPTS} "https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/plain/include/dt-bindings/clock/ath79-clk.h?h=v${LINUX_VERSION}" -o linux-include/dt-bindings/clock/ath79-clk.h
	curl ${ALL_CURL_OPTS} "https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/plain/include/dt-bindings/gpio/gpio.h?h=v${LINUX_VERSION}" -o linux-include/dt-bindings/gpio/gpio.h
	curl ${ALL_CURL_OPTS} "https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/plain/include/dt-bindings/input/input.h?h=v${LINUX_VERSION}" -o linux-include/dt-bindings/input/input.h
	curl ${ALL_CURL_OPTS} "https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/plain/include/uapi/linux/input-event-codes.h?h=v${LINUX_VERSION}" -o linux-include/dt-bindings/input/linux-event-codes.h


${KDIR}/${PROFILE}-kernel.bin: ${BUILDER} linux-include
	# Build this device's DTB and firmware kernel image. Uses the official kernel build as a base.
	ln -sf /usr/bin/cpp ${BUILDER}/staging_dir/host/bin/mips-openwrt-linux-musl-cpp
	cp -Trf linux-include ${KDIR}/linux-${LINUX_VERSION}/include
	cd ${BUILDER} && env PATH=${PATH} make --trace -C target/linux/${BOARD}/image ${KDIR}/${PROFILE}-kernel.bin TOPDIR="${TOPDIR}" INCLUDE_DIR="${TOPDIR}/include" TARGET_BUILD=1 BOARD="${BOARD}" SUBTARGET="${SUBTARGET}" PROFILE="${PROFILE}" DEVICE_DTS="${SOC}_${PROFILE}"


images: ${BUILDER} ${KDIR}/${PROFILE}-kernel.bin
	# Use ImageBuilder as normal
	cd ${BUILDER} && make image PROFILE="${PROFILE}" EXTRA_IMAGE_NAME="${EXTRA_IMAGE_NAME}" PACKAGES="${PACKAGES}"
	cat ${BUILDER}/bin/targets/${BOARD}/${SUBTARGET}/sha256sums
	ls -hs ${BUILDER}/bin/targets/${BOARD}/${SUBTARGET}/openwrt-${EXTRA_IMAGE_NAME}-*-factory.bin


clean:
	rm -rf openwrt-imagebuilder-ath79-generic.Linux-x86_64
	rm -rf openwrt-imagebuilder-ath79-generic.Linux-x86_64.tar.xz
	rm -rf linux-include
