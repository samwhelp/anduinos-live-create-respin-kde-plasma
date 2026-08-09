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

function model_base_gsettings_schema_compile () {

	glib-compile-schemas /usr/share/glib-2.0/schemas

}




################################################################################
# Main
################################################################################

function portal_base_gsettings_schema_compile () {

	print_info "Compile Gsettings Schema ..."
	model_base_gsettings_schema_compile
	judge "Compile Gsettings Schema"

}

portal_base_gsettings_schema_compile
