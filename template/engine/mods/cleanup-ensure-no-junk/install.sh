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

function model_cleanup_ensure_no_junk () {

	# remove unused and clean up apt cache
	print_info "Removing unused packages ..."
	apt autoremove -y --purge
	judge "Remove unused packages"

	local EXIT_IF_UNNECESSARY_PACKAGE_FOUND=1

	print_info "Purging unnecessary packages"
	local packages=(
		# ── Ubuntu desktop metapackages ────────────────────────────
		ubuntu-desktop
		ubuntu-desktop-minimal

		# ── Snap ecosystem ─────────────────────────────────────────
		snapd
		snap
		snap-store

		# ── Ubuntu session & branding ──────────────────────────────
		ubuntu-session
		yaru-theme-gnome-shell
		yaru-theme-unity
		yaru-theme-icon
		yaru-theme-gtk
		ubuntu-wallpapers
		ubuntu-wallpaper

		# ── Ubuntu Pro / upgrader / telemetry ──────────────────────
		ubuntu-pro-client
		ubuntu-advantage-desktop-daemon
		ubuntu-advantage-tools
		ubuntu-pro-client-l10n
		ubuntu-release-upgrader-core
		ubuntu-release-upgrader-gtk
		update-notifier
		update-notifier-common
		update-manager
		update-manager-core
		apport
		popularity-contest
		ubuntu-report
		whoopsie

		# ── Ubuntu GNOME extensions (AnduinOS ships own versions) ─
		gnome-shell-ubuntu-extensions
		gnome-shell-extension-ubuntu-dock
		gnome-shell-extension-appindicator
		gnome-shell-extension-dash-to-panel
		gnome-shell-extension-desktop-icons-ng
		gnome-shell-extension-gtk4-desktop-icons-ng

		# ── Packages replaced by AnduinOS forks ───────────────────
		firefox
		software-properties-common
		software-properties-gtk
		firmware-sof-signed
		alsa-ucm-conf
		plymouth-theme-spinner
		ubiquity-slideshow-ubuntu

		# ── LibreOffice (monster package) ──────────────────────────
		libreoffice-*

		# ── Alternative terminals (AnduinOS uses Ptyxis) ──────────
		alacritty
		gnome-terminal
		tilix
		zutty
		xterm

		# ── GNOME apps / games (unwanted) ─────────────────────────
		gnome-mahjongg
		gnome-mines
		gnome-sudoku
		aisleriot
		hitori
		gnome-initial-setup
		gnome-photos
		eog
		gnome-contacts

		# ── Dev tools not needed at runtime ────────────────────────
		gdb
		build-essential
	)

	local violators=()

	local pkg=""

	for pkg in "${packages[@]}"; do
		if dpkg -l "${pkg}" 2>/dev/null | grep -q '^ii'; then
			print_warn "Unwanted package found: ${pkg}"
			violators+=("${pkg}")
			apt autoremove -y --purge "${pkg}"
		fi
	done

	if [[ ${#violators[@]} -gt 0 && $EXIT_IF_UNNECESSARY_PACKAGE_FOUND -eq 1 ]]; then
		print_error "Build failed! The following unnecessary packages were injected: ${violators[*]}"
		exit 1
	fi


}




################################################################################
# Main
################################################################################

function portal_cleanup_ensure_no_junk () {

	core_check_permission

	print_info "Remove Package ..."
	model_cleanup_ensure_no_junk
	judge "Remove Package"

}

portal_cleanup_ensure_no_junk
