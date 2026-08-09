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

function model_base_network_package_install () {

	apt install -y \
		network-manager \
		net-tools \
		resolvconf \
	--install-recommends

}




################################################################################
# Main
################################################################################

function portal_base_network_package_install () {

	core_check_permission

	print_info "Install Network Package ..."
	model_base_network_package_install
	judge "Install Network Package"

}

portal_base_network_package_install
