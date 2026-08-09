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
# Model Path
################################################################################

##
## uncoment for overwrite
##

##INSTALLER_ASSET_DIR_PATH="${BASE_DIR_PATH}/asset"
##INSTALLER_OVERLAY_DIR_PATH="${INSTALLER_ASSET_DIR_PATH}/overlay"
##INSTALLER_PACKAGE_DIR_PATH="${INSTALLER_ASSET_DIR_PATH}/package"
##INSTALLER_PACKAGE_INSTALL_DIR_PATH="${INSTALLER_PACKAGE_DIR_PATH}/install"




################################################################################
# Model
################################################################################

function util_load_list () {

	local file_path="${1}"

	local trim_line=""

	cat ${file_path} | while IFS='' read -r line; do

		trim_line=$(echo ${line}) # trim

		## https://www.gnu.org/software/bash/manual/html_node/Shell-Parameter-Expansion.html
		## ignore leading #
		if [ "${trim_line:0:1}" == '#' ]; then
			continue;
		fi

		## ignore empty line
		if [[ -z "${trim_line}" ]]; then
			continue;
		fi

		echo "${line}"

	done

}

function find_package_install_list_via_loader () {

	local package_install_list=""
	local list_dir_path="${INSTALLER_PACKAGE_INSTALL_DIR_PATH}"

	mkdir -p "${list_dir_path}"

	local item_file_path=""

	for item_file_path in ${list_dir_path}/*.txt; do

		if [[ -f "${item_file_path}" ]]; then
			util_load_list "${item_file_path}"
		fi

	done

}

function find_package_install_list_via_cat () {

	local package_install_list=""
	local list_dir_path="${INSTALLER_PACKAGE_INSTALL_DIR_PATH}"

	mkdir -p "${list_dir_path}"

	local item_file_path=""

	for item_file_path in ${list_dir_path}/*.txt; do

		if [[ -f "${item_file_path}" ]]; then
			cat "${item_file_path}"
		fi

	done

}

function find_package_install_list () {

	##local package_install_list=$(find_package_install_list_via_cat)
	local package_install_list=$(find_package_install_list_via_loader)

	echo ${package_install_list}

}

function model_installer_package_install () {

	local package_install_list=$(find_package_install_list)
	local run_cmd="apt install -y --install-recommends ${package_install_list}"

	echo ${run_cmd}
	${run_cmd}
	#apt install -y --install-recommends ${package_install_list}
	judge "Install Package"

}




################################################################################
# Main
################################################################################

function portal_installer_package_install () {

	core_check_permission

	print_info "Install Installer Package ..."
	model_installer_package_install
	judge "Install Installer Package"

}

portal_installer_package_install
