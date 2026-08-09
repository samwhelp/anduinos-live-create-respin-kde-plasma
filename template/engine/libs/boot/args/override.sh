#!/usr/bin/env bash


################################################################################
# Args / Override
################################################################################


##
## ## args/override/main.sh
##

if [ -f "${ARGS_DIR_PATH}/override/main.sh" ]; then
	source "${ARGS_DIR_PATH}/override/main.sh"
fi
