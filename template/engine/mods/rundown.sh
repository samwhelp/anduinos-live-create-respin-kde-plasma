#!/usr/bin/env bash


################################################################################
# Set up the environment
################################################################################

set -e						# exit on error
set -o pipefail				# exit on pipeline error
#set -u						# treat unset variable as error


################################################################################
# Base Path
################################################################################

BASE_DIR_PATH="$(dirname "$(realpath "${0}")")"
LIBS_DIR_PATH="$(realpath "${BASE_DIR_PATH}/../libs")"


################################################################################
# Init
################################################################################

source "${LIBS_DIR_PATH}/domain/worker/init.sh"




################################################################################
# Dump building variables
################################################################################

print_info "Building variables for mods:"

core_building_var_dump




################################################################################
# Option
################################################################################

DEFAULT_RUNDOWN_FILE_NAME="rundown.txt"
RUNDOWN_FILE_NAME="${1}"
RUNDOWN_FILE_NAME="${RUNDOWN_FILE_NAME:=$DEFAULT_RUNDOWN_FILE_NAME}"


DEFAULT_INSTALL_FILE_NAME="install.sh"
INSTALL_FILE_NAME="${INSTALL_FILE_NAME:=$DEFAULT_INSTALL_FILE_NAME}"




################################################################################
# Model / Old
################################################################################

##
## Execute the module based on the folder name.
##

function run_mods_by_dirname () {
	local install_file_name="$INSTALL_FILE_NAME"
	local mods_dir_path="${MODS_DIR_PATH}"
	for mod in "$mods_dir_path"/*; do
		if [[ -d "$mod" && -f "$mod/$install_file_name" ]]; then
			print_info "Processing mod: $mod"
			(
				cd "$mod" && \
				chmod +x "$install_file_name" && \
				bash "$mod/$install_file_name"
			)
		fi
	done
}


################################################################################
# Model / New
################################################################################

##
## The install_all_mods.txt file is used to control which modules are executed and their execution order.
##

function util_load_list () {
	local file_path="${1}"
	cat $file_path  | while IFS='' read -r line; do
		trim_line=$(echo $line) # trim

		## https://www.gnu.org/software/bash/manual/html_node/Shell-Parameter-Expansion.html
		## ignore leading #
		if [ "${trim_line:0:1}" == '#' ]; then
			continue;
		fi

		## ignore empty line
		if [[ -z "$trim_line" ]]; then
			continue;
		fi

		echo "$line"
	done
}

function find_mods_list_via_loader () {
	local rundown_file_name="$RUNDOWN_FILE_NAME"
	local mods_dir_path="${MODS_DIR_PATH}"
	util_load_list "$mods_dir_path/$rundown_file_name"
}

function find_mods_list_via_cat () {
	local rundown_file_name="$RUNDOWN_FILE_NAME"
	local mods_dir_path="${MODS_DIR_PATH}"
	cat "$mods_dir_path/${rundown_file_name}"
}

function find_mods_list () {
	##local mods_list=$(find_mods_list_via_cat)
	local mods_list=$(find_mods_list_via_loader)
	echo $mods_list
}

function run_mods_by_list () {
	local install_file_name="$INSTALL_FILE_NAME"
	local mods_dir_path="${MODS_DIR_PATH}"
	local mods_list=$(find_mods_list)
	local mod_name
	local mod_dir_path
	local mod_install_file_path

	for mod_name in $mods_list; do
		mod_dir_path="$mods_dir_path/$mod_name"
		mod_install_file_path="$mod_dir_path/$install_file_name"

		if [[ -d "$mod_dir_path" && -x "$mod_install_file_path" ]]; then
			print_info "Processing mod: $mod_name"
			cd "$mod_dir_path" && \
			bash "$mod_install_file_path"
		fi
	done
}


################################################################################
# Main
################################################################################

##run_mods_by_dirname
run_mods_by_list
