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

function model_live_casper_config_install () {

cat << EOF > /etc/casper.conf
# This file should go in /etc/casper.conf
# Supported variables are:
# USERNAME, USERFULLNAME, HOST, BUILD_SYSTEM, FLAVOUR

export USERNAME="live"
export USERFULLNAME="${TARGET_BUSINESS_NAME} Live session user"
export HOST="${TARGET_NAME}"
export BUILD_SYSTEM="Ubuntu"

# USERNAME and HOSTNAME as specified above won't be honoured and will be set to
# flavour string acquired at boot time, unless you set FLAVOUR to any
# non-empty string.

export FLAVOUR="${TARGET_BUSINESS_NAME}"
EOF

}




################################################################################
# Main
################################################################################

function portal_live_casper_config_install () {

	core_check_permission

	print_info "Updating /etc/casper.conf"
	model_live_casper_config_install
	judge "Update /etc/casper.conf"

}

portal_live_casper_config_install
