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


################################################################################
# LIVE ISO BUILD SPECIFIC LOGIC
# We MUST use initramfs-tools here because Dracut cannot
# boot an Ubuntu 'casper' Live ISO natively.
################################################################################

function model_kernel_initramfs_create () {

	if command -v update-initramfs >/dev/null 2>&1; then
		print_ok "Using initramfs-tools to ensure 'casper' live-boot capability ..."
		update-initramfs -c -k all
	else
		print_error "ERROR: initramfs-tools is missing! Casper live boot will fail."
		exit 1
	fi

}




################################################################################
# Main
################################################################################

function portal_kernel_initramfs_create () {

	core_check_permission

	print_info "Create initramfs for LIVE ISO ..."
	model_kernel_initramfs_create
	judge "Create initramfs"

}

portal_kernel_initramfs_create
