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

function mod_config_network_manager () {

	print_info "Configuring network manager ..."

	mkdir -p "/etc/NetworkManager"

cat << EOF > "/etc/NetworkManager/NetworkManager.conf"
[main]
rc-manager=resolvconf
plugins=ifupdown,keyfile
dns=dnsmasq

[ifupdown]
managed=false
EOF

	judge "Configure network manager"

}

function mod_config_netplan () {

	print_info "Configuring netplan ..."

	mkdir -p "/etc/netplan"

cat << EOF > "/etc/netplan/01-network-manager-all.yaml"
network:
  version: 2
  renderer: NetworkManager
EOF
	judge "Configure netplan"

}

function model_base_network_config_install () {

	mod_config_network_manager
	mod_config_netplan

}




################################################################################
# Main
################################################################################

function portal_base_network_config_install () {

	core_check_permission

	print_info "Config Network ..."
	model_base_network_config_install
	judge "Config Network"

}

portal_base_network_config_install
