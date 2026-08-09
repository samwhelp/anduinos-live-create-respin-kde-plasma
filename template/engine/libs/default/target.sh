#!/usr/bin/env bash


################################################################################
# Default Target
################################################################################




################################################################################
# OS system information
################################################################################

# This is the apt source for both the build process and the live system.
# It can be any Ubuntu mirror that you prefer.
# You can change it to any other mirror that you prefer.
# See https://docs.anduinos.com/Install/Select-Best-Apt-Source.html
APT_SOURCE="http://archive.ubuntu.com/ubuntu"

# This is the target Ubuntu version code name for the build.
# It should match the Ubuntu version you are building against.
# For example, if you are building against Ubuntu 22.04 LTS, this should be "jammy".
# If you are building against Ubuntu 24.04 LTS, this should be "noble".
# If you are building against Ubuntu 24.10, this should be "oracular".
# If you are building against Ubuntu 25.04, this should be "plucky".
# If you are building against Ubuntu 25.10, this should be "questing".
# If you are building against Ubuntu 26.04, this should be "resolute".
# Can be: jammy noble oracular plucky questing resolute
TARGET_UBUNTU_VERSION="resolute"

# This is the target CPU architecture.
#   amd64 — Intel / AMD 64-bit
#   arm64 — ARM 64-bit (Raspberry Pi, Snapdragon, Apple Silicon, etc.)
#TARGET_ARCH="$(dpkg --print-architecture)"
TARGET_ARCH=amd64

# This is the name of the target OS.
# Must be lowercase without special characters and spaces
TARGET_NAME="anduinos"

# This is the full display name of the target OS.
# Business name. No special characters or spaces
TARGET_BUSINESS_NAME="AnduinOS"

# Version number. Must be in the format of x.y.z
TARGET_BUILD_VERSION="2.0.0"

# For xorriso -volid
TARGET_ISO_VOLID="ANDUINOS"

################################################################################
# Installer customization
################################################################################

# Packages will be uninstalled during the installation process
TARGET_PACKAGE_REMOVE="
	ubiquity \
	casper \
	discover \
	laptop-detect \
	os-prober \
	gparted \
	anduinos-installer-config \
	anduinos-bwrap-hack \
"

################################################################################
# AnduinOS APKG server configuration
################################################################################

# AnduinOS APT config package name (can also be anduinos-apt-config-dev).
APT_CONFIG_PACKAGE="anduinos-apt-config"

# APKG server URL for AnduinOS-branded overlay packages.
APKG_SERVER="https://packages.anduinos.com"

# GPG certificate name on the APKG server (used to download and verify the repo).
# The cert is fetched from: ${APKG_SERVER}/artifacts/certs/${APKG_CERT_NAME}
APKG_CERT_NAME="anduinos"
