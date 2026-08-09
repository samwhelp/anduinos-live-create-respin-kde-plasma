#!/usr/bin/env bash


################################################################################
# Set up the environment
################################################################################

set -e						# exit on error
set -o pipefail				# exit on pipeline error
set -u						# treat unset variable as error


BASE_DIR_PATH="$(dirname "$(realpath "${0}")")"




################################################################################
# Main
################################################################################

echo "${BASE_DIR_PATH}/rundown.sh" "fulfill-for-basic-system.txt"
"${BASE_DIR_PATH}/rundown.sh" "fulfill-for-basic-system.txt"
