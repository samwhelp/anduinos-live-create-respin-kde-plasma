#!/usr/bin/env bash


################################################################################
# Module
################################################################################

function core_check_permission () {

	if [ $(id -u) -ne 0 ]; then
		print_error "This script should be run as 'root'"
		exit 1
	fi

}

function raw_var_dump () {

	echo "GEAR_DIR_PATH=${GEAR_DIR_PATH}"
	echo "LIBS_DIR_PATH=${LIBS_DIR_PATH}"
	echo "MODS_DIR_PATH=${MODS_DIR_PATH}"
	echo "ARGS_DIR_PATH=${ARGS_DIR_PATH}"

	echo "PLAN_DIR_PATH=${PLAN_DIR_PATH}"
	echo "TEMPLATE_DIR_PATH=${TEMPLATE_DIR_PATH}"

	echo "WORK_DIR_PATH=${WORK_DIR_PATH}"
	echo "DIST_DIR_PATH=${DIST_DIR_PATH}"
	echo "DISTRO_IMG_DIR_PATH=${DISTRO_IMG_DIR_PATH}"
	echo "DISTRO_ISO_DIR_PATH=${DISTRO_ISO_DIR_PATH}"

	echo "MASTER_ASSET_DIR_PATH=${MASTER_ASSET_DIR_PATH}"
	echo "MASTER_OVERLAY_DIR_PATH=${MASTER_OVERLAY_DIR_PATH}"
	echo "MASTER_PACKAGE_DIR_PATH=${MASTER_PACKAGE_DIR_PATH}"
	echo "MASTER_PACKAGE_INSTALL_DIR_PATH=${MASTER_PACKAGE_INSTALL_DIR_PATH}"

	echo "INSTALLER_ASSET_DIR_PATH=${INSTALLER_ASSET_DIR_PATH}"
	echo "INSTALLER_OVERLAY_DIR_PATH=${INSTALLER_OVERLAY_DIR_PATH}"
	echo "INSTALLER_PACKAGE_DIR_PATH=${INSTALLER_PACKAGE_DIR_PATH}"
	echo "INSTALLER_PACKAGE_INSTALL_DIR_PATH=${INSTALLER_PACKAGE_INSTALL_DIR_PATH}"

}

function core_var_dump () {

	print_info "Dump skeleton variables"

	raw_var_dump

	judge "Dump skeleton variables"

}

function raw_building_var_dump () {

	echo "APT_SOURCE=${APT_SOURCE}"
	echo "TARGET_UBUNTU_VERSION=${TARGET_UBUNTU_VERSION}"
	echo "TARGET_ARCH=${TARGET_ARCH}"
	echo "TARGET_NAME=${TARGET_NAME}"
	echo "TARGET_BUSINESS_NAME=${TARGET_BUSINESS_NAME}"
	echo "TARGET_BUILD_VERSION=${TARGET_BUILD_VERSION}"
	echo "APKG_SERVER=${APKG_SERVER}"

}

function core_building_var_dump () {

	print_info "Dump building variables"

	raw_building_var_dump

	judge "Dump building variables"

}

function core_create_skeleton_dir () {

	print_info "Create Skeleton Dir"
	mkdir -p "${WORK_DIR_PATH}"
	mkdir -p "${DIST_DIR_PATH}"
	mkdir -p "${DISTRO_IMG_DIR_PATH}"
	mkdir -p "${DISTRO_ISO_DIR_PATH}"
	judge "Create Skeleton Dir"

}


function sys_prepare_package_for_build () {

	print_info "Installing package for build ..."
	apt install -y \
		binutils \
		curl \
		debootstrap \
		gnupg \
		squashfs-tools \
		xorriso \
		grub-pc-bin \
		grub-efi-amd64 \
		grub2-common \
		mtools \
		dosfstools \
	--install-recommends
	judge "Install package"

}

function mod_prepare () {

	sys_prepare_package_for_build

}

function mod_bind_signal () {

	print_info "Bind signal ..."
	trap mod_unmount_on_exit EXIT INT TERM
	judge "Bind signal"

}

function mod_unmount_on_exit () {

	sleep 2
	print_info "Umount before exit ..."
	##set +e
	sys_unmount_before_clean

}

function raw_unmount_before_clean () {

	umount "${DISTRO_IMG_DIR_PATH}/sys" || umount -lf "${DISTRO_IMG_DIR_PATH}/sys" || true
	umount "${DISTRO_IMG_DIR_PATH}/proc" || umount -lf "${DISTRO_IMG_DIR_PATH}/proc" || true
	umount "${DISTRO_IMG_DIR_PATH}/dev" || umount -lf "${DISTRO_IMG_DIR_PATH}/dev" || true
	umount "${DISTRO_IMG_DIR_PATH}/run" || umount -lf "${DISTRO_IMG_DIR_PATH}/run" || true

	umount "${DISTRO_ISO_DIR_PATH}/isolinux/efi" || umount -lf "${DISTRO_ISO_DIR_PATH}/isolinux/efi" || true

}

function let_unmount_before_clean () {

	local node=""
	local path=""

	for node in proc sys dev/pts dev run; do
		path="${DISTRO_IMG_DIR_PATH}/${node}"
		let_unmount_node "${path}"
	done

	for node in isolinux/efi; do
		path="${DISTRO_ISO_DIR_PATH}/${node}"
		let_unmount_node "${path}"
	done


}

function try_unmount_before_clean () {

	local node=""
	local path=""

	for node in proc sys dev/pts dev run; do
		path="${DISTRO_IMG_DIR_PATH}/${node}"
		try_unmount_node "${path}"
	done

	for node in isolinux/efi; do
		path="${DISTRO_ISO_DIR_PATH}/${node}"
		try_unmount_node "${path}"
	done


}

function sys_unmount_before_clean () {

	##raw_unmount_before_clean
	try_unmount_before_clean
	##let_unmount_before_clean

}

function let_unmount_node () {

	local path="${1}"

	if mountpoint -q "${path}"; then
		umount "${path}" || umount -lf "${path}" || true
	fi

}

function try_unmount_node () {

	local path="${1}"

	umount "${path}" || umount -lf "${path}" || true

}

function mod_clean () {

	print_info "Cleaning up previous build ..."
	sys_unmount_before_clean
	rm -rf "${DISTRO_IMG_DIR_PATH}" "${DISTRO_ISO_DIR_PATH}" || true
	judge "Clean up build artifacts"

}

function sys_reload_systemd_daemon () {

	print_info "Reloading systemd daemon ..."
	systemctl daemon-reload
	judge "Reload systemd daemon"

}

function raw_mount () {

	##
	## https://github.com/mvallim/live-custom-ubuntu-from-scratch/blob/master/scripts/build.sh#L46-L52
	##

	##
	## sudo mount --bind /dev chroot/dev
	## sudo mount --bind /run chroot/run
	## sudo chroot chroot mount none -t proc /proc
	## sudo chroot chroot mount none -t sysfs /sys
	## sudo chroot chroot mount none -t devpts /dev/pts
	##

	print_info "Mounting ..."

	mount --bind /dev "${DISTRO_IMG_DIR_PATH}/dev" || true
	mount --bind /run "${DISTRO_IMG_DIR_PATH}/run" || true
	##judge "Mount /dev /run"

	chroot "${DISTRO_IMG_DIR_PATH}" mount none -t proc /proc || true
	chroot "${DISTRO_IMG_DIR_PATH}" mount none -t sysfs /sys || true
	chroot "${DISTRO_IMG_DIR_PATH}" mount none -t devpts /dev/pts || true
	##judge "Mount /proc /sys /dev/pts"

	print_info "Mount end."

}

function raw_unmount () {

	##
	## https://github.com/mvallim/live-custom-ubuntu-from-scratch/blob/master/scripts/build.sh#L54-L60
	##

	##
	## sudo chroot chroot umount -l /proc
	## sudo chroot chroot umount -l /sys
	## sudo chroot chroot umount -l /dev/pts
	## sudo umount -l chroot/dev
	## sudo umount -l chroot/run
	##

	print_info "Unmounting ..."

	chroot "${DISTRO_IMG_DIR_PATH}" umount -l /proc || true
	chroot "${DISTRO_IMG_DIR_PATH}" umount -l /sys || true
	chroot "${DISTRO_IMG_DIR_PATH}" umount -l /dev/pts || true
	judge "Unmount /proc /sys /dev/pts"


	umount -l "${DISTRO_IMG_DIR_PATH}/dev" || true
	umount -l "${DISTRO_IMG_DIR_PATH}/run" || true
	judge "Unmount /dev /run"

}

function let_unmount () {

	print_info "Unmounting ..."

	local node=""
	local path=""

	for node in proc sys dev/pts dev run; do
		path="${DISTRO_IMG_DIR_PATH}/${node}"
		let_unmount_node "${path}"
	done

}

function try_unmount () {

	print_info "Unmounting ..."

	local node=""
	local path=""

	for node in proc sys dev/pts dev run; do
		path="${DISTRO_IMG_DIR_PATH}/${node}"
		try_unmount_node "${path}"
	done

}


function sys_mount () {

	raw_mount

}

function sys_unmount () {

	raw_unmount
	##try_unmount
	##let_unmount

}

function mod_mount () {

	sys_unmount_before_clean
	sys_reload_systemd_daemon
	sys_mount

}

function mod_unmount () {

	sys_unmount_before_clean
	sys_unmount
}

function mod_chroot () {

	print_info "Chroot"

	mod_mount
	chroot "${DISTRO_IMG_DIR_PATH}"
	mod_unmount

}

function sys_create_core_system () {

	print_info "Creating new_building_os directory ..."
	mkdir -p "${DISTRO_IMG_DIR_PATH}"
	judge "Create build directory"


	print_info "Creating base system via debootstrap ..."
	echo debootstrap --arch=amd64 --variant=minbase --include=ca-certificates,openssl,console-setup-linux,console-setup,locales,tzdata,whiptail,wget,dbus "${TARGET_UBUNTU_VERSION}" "${DISTRO_IMG_DIR_PATH}" "${APT_SOURCE}"
	debootstrap --arch=amd64 --variant=minbase --include=ca-certificates,openssl,console-setup-linux,console-setup,locales,tzdata,whiptail,wget,dbus "${TARGET_UBUNTU_VERSION}" "${DISTRO_IMG_DIR_PATH}" "${APT_SOURCE}"
	judge "Creating base system via debootstrap"

}

function mod_create_core_system () {

	##
	## Only debootstrap
	##




	##
	## ## create skeleton dir
	##

	core_create_skeleton_dir




	##
	## ## debootstrap
	##

	sys_create_core_system

	#sys_copy_fulfill_scripts_to_chroot




	##
	## ## chroot
	##

	#mod_mount




	#mod_setup_locale_for_build_start

	#mod_setup_apt_for_core_system

	#sys_run_fulfill_scripts_for_core_system




	#mod_unmount

}

function mod_create_base_system () {

	##
	## debootstrap + base settings
	##




	##
	## ## create skeleton dir
	##

	core_create_skeleton_dir




	##
	## ## debootstrap
	##

	sys_create_core_system

	sys_copy_fulfill_scripts_to_chroot




	##
	## ## chroot
	##

	mod_mount




	mod_setup_locale_for_build_start

	mod_setup_apt_for_base_system

	sys_run_fulfill_scripts_for_base_system




	mod_unmount

}

function mod_create_basic_system () {

	##
	## debootstrap + base settings + anduinos apt-sources
	##




	##
	## ## create skeleton dir
	##

	core_create_skeleton_dir




	##
	## ## debootstrap
	##

	sys_create_core_system

	sys_copy_fulfill_scripts_to_chroot




	##
	## ## chroot
	##

	mod_mount




	mod_setup_locale_for_build_start

	mod_setup_apt_for_basic_system

	sys_run_fulfill_scripts_for_basic_system




	mod_unmount

}

function mod_create_full_system () {

	##
	## debootstrap + base settings + anduinos apt-sources + extra
	##




	##
	## ## create skeleton dir
	##

	core_create_skeleton_dir




	##
	## ## debootstrap
	##

	sys_create_core_system

	sys_copy_fulfill_scripts_to_chroot




	##
	## ## chroot
	##

	mod_mount




	mod_setup_locale_for_build_start

	mod_setup_apt_for_full_system

	sys_run_fulfill_scripts_for_full_system




	mod_unmount

}


function sys_copy_fulfill_scripts_to_chroot () {

	##
	## See Also: `function sys_run_fulfill_scripts_portal`
	##

	print_info "Copying fulfill scripts to chroot /opt/build ..."
	mkdir -p "${DISTRO_IMG_DIR_PATH}/opt/build/template/engine"
	[ -d "${ARGS_DIR_PATH}" ] && cp -rfT "${ARGS_DIR_PATH}" "${DISTRO_IMG_DIR_PATH}/opt/build/template/engine/args" || true
	cp -rfT "${LIBS_DIR_PATH}" "${DISTRO_IMG_DIR_PATH}/opt/build/template/engine/libs"
	cp -rfT "${MODS_DIR_PATH}" "${DISTRO_IMG_DIR_PATH}/opt/build/template/engine/mods"
	cp -rfT "${MASTER_ASSET_DIR_PATH}" "${DISTRO_IMG_DIR_PATH}/opt/build/template/asset"
	[ -d "${INSTALLER_ASSET_DIR_PATH}" ] && cp -rfT "${INSTALLER_ASSET_DIR_PATH}" "${DISTRO_IMG_DIR_PATH}/opt/build/template/installer" || true
	print_ok "Copying fulfill scripts to chroot /opt/build"

}

function sys_chroot_run_init_locale_to_en_us () {

	print_info "Init locale in chroot ..."


	print_info "Run locale-gen"

	echo >> "${DISTRO_IMG_DIR_PATH}/etc/locale.gen"
	echo "##" >> "${DISTRO_IMG_DIR_PATH}/etc/locale.gen"
	echo "## ## Head: manually_edited" >> "${DISTRO_IMG_DIR_PATH}/etc/locale.gen"
	echo "##" >> "${DISTRO_IMG_DIR_PATH}/etc/locale.gen"
	echo >> "${DISTRO_IMG_DIR_PATH}/etc/locale.gen"

	echo "C.UTF-8 UTF-8" >> "${DISTRO_IMG_DIR_PATH}/etc/locale.gen"
	echo "en_US.UTF-8 UTF-8" >> "${DISTRO_IMG_DIR_PATH}/etc/locale.gen"

	chroot "${DISTRO_IMG_DIR_PATH}" locale-gen --lang en_US.UTF-8 C.UTF-8
	judge "Run locale-gen"


	print_info "Setup locale.conf"
	echo "LANG=en_US.UTF-8" >> "${DISTRO_IMG_DIR_PATH}/etc/locale.conf"
	judge "Setup locale.conf"

}

function mod_setup_locale_for_build_start () {

	sys_chroot_run_init_locale_to_en_us

}

function sys_chroot_run_apt_update () {

	print_info "Running apt update in chroot ..."
	chroot "${DISTRO_IMG_DIR_PATH}" apt update
	judge "Apt update in chroot"

}

function sys_chroot_run_apt_upgrade () {

	##
	## Upgrade base system BEFORE mods run.  Swap packages (mod 01)
	## must not be visible to this upgrade — apt would try to
	## "normalize" them back to Ubuntu's lower version and fail.
	##

	print_info "Upgrading base system packages ..."
	chroot "${DISTRO_IMG_DIR_PATH}" apt -y upgrade
	judge "Upgrade base system"

}

function sys_config_apt_install_enable_recommends () {

	print_info "Enabling apt recommends in chroot ..."
	echo 'APT::Install-Recommends "true";' | tee "${DISTRO_IMG_DIR_PATH}/etc/apt/apt.conf.d/99-enable-recommends" > /dev/null
	judge "Enable apt recommends"

}

function sys_config_apt_sources_list_for_ubuntu () {

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

	##
	## Remove stale legacy-format sources.list (debootstrap artifact).
	## Ubuntu 24.04+ uses deb822 .sources files in sources.list.d/ instead.
	##
	rm -f "${DISTRO_IMG_DIR_PATH}/etc/apt/sources.list"

}

function sys_config_apt_sources_list_for_anduinos () {

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

}

function sys_config_apt_for_ubuntu () {

	sys_config_apt_install_enable_recommends

	sys_config_apt_sources_list_for_ubuntu

}

function sys_config_apt_for_anduinos () {

	sys_config_apt_install_enable_recommends

	sys_config_apt_sources_list_for_ubuntu

	sys_config_apt_sources_list_for_anduinos

}

function sys_setup_apt_for_ubuntu () {

	sys_config_apt_for_ubuntu

	sys_chroot_run_apt_update
	sys_chroot_run_apt_upgrade

}

function sys_setup_apt_for_anduinos () {

	sys_config_apt_for_anduinos

	sys_chroot_run_apt_update
	sys_chroot_run_apt_upgrade
}


function mod_setup_apt_for_core_system () {

	sys_setup_apt_for_ubuntu

}

function mod_setup_apt_for_base_system () {

	sys_setup_apt_for_ubuntu

}

function mod_setup_apt_for_basic_system () {

	sys_setup_apt_for_anduinos

}

function mod_setup_apt_for_full_system () {

	sys_setup_apt_for_anduinos

}

function sys_run_fulfill_scripts_portal () {

	##
	## See Also: `function sys_copy_fulfill_scripts_to_chroot`
	##

	local portal_file_name="${1}"

	print_info "Running $portal_file_name in new_building_os ..."
	print_warn "============================================"
	print_warn "   The following will run in chroot ENV!"
	print_warn "============================================"
	chroot "${DISTRO_IMG_DIR_PATH}" /usr/bin/env DEBIAN_FRONTEND=${DEBIAN_FRONTEND:-readline} /opt/build/template/engine/mods/$portal_file_name -
	print_warn "============================================"
	print_warn "   chroot ENV execution completed!"
	print_warn "============================================"
	judge "Run $portal_file_name in new_building_os"

	print_info "Sleeping for 5 seconds to allow chroot to exit cleanly ..."
	sleep 5
}

function sys_run_fulfill_scripts_for_core_system () {

	sys_run_fulfill_scripts_portal "fulfill-for-core-system.sh"

}

function sys_run_fulfill_scripts_for_base_system () {

	sys_run_fulfill_scripts_portal "fulfill-for-base-system.sh"

}

function sys_run_fulfill_scripts_for_basic_system () {

	sys_run_fulfill_scripts_portal "fulfill-for-basic-system.sh"

}

function sys_run_fulfill_scripts_for_full_system () {

	sys_run_fulfill_scripts_portal "fulfill-for-full-system.sh"

}

function sys_archive_system_to_iso () {

	print_info "Building ISO image ..."

	print_info "Creating image directory ..."
	rm -rf "${DISTRO_ISO_DIR_PATH}"
	mkdir -p "${DISTRO_ISO_DIR_PATH}"/{casper,isolinux,.disk}
	judge "Create image directory"

	# copy kernel files
	print_info "Copying kernel files as /casper/vmlinuz, /casper/initrd ..."
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

	##
	## Keep both names for remix compatibility:
	## - Legacy BIOS core.img may embed "/casper/initrd"
	## Having both avoids boot mismatch between BIOS and UEFI paths.
	##

	cp "${REAL_INITRD}" "${DISTRO_ISO_DIR_PATH}/casper/initrd"
	judge "Copy kernel files"

	print_info "Save build args ..."
	touch "${DISTRO_ISO_DIR_PATH}/${TARGET_NAME}"
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

	##
	## Copy system unicode.pf2 so GRUB can render CJK/Arabic/Thai labels.
	## Without loadfont, GRUB defaults to an ASCII-only built-in font.
	## Placed in both paths: isolinux (BIOS) and boot/grub/fonts (UEFI standard).
	##

	print_info "Preparing GRUB unicode font (for CJK) ..."
	mkdir -p "${DISTRO_ISO_DIR_PATH}/isolinux" "${DISTRO_ISO_DIR_PATH}/boot/grub/fonts"
	cp /usr/share/grub/unicode.pf2 "${DISTRO_ISO_DIR_PATH}/isolinux/unicode.pf2"
	cp /usr/share/grub/unicode.pf2 "${DISTRO_ISO_DIR_PATH}/boot/grub/fonts/unicode.pf2"
	judge "Prepare GRUB unicode font"

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
		-volid "${TARGET_ISO_VOLID^^}" \
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
	echo "${HASH}  ${dist_iso_file_name}" | tee "${sha256_file_path}" > /dev/null 2>&1
	judge "Generate sha256 checksum"

	popd

}

function mod_archive_system_to_iso () {

	sys_unmount_before_clean

	sys_archive_system_to_iso

}




################################################################################
# Model
################################################################################

function model_clean () {

	core_check_permission

	mod_bind_signal
	mod_clean

}

function model_create_core_system () {

	core_check_permission

	mod_bind_signal
	mod_clean

	mod_create_core_system

}

function model_create_base_system () {

	core_check_permission

	mod_bind_signal
	mod_clean

	mod_create_base_system

}

function model_create_basic_system () {

	core_check_permission

	mod_bind_signal
	mod_clean

	mod_create_basic_system

}

function model_create_full_system () {

	core_check_permission

	mod_bind_signal
	mod_clean

	mod_create_full_system

}

function model_mount () {

	core_check_permission

	mod_mount
}

function model_unmount () {

	core_check_permission

	mod_unmount
}

function model_chroot () {

	core_check_permission

	mod_bind_signal

	mod_chroot

}

function model_chroot_run () {
	echo "model_chroot_run"
	return 0
}

function model_archive_system_to_iso () {

	core_check_permission

	mod_bind_signal

	mod_archive_system_to_iso

}

function model_prepare () {

	core_check_permission

	mod_prepare

}

function model_build () {

	core_check_permission

	mod_bind_signal
	mod_clean

	mod_create_full_system

	mod_archive_system_to_iso

}
