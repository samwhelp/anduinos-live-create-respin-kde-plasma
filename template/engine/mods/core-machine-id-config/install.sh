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

function model_core_machine_id_config () {

	dbus-uuidgen > /etc/machine-id
	ln -fs /etc/machine-id /var/lib/dbus/machine-id

}




################################################################################
# Main
################################################################################

function portal_core_machine_id_config () {

	core_check_permission

	print_info "Configuring machine id ..."
	model_core_machine_id_config
	judge "Configure machine id"

}

portal_core_machine_id_config
