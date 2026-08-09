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

##MASTER_ASSET_DIR_PATH="${BASE_DIR_PATH}/asset"
##MASTER_OVERLAY_DIR_PATH="${MASTER_ASSET_DIR_PATH}/overlay"
##MASTER_PACKAGE_DIR_PATH="${MASTER_ASSET_DIR_PATH}/package"
##MASTER_PACKAGE_INSTALL_DIR_PATH="${MASTER_PACKAGE_DIR_PATH}/install"




################################################################################
# Model
################################################################################

function model_master_file_install () {

	mkdir -p "${MASTER_OVERLAY_DIR_PATH}"
	cp -rfT "${MASTER_OVERLAY_DIR_PATH}" /

}




################################################################################
# Main
################################################################################

function portal_master_file_install () {

	core_check_permission

	print_info "Install Master File ..."
	model_master_file_install
	judge "Install Master File"

}

portal_master_file_install
