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

function model_basic_language_pack_install () {

	local VALID_PACKAGES=""

	print_info "Filtering available language packs ..."
	print_info "(this might take a while)"
	for pkg in ${LANGUAGE_PACKS}; do
		if apt-get install -s -y "${pkg}" >/dev/null 2>&1; then
			VALID_PACKAGES="${VALID_PACKAGES} ${pkg}"
		else
			print_warn "Package ${pkg} is not installable (no candidate or broken), skipping."
		fi
	done


	print_info "Installing available language packs ..."
	print_info "(this might take a while)"
	if [ -n "${VALID_PACKAGES}" ]; then
		apt install -y ${VALID_PACKAGES} --no-install-recommends
		judge "Install language packs"
	else
		print_warn "No language packs were valid for installation."
	fi


}




################################################################################
# Main
################################################################################

function portal_basic_language_pack_install () {

	core_check_permission

	print_info "Install language-pack Package ..."
	model_basic_language_pack_install
	judge "Install language-pack Package"

}

portal_basic_language_pack_install
