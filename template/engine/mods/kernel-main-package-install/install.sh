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
# Model
################################################################################

function model_kernel_main_package_install () {

	apt install -y \
		linux-image-generic-hwe-26.04 \
		linux-headers-generic-hwe-26.04 \
		thermald \
	--no-install-recommends

}




################################################################################
# Main
################################################################################

function portal_kernel_main_package_install () {

	core_check_permission

	print_info "Install Kernel Package ..."
	model_kernel_main_package_install
	judge "Install Kernel Package"

}

portal_kernel_main_package_install
