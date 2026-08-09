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
# Main
################################################################################




################################################################################
# Model
################################################################################

function model_cleanup_task () {

	# Clean up root home
	print_info "Cleaning up /root/ ..."
	rm -f /root/.config/mimeapps.list || true
	rm -rf /root/.local/share/gnome-shell/extensions || true
	rm -rf /root/.cache || true
	judge "Clean up /root/"

	# Clean up apt cache
	print_info "Cleaning up apt cache ..."
	find /var/cache/apt/archives -mindepth 1 -delete 2>/dev/null || true
	rm -f /var/cache/apt/pkgcache.bin /var/cache/apt/srcpkgcache.bin || true
	judge "Clean up apt cache"

	# Clean up apt lists (save ~50-80MB in the squashfs; the installed system
	# will re-fetch them on first apt update anyway)
	print_info "Cleaning up apt lists ..."
	find /var/lib/apt/lists -mindepth 1 -maxdepth 1 ! -name 'lock' ! -name 'partial' -delete 2>/dev/null || true
	judge "Clean up apt lists"

	# Clean up log files
	print_info "Cleaning up log files ..."
	find /var/log -mindepth 1 -delete 2>/dev/null || true
	judge "Clean up log files"

	## fix
	# Remove timezone files (systemd.timezone= on kernel cmdline sets them at boot)
	#print_info "Removing timezone files ..."
	#rm -f /etc/localtime /etc/timezone || true
	#judge "Remove timezone files"

	# Clean bash history and temp files
	print_info "Removing bash history and temporary files ..."
	find /tmp -mindepth 1 -delete 2>/dev/null || true
	rm -f ~/.bash_history 2>/dev/null || true
	export HISTSIZE=0
	judge "Remove bash history and temporary files"

	# Remove usr-is-merged folders
	print_info "Removing usr-is-merged folders ..."
	rm -rf /bin.usr-is-merged /lib.usr-is-merged /sbin.usr-is-merged || true
	judge "Remove usr-is-merged folders"

}




################################################################################
# Main
################################################################################

function portal_cleanup_task () {

	core_check_permission

	print_info "Process Cleanup Task ..."
	model_cleanup_task
	judge "Process Cleanup Task"

}

portal_cleanup_task
