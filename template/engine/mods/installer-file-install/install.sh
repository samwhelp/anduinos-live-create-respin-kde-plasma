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
LIBS_DIR_PATH="$(realpath "${BASE_DIR_PATH}/../../libs")"


################################################################################
# Init
################################################################################

source "${LIBS_DIR_PATH}/domain/worker/init.sh"




################################################################################
# Model Path
################################################################################

##
## uncoment for overwrite
##

##INSTALLER_ASSET_DIR_PATH="${BASE_DIR_PATH}/asset"
##INSTALLER_OVERLAY_DIR_PATH="${INSTALLER_ASSET_DIR_PATH}/overlay"
##INSTALLER_PACKAGE_DIR_PATH="${INSTALLER_ASSET_DIR_PATH}/package"
##INSTALLER_PACKAGE_INSTALL_DIR_PATH="${INSTALLER_PACKAGE_DIR_PATH}/install"




################################################################################
# Model
################################################################################

function model_installer_file_install () {

	mkdir -p "${INSTALLER_OVERLAY_DIR_PATH}"
	cp -rfT "${INSTALLER_OVERLAY_DIR_PATH}" /

}




################################################################################
# Main
################################################################################

function portal_installer_file_install () {

	core_check_permission

	print_info "Install Installer File ..."
	model_installer_file_install
	judge "Install Installer File"

}

portal_installer_file_install
