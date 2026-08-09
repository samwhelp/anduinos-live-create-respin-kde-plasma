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
LIBS_DIR_PATH="${BASE_DIR_PATH}/libs"


################################################################################
# Init
################################################################################

source "${LIBS_DIR_PATH}/domain/controller/init.sh"




################################################################################
# Main
################################################################################

sudo "${BASE_DIR_PATH}/do-build.sh"


##
## change dist owner to current user
##

#[ -d "${DIST_DIR_PATH}" ] && echo "change dist owner to current user"; sudo chown $(whoami):$(whoami) "${DIST_DIR_PATH}" -R
