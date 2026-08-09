#!/usr/bin/env bash


################################################################################
# Set up the environment
################################################################################

set -e						# exit on error
set -o pipefail				# exit on pipeline error
set -u						# treat unset variable as error


################################################################################
# Base Path
################################################################################

BASE_DIR_PATH="$(dirname "$(realpath "${0}")")"
LIBS_DIR_PATH="${BASE_DIR_PATH}/libs"


################################################################################
# Init
################################################################################

source "${LIBS_DIR_PATH}/domain/controller/init.sh"




################################################################################
# Model
################################################################################

function bind_signal () {

	print_info "Bind signal ..."
	trap umount_on_exit EXIT
	judge "Bind signal"

}

function clean () {

	print_info "Cleaning up previous build ..."
	umount "${DISTRO_IMG_DIR_PATH}/sys" || umount -lf "${DISTRO_IMG_DIR_PATH}/sys" || true
	umount "${DISTRO_IMG_DIR_PATH}/proc" || umount -lf "${DISTRO_IMG_DIR_PATH}/proc" || true
	umount "${DISTRO_IMG_DIR_PATH}/dev" || umount -lf "${DISTRO_IMG_DIR_PATH}/dev" || true
	umount "${DISTRO_IMG_DIR_PATH}/run" || umount -lf "${DISTRO_IMG_DIR_PATH}/run" || true
	rm -rf "${DISTRO_IMG_DIR_PATH}" "${DISTRO_ISO_DIR_PATH}" || true
	judge "Clean up build artifacts"

}

function download_base_system () {

	print_info "Creating new_building_os directory ..."
	mkdir -p "${DISTRO_IMG_DIR_PATH}"
	judge "Create build directory"

	print_info "Calling debootstrap to download base debian system ..."
	debootstrap  --arch=amd64 --variant=minbase --include=ca-certificates,wget,dbus "${TARGET_UBUNTU_VERSION}" "${DISTRO_IMG_DIR_PATH}" "${APT_SOURCE}"
	judge "Download base system"

}

function mount_folders () {

	print_info "Reloading systemd daemon ..."
	systemctl daemon-reload
	judge "Reload systemd daemon"

	print_info "Mounting /dev /run from host to build dir ..."
	mount --bind /dev "${DISTRO_IMG_DIR_PATH}/dev"
	mount --bind /run "${DISTRO_IMG_DIR_PATH}/run"
	judge "Mount /dev /run"

	print_info "Mounting /proc /sys /dev/pts within chroot ..."
	chroot "${DISTRO_IMG_DIR_PATH}" mount none -t proc /proc
	chroot "${DISTRO_IMG_DIR_PATH}" mount none -t sysfs /sys
	chroot "${DISTRO_IMG_DIR_PATH}" mount none -t devpts /dev/pts
	judge "Mount /proc /sys /dev/pts"

	print_info "Copying fulfill scripts to chroot /opt/build ..."
	mkdir -p "${DISTRO_IMG_DIR_PATH}/opt/build/template/engine"
	[ -d "${ARGS_DIR_PATH}" ] && cp -rfT "${ARGS_DIR_PATH}" "${DISTRO_IMG_DIR_PATH}/opt/build/template/engine/args" || true
	cp -rfT "${LIBS_DIR_PATH}" "${DISTRO_IMG_DIR_PATH}/opt/build/template/engine/libs"
	cp -rfT "${MODS_DIR_PATH}" "${DISTRO_IMG_DIR_PATH}/opt/build/template/engine/mods"
	cp -rfT "${MASTER_ASSET_DIR_PATH}" "${DISTRO_IMG_DIR_PATH}/opt/build/template/asset"
	[ -d "${INSTALLER_ASSET_DIR_PATH}" ] && cp -rfT "${INSTALLER_ASSET_DIR_PATH}" "${DISTRO_IMG_DIR_PATH}/opt/build/template/installer" || true
	print_ok "Copying fulfill scripts to chroot /opt/build"

}

function setup_apt () {

	print_info "Setting up Ubuntu apt sources in chroot ..."
	mkdir -p "${DISTRO_IMG_DIR_PATH}/etc/apt/sources.list.d"
	tee "${DISTRO_IMG_DIR_PATH}/etc/apt/sources.list.d/ubuntu.sources" > /dev/null <<EOF
Types: deb
URIs: ${APT_SOURCE}
Suites: ${TARGET_UBUNTU_VERSION}
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

Types: deb
URIs: ${APT_SOURCE}
Suites: ${TARGET_UBUNTU_VERSION}-updates
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

Types: deb
URIs: ${APT_SOURCE}
Suites: ${TARGET_UBUNTU_VERSION}-backports
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

Types: deb
URIs: ${APT_SOURCE}
Suites: ${TARGET_UBUNTU_VERSION}-security
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
EOF
	judge "Set up Ubuntu apt sources"

	# Remove stale legacy-format sources.list (debootstrap artifact).
	# Ubuntu 24.04+ uses deb822 .sources files in sources.list.d/ instead.
	rm -f "${DISTRO_IMG_DIR_PATH}/etc/apt/sources.list"

	print_info "Setting up AnduinOS APKG apt source in chroot ..."

	local keyring_path="${DISTRO_IMG_DIR_PATH}/usr/share/keyrings/anduinos-archive-keyring.gpg"
	local cert_url="${APKG_SERVER}/artifacts/certs/${APKG_CERT_NAME}"

	print_info "Downloading GPG keyring from $cert_url ..."
	mkdir -p "${DISTRO_IMG_DIR_PATH}/usr/share/keyrings"
	curl -sL "$cert_url" | sed '1s/^\xEF\xBB\xBF//' | gpg --dearmor | tee "$keyring_path" > /dev/null
	judge "Download and dearmor keyring"

	print_info "Generating anduinos.sources for ${APKG_SERVER} (suite: ${TARGET_UBUNTU_VERSION}-addon) ..."
	mkdir -p "${DISTRO_IMG_DIR_PATH}/etc/apt/sources.list.d"
	tee "${DISTRO_IMG_DIR_PATH}/etc/apt/sources.list.d/anduinos.sources" > /dev/null <<EOF
Types: deb
URIs: ${APKG_SERVER}/artifacts/anduinos/
Suites: ${TARGET_UBUNTU_VERSION}-addon
Components: main
Architectures: amd64
Signed-By: /usr/share/keyrings/anduinos-archive-keyring.gpg
EOF
	judge "Generate sources"

	print_info "Enabling apt recommends in chroot ..."
	echo 'APT::Install-Recommends "true";' | tee "${DISTRO_IMG_DIR_PATH}/etc/apt/apt.conf.d/99-enable-recommends" > /dev/null
	judge "Enable apt recommends"

	print_info "Running apt update in chroot ..."
	chroot "${DISTRO_IMG_DIR_PATH}" apt update
	judge "Apt update in chroot"

	# Upgrade base system BEFORE mods run.  Swap packages (mod 01)
	# must not be visible to this upgrade — apt would try to
	# "normalize" them back to Ubuntu's lower version and fail.
	print_info "Upgrading base system packages ..."
	chroot "${DISTRO_IMG_DIR_PATH}" apt -y upgrade
	judge "Upgrade base system"

}

function run_chroot () {

	print_info "Running rundown.sh in new_building_os ..."
	print_warn "============================================"
	print_warn "   The following will run in chroot ENV!"
	print_warn "============================================"
	chroot "${DISTRO_IMG_DIR_PATH}" /usr/bin/env DEBIAN_FRONTEND=${DEBIAN_FRONTEND:-readline} /opt/build/template/engine/mods/fulfill-for-full-system.sh -
	print_warn "============================================"
	print_warn "   chroot ENV execution completed!"
	print_warn "============================================"
	judge "Run rundown.sh in new_building_os"

	print_info "Sleeping for 5 seconds to allow chroot to exit cleanly ..."
	sleep 5

}

function umount_folders () {

	print_info "Cleaning mods from chroot /opt/build ..."
	rm -rf "${DISTRO_IMG_DIR_PATH}/opt/build"
	judge "Clean up chroot /opt/build"

	print_info "Unmounting /proc /sys /dev/pts within chroot ..."
	chroot "${DISTRO_IMG_DIR_PATH}" umount /dev/pts || chroot "${DISTRO_IMG_DIR_PATH}" umount -lf /dev/pts
	chroot "${DISTRO_IMG_DIR_PATH}" umount /sys || chroot "${DISTRO_IMG_DIR_PATH}" umount -lf /sys
	chroot "${DISTRO_IMG_DIR_PATH}" umount /proc || chroot "${DISTRO_IMG_DIR_PATH}" umount -lf /proc
	judge "Unmount /proc /sys /dev/pts"

	print_info "Unmounting /dev /run outside of chroot ..."
	umount "${DISTRO_IMG_DIR_PATH}/dev" || umount -lf "${DISTRO_IMG_DIR_PATH}/dev"
	umount "${DISTRO_IMG_DIR_PATH}/run" || umount -lf "${DISTRO_IMG_DIR_PATH}/run"
	judge "Unmount /dev /run"

}

function build_iso () {

	print_info "Building ISO image ..."

	print_info "Creating image directory ..."
	rm -rf "${DISTRO_ISO_DIR_PATH}"
	mkdir -p "${DISTRO_ISO_DIR_PATH}"/{casper,isolinux,.disk}
	judge "Create image directory"

	# copy kernel files
	print_info "Copying kernel files as /casper/vmlinuz, /casper/initrd and /casper/initrd.gz ..."
	# Resolve the distro-maintained symlinks — they always point to the
	# current kernel, so we never pick a stale one left behind by apt.
	local REAL_VMLINUZ=$(realpath "${DISTRO_IMG_DIR_PATH}/vmlinuz" 2>/dev/null)
	[ -f "${REAL_VMLINUZ}" ] || REAL_VMLINUZ=$(realpath "${DISTRO_IMG_DIR_PATH}/boot/vmlinuz" 2>/dev/null)
	local REAL_INITRD=$(realpath "${DISTRO_IMG_DIR_PATH}/initrd.img" 2>/dev/null)
	[ -f "${REAL_INITRD}" ] || REAL_INITRD=$(realpath "${DISTRO_IMG_DIR_PATH}/boot/initrd.img" 2>/dev/null)
	if [ -z "${REAL_VMLINUZ}" ] || [ ! -f "${REAL_VMLINUZ}" ]; then
		print_error "No kernel found via vmlinuz symlink in new_building_os/"
		exit 1
	fi
	cp "${REAL_VMLINUZ}" "${DISTRO_ISO_DIR_PATH}/casper/vmlinuz"
	# Keep both names for remix compatibility:
	# - Legacy BIOS core.img may embed "/casper/initrd"
	# - Some remix tools (e.g. Cubic) may rewrite text grub.cfg to "/casper/initrd.gz"
	# Having both avoids boot mismatch between BIOS and UEFI paths.
	cp "${REAL_INITRD}" "${DISTRO_ISO_DIR_PATH}/casper/initrd"
	#cp "${REAL_INITRD}" "${DISTRO_ISO_DIR_PATH}/casper/initrd.gz"
	judge "Copy kernel files"

	print_info "Save build args ..."
	raw_building_var_dump | tee "${DISTRO_ISO_DIR_PATH}/${TARGET_NAME}"
	judge "Save build args"

	print_info "Generating grub.cfg ..."
	# Configurations are setup in new_building_os/usr/share/initramfs-tools/scripts/casper-bottom/25configure_init
	local TRY_TEXT="Try or Install ${TARGET_BUSINESS_NAME}"
	local TOGO_TEXT="${TARGET_BUSINESS_NAME} To Go (Persistent on USB)"

	# Build locale submenu entries for Try mode.
	# Each entry also derives a best-guess timezone so the live session
	# clock matches the user's region, not hardcoded Los Angeles.
	local _TRY_LOCALE_ENTRIES=""
	while IFS="|" read -r _code _label; do
		[ -z "${_code}" ] && continue
		[ -z "${_label}" ] && continue

		# locale -> timezone best-guess mapping
		case "${_code}" in
			en_US) _tz="America/New_York" ;;
			en_GB) _tz="Europe/London" ;;
			zh_CN) _tz="Asia/Shanghai" ;;
			zh_TW) _tz="Asia/Taipei" ;;
			zh_HK) _tz="Asia/Hong_Kong" ;;
			ja_JP) _tz="Asia/Tokyo" ;;
			ko_KR) _tz="Asia/Seoul" ;;
			vi_VN) _tz="Asia/Ho_Chi_Minh" ;;
			th_TH) _tz="Asia/Bangkok" ;;
			de_DE) _tz="Europe/Berlin" ;;
			fr_FR) _tz="Europe/Paris" ;;
			es_ES) _tz="Europe/Madrid" ;;
			ru_RU) _tz="Europe/Moscow" ;;
			it_IT) _tz="Europe/Rome" ;;
			pt_PT) _tz="Europe/Lisbon" ;;
			pt_BR) _tz="America/Sao_Paulo" ;;
			ar_SA) _tz="Asia/Riyadh" ;;
			nl_NL) _tz="Europe/Amsterdam" ;;
			sv_SE) _tz="Europe/Stockholm" ;;
			pl_PL) _tz="Europe/Warsaw" ;;
			tr_TR) _tz="Europe/Istanbul" ;;
			ro_RO) _tz="Europe/Bucharest" ;;
			da_DK) _tz="Europe/Copenhagen" ;;
			uk_UA) _tz="Europe/Kiev" ;;
			id_ID) _tz="Asia/Jakarta" ;;
			fi_FI) _tz="Europe/Helsinki" ;;
			hi_IN) _tz="Asia/Kolkata" ;;
			el_GR) _tz="Europe/Athens" ;;
			*)	  _tz="America/Los_Angeles" ;;
		esac

		_TRY_LOCALE_ENTRIES="${_TRY_LOCALE_ENTRIES}
	menuentry \"${_label}\" {
		set gfxpayload=keep
		linux   /casper/vmlinuz boot=casper locale=${_code}.UTF-8 timezone=${_tz} systemd.timezone=${_tz} nopersistent quiet splash ---
		initrd  /casper/initrd
	}"
	done <<< "${SUPPORTED_LOCALES}"

	# Copy system unicode.pf2 so GRUB can render CJK/Arabic/Thai labels.
	# Without loadfont, GRUB defaults to an ASCII-only built-in font.
	# Placed in both paths: isolinux (BIOS) and boot/grub/fonts (UEFI standard).
	print_info "Preparing GRUB unicode font (for CJK) ..."
	mkdir -p "${DISTRO_ISO_DIR_PATH}/isolinux" "${DISTRO_ISO_DIR_PATH}/boot/grub/fonts"
	cp /usr/share/grub/unicode.pf2 "${DISTRO_ISO_DIR_PATH}/isolinux/unicode.pf2"
	cp /usr/share/grub/unicode.pf2 "${DISTRO_ISO_DIR_PATH}/boot/grub/fonts/unicode.pf2"
	judge "Prepare GRUB unicode font"


	##
	## ## for grub.cfg: search --set=root --file /${TARGET_NAME}
	##

	touch "${DISTRO_ISO_DIR_PATH}/${TARGET_NAME}"


	##
	## ## create grub.cfg
	##

	cat << EOF > "${DISTRO_ISO_DIR_PATH}/isolinux/grub.cfg"

search --set=root --file /${TARGET_NAME}

insmod all_video
insmod gfxterm
insmod font
if loadfont /boot/grub/fonts/unicode.pf2 ; then
	terminal_output gfxterm
elif loadfont /isolinux/unicode.pf2 ; then
	terminal_output gfxterm
fi

set default="0"
set timeout=10

submenu "${TRY_TEXT}" {
${_TRY_LOCALE_ENTRIES}
}

submenu "Advanced Options ..." {
	menuentry "${TRY_TEXT} (Safe Graphics)" {
		set gfxpayload=keep
		linux   /casper/vmlinuz boot=casper nopersistent nomodeset ---
		initrd  /casper/initrd
	}
	menuentry "${TOGO_TEXT}" {
		set gfxpayload=keep
		linux   /casper/vmlinuz boot=casper persistent quiet splash ---
		initrd  /casper/initrd
	}
	menuentry "Check installation media for defects (Integrity Check)" {
		set gfxpayload=keep
		linux   /casper/vmlinuz boot=casper integrity-check quiet splash ---
		initrd  /casper/initrd
	}
}

if [ "\$grub_platform" == "efi" ]; then
	menuentry "Boot from next volume" {
		exit 1
	}
	menuentry "UEFI Firmware Settings" {
		fwsetup
	}
fi
EOF
	judge "Generate grub.cfg"


	# generate manifest
	print_info "Generating manifest for filesystem ..."
	chroot "${DISTRO_IMG_DIR_PATH}" dpkg-query -W --showformat='${Package} ${Version}\n' | tee "${DISTRO_ISO_DIR_PATH}/casper/filesystem.manifest" >/dev/null 2>&1
	judge "Generate manifest for filesystem"

	print_info "Generating manifest for filesystem-desktop ..."
	cp -v "${DISTRO_ISO_DIR_PATH}/casper/filesystem.manifest" "${DISTRO_ISO_DIR_PATH}/casper/filesystem.manifest-desktop"
	for pkg in ${TARGET_PACKAGE_REMOVE}; do
		sed -i "/^${pkg} /d" "${DISTRO_ISO_DIR_PATH}/casper/filesystem.manifest-desktop"
	done
	judge "Generate manifest for filesystem-desktop"

	print_info "Compressing rootfs as squashfs on /casper/filesystem.squashfs ..."
	mksquashfs "${DISTRO_IMG_DIR_PATH}" "${DISTRO_ISO_DIR_PATH}/casper/filesystem.squashfs" \
		-noappend -no-duplicates -no-recovery \
		-wildcards -b 1M \
		-comp zstd -Xcompression-level 19 \
		-e "var/cache/apt/archives/*" \
		-e "tmp/*" \
		-e "tmp/.*" \
		-e "swapfile"
	judge "Compress rootfs"

	print_info "Verifying the integrity of filesystem.squashfs ..."
	if unsquashfs -s "${DISTRO_ISO_DIR_PATH}/casper/filesystem.squashfs"; then
		print_ok "Verification successful. The file appears to be valid."
	else
		print_error "Verification FAILED! The squashfs file is likely corrupt."
		exit 1
	fi

	print_info "Generating filesystem.size on /casper/filesystem.size ..."
	printf $(du -sx --block-size=1 "${DISTRO_IMG_DIR_PATH}" | cut -f1) > "${DISTRO_ISO_DIR_PATH}/casper/filesystem.size"
	judge "Generate filesystem.size"

	print_info "Generating README.diskdefines ..."
	cat << EOF > "${DISTRO_ISO_DIR_PATH}/README.diskdefines"
#define DISKNAME  Try ${TARGET_BUSINESS_NAME}
#define TYPE  binary
#define TYPEbinary  1
#define ARCH  amd64
#define ARCHamd64  1
#define DISKNUM  1
#define DISKNUM1  1
#define TOTALNUM  0
#define TOTALNUM0  1
EOF
	judge "Generate README.diskdefines"

	##local DATE=$(TZ="UTC" date +"%y%m%d%H%M")
	local DATE=$(date +"%y%m%d%H%M")
	cat << EOF > "${DISTRO_ISO_DIR_PATH}/README.md"
# ${TARGET_BUSINESS_NAME} ${TARGET_BUILD_VERSION}

${TARGET_BUSINESS_NAME} is a custom Ubuntu-based Linux distribution that offers a familiar and easy-to-use experience for anyone moving to Linux.

This image is built with the following configurations:

- **Version**: ${TARGET_BUILD_VERSION}
- **Date**: ${DATE}


## Please verify the checksum!!!

To verify the integrity of the image, you can calculate the md5sum of the image and compare it with the value in the file \`md5sum.txt\`.

To do this, run the following command in the terminal:

\`\`\`bash
md5sum -c md5sum.txt | grep -v 'OK'
\`\`\`

No output indicates that the image is correct.

## How to use

Press F12 to enter the boot menu when you start your computer. Select the USB drive to boot from.

## More information

EOF

	pushd "${DISTRO_ISO_DIR_PATH}"

	print_info "Creating EFI boot image on /isolinux/efiboot.img ..."
	(
		cd isolinux && \
		dd if=/dev/zero of=efiboot.img bs=1M count=10 && \
		mkfs.vfat efiboot.img && \
		mkdir efi && \
		mount efiboot.img efi

		if ! grub-install --target=x86_64-efi --efi-directory=efi --boot-directory=boot --uefi-secure-boot --removable --no-nvram; then
			umount efi
			print_error "grub-install failed!"
			exit 1
		fi

		umount efi && \
		rm -rf efi
	)
	judge "Create EFI boot image"

	print_info "Creating BIOS boot image on /isolinux/bios.img ..."
	grub-mkstandalone \
		--format=i386-pc \
		--output=isolinux/core.img \
		--install-modules="linux16 linux normal iso9660 biosdisk memdisk search tar ls font gfxterm all_video" \
		--modules="linux16 linux normal iso9660 biosdisk search font gfxterm all_video" \
		--locales="" \
		--fonts="" \
		"boot/grub/grub.cfg=isolinux/grub.cfg"
	judge "Create BIOS boot image"

	print_info "Creating hybrid boot image on /isolinux/bios.img ..."
	cat /usr/lib/grub/i386-pc/cdboot.img isolinux/core.img > isolinux/bios.img
	judge "Create hybrid boot image"

	print_info "Creating .disk/info ..."
	echo "${TARGET_BUSINESS_NAME} ${TARGET_BUILD_VERSION} ${TARGET_UBUNTU_VERSION} - Release amd64 ($(date +%Y%m%d))" | tee .disk/info
	judge "Create .disk/info"

	print_info "Creating md5sum.txt ..."
	/bin/bash -c "(find . -type f -print0 | xargs -0 md5sum | grep -v -e 'md5sum.txt' -e 'bios.img' -e 'efiboot.img' > md5sum.txt)"
	judge "Create md5sum.txt"

	local build_iso_file_main_name="${TARGET_NAME}"
	local build_iso_file_name="${build_iso_file_main_name}.iso"
	local build_iso_file_path="${WORK_DIR_PATH}/${build_iso_file_name}"

	local dist_iso_file_main_name="${TARGET_NAME}-${TARGET_BUILD_VERSION}-${TARGET_ARCH}-${DATE}"
	local dist_iso_file_name="${dist_iso_file_main_name}.iso"
	local dist_iso_file_path="${DIST_DIR_PATH}/${dist_iso_file_name}"

	local sha256_file_name="${dist_iso_file_main_name}.sha256"
	local sha256_file_path="${DIST_DIR_PATH}/${sha256_file_name}"

	print_info "Creating iso image on ${WORK_DIR_PATH}/${TARGET_NAME}.iso ..."
	xorriso \
		-as mkisofs \
		-r -J \
		-iso-level 3 \
		-full-iso9660-filenames \
		-volid "${TARGET_ISO_VOLID}" \
		-eltorito-boot boot/grub/bios.img \
			-no-emul-boot \
			-boot-load-size 4 \
			-boot-info-table \
			--eltorito-catalog boot/grub/boot.cat \
			--grub2-boot-info \
			--grub2-mbr /usr/lib/grub/i386-pc/boot_hybrid.img \
		-eltorito-alt-boot \
			-e EFI/efiboot.img \
			-no-emul-boot \
			-append_partition 2 0xef isolinux/efiboot.img \
		-output "${build_iso_file_path}" \
		-m "isolinux/efiboot.img" \
		-m "isolinux/bios.img" \
		-graft-points \
			"/EFI/efiboot.img=isolinux/efiboot.img" \
			"/boot/grub/grub.cfg=isolinux/grub.cfg" \
			"/boot/grub/bios.img=isolinux/bios.img" \
			"."

	judge "Create iso image"

	print_info "Moving iso image to ${dist_iso_file_path} ..."
	mkdir -p "${DIST_DIR_PATH}"
	mv "${build_iso_file_path}" "${dist_iso_file_path}"
	judge "Move iso image"

	print_info "Generating sha256 checksum ..."
	local HASH=$(sha256sum "${dist_iso_file_path}" | cut -d ' ' -f 1)
	echo "SHA256: ${HASH}" | tee "${sha256_file_path}" > /dev/null 2>&1
	judge "Generate sha256 checksum"

	popd
}

function umount_on_exit () {

	sleep 2

	print_info "Umount before exit ..."
	umount "${DISTRO_IMG_DIR_PATH}/sys" || umount -lf "${DISTRO_IMG_DIR_PATH}/sys" || true
	umount "${DISTRO_IMG_DIR_PATH}/proc" || umount -lf "${DISTRO_IMG_DIR_PATH}/proc" || true
	umount "${DISTRO_IMG_DIR_PATH}/dev" || umount -lf "${DISTRO_IMG_DIR_PATH}/dev" || true
	umount "${DISTRO_IMG_DIR_PATH}/run" || umount -lf "${DISTRO_IMG_DIR_PATH}/run" || true
	judge "Umount before exit"

}




################################################################################
# Main
################################################################################

cd "${WORK_DIR_PATH}"
core_check_permission
bind_signal
clean
download_base_system
mount_folders
setup_apt
run_chroot
umount_folders
build_iso
echo "${0} - Initial build is done!"
