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
# Util
################################################################################

function sys_find_supported_locales_list () {

	local locales="${SUPPORTED_LOCALES}"
	local code=""
	local list=""

	while IFS="|" read -r code _; do
		# trim whitespace that may trail the locale code
		code=$(printf '%s' "${code}" | xargs)
		[ -z "${code}" ] && continue
		if [[ "${code}" =~ ^[a-z]{2}_[A-Z]{2}$ ]]; then
			echo "${code}.UTF-8 UTF-8" >> /etc/locale.gen
			list="${list} ${code}"
		else
			true;
			#print_warn "Skipping malformed locale code from SUPPORTED_LOCALES: '${code}'"
		fi
	done <<< "${locales}"

	echo ${list}

}




################################################################################
# Module
################################################################################

function mod_basic_locales_supported_generate_v1 () {

	print_info "Generating locales from SUPPORTED_LOCALES ..."

	if [ -z "${SUPPORTED_LOCALES:-}" ]; then
		print_error "SUPPORTED_LOCALES is empty or not set — cannot generate locales"
		exit 1
	fi

	local code=""

	## > /etc/locale.gen
	while IFS="|" read -r code _; do
		# trim whitespace that may trail the locale code
		code=$(printf '%s' "${code}" | xargs)
		[ -z "${code}" ] && continue
		if [[ "${code}" =~ ^[a-z]{2}_[A-Z]{2}$ ]]; then
			echo "${code}.UTF-8 UTF-8" >> /etc/locale.gen
		else
			print_warn "Skipping malformed locale code from SUPPORTED_LOCALES: '${code}'"
		fi
	done <<< "${SUPPORTED_LOCALES}"

	if [ ! -s /etc/locale.gen ]; then
		print_error "No valid locales extracted from SUPPORTED_LOCALES"
		exit 1
	fi

	print_info "Generating locales (this might take a while) ..."
	locale-gen
	judge "Generate locales from SUPPORTED_LOCALES"

}

function mod_basic_locales_supported_generate_v2 () {

	print_info "Generating locales from SUPPORTED_LOCALES ..."

	local list=""

	if [ -z "${SUPPORTED_LOCALES:-}" ]; then
		print_error "SUPPORTED_LOCALES is empty or not set — cannot generate locales"
		exit 1
	fi

	if [ ! -s /etc/locale.gen ]; then
		print_error "No valid locales extracted from SUPPORTED_LOCALES"
		exit 1
	fi

	print_info "Generating locales (this might take a while) ..."
	list=$(sys_find_supported_locales_list)
	echo locale-gen --lang ${list}
	locale-gen --lang ${list}
	judge "Generate locales from SUPPORTED_LOCALES"

}




################################################################################
# Model
################################################################################

function model_basic_locales_supported_generate () {

	##mod_basic_locales_supported_generate_v1

	mod_basic_locales_supported_generate_v2

}




################################################################################
# Main
################################################################################

function portal_basic_locales_supported_generate () {

	core_check_permission

	print_info "Generate Locales ..."
	model_basic_locales_supported_generate
	judge "Generate Locales"

}

portal_basic_locales_supported_generate
