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

function model_core_machine_id_clear () {

	##
	## Truncate machine id
	##

	truncate -s 0 /etc/machine-id || true
	truncate -s 0 /var/lib/dbus/machine-id || true

}




################################################################################
# Main
################################################################################

function portal_core_machine_id_clear () {

	core_check_permission

	print_info "Truncating machine id ..."
	model_core_machine_id_clear
	judge "Truncate machine id"

}

portal_core_machine_id_clear
