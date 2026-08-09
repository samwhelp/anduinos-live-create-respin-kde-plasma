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

function model_base_dconf_db_update () {

	dconf update

}




################################################################################
# Main
################################################################################

function portal_base_dconf_db_update () {

	core_check_permission

	print_info "Update Dconf DB ..."
	model_base_dconf_db_update
	judge "Update Dconf DB"

}

portal_base_dconf_db_update
