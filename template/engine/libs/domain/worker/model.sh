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
