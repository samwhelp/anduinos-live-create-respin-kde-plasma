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

function model_core_systemd_package_install () {

	apt install -y \
		systemd-sysv \
		libterm-readline-gnu-perl \
	--install-recommends

}




################################################################################
# Main
################################################################################

function portal_core_systemd_package_install () {

	core_check_permission

	print_info "Install Systemd Package ..."
	model_core_systemd_package_install
	judge "Install Systemd Package"

}

portal_core_systemd_package_install
