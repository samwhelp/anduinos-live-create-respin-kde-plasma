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

function model_core_hostname_config () {

	print_info "Setting up hostname ..."
	echo "${TARGET_NAME}" > /etc/hostname
	judge "Set up hostname to ${TARGET_NAME}"

}




################################################################################
# Main
################################################################################

function portal_core_hostname_config () {

	core_check_permission

	print_info "Config hostname ..."
	model_core_hostname_config
	judge "Config hostname"

}

portal_core_hostname_config
