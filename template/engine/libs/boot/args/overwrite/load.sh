#!/usr/bin/env bash


################################################################################
# Args / Section / Load
################################################################################

function master_args_load () {

	local args_dir_path="${ARGS_DIR_PATH}"
	local overwrite_dir_path="${args_dir_path}/overwrite"

	local load_value=""


	##
	## ## TARGET_UBUNTU_VERSION: args/overwrite/TARGET_UBUNTU_VERSION.txt
	##

	load_value="$(core_args_load "${overwrite_dir_path}/TARGET_UBUNTU_VERSION.txt")"
	TARGET_UBUNTU_VERSION="${load_value:=$TARGET_UBUNTU_VERSION}"


	##
	## ## TARGET_ARCH: args/overwrite/TARGET_ARCH.txt
	##

	load_value="$(core_args_load "${overwrite_dir_path}/TARGET_ARCH.txt")"
	TARGET_ARCH="${load_value:=$TARGET_ARCH}"


	##
	## ## TARGET_NAME: args/overwrite/TARGET_NAME.txt
	##

	load_value="$(core_args_load "${overwrite_dir_path}/TARGET_NAME.txt")"
	TARGET_NAME="${load_value:=$TARGET_NAME}"


	##
	## ## TARGET_BUSINESS_NAME: args/overwrite/TARGET_BUSINESS_NAME.txt
	##

	load_value="$(core_args_load "${overwrite_dir_path}/TARGET_BUSINESS_NAME.txt")"
	TARGET_BUSINESS_NAME="${load_value:=$TARGET_BUSINESS_NAME}"


	##
	## ## TARGET_BUILD_VERSION: args/overwrite/TARGET_BUILD_VERSION.txt
	##

	load_value="$(core_args_load "${overwrite_dir_path}/TARGET_BUILD_VERSION.txt")"
	TARGET_BUILD_VERSION="${load_value:=$TARGET_BUILD_VERSION}"

}

master_args_load
