#!/usr/bin/env bash

# Helper functions
source script/helpers.sh

# Variable initialisation
WORKING_DIR="tf/addons/sourcemod"
SPCOMP_PATH="scripting/spcomp64"
SCRIPTS_DIR="scripting"
COMPILED_DIR="plugins"

# Temporary files
UNCOMPILED_LIST=$(mktemp)
UPDATED_LIST=$(mktemp)
trap "rm -f ${UNCOMPILED_LIST} ${UPDATED_LIST}; popd >/dev/null" EXIT

usage() {
    echo "This script looks for all uncompiled .sp files"
    echo "and if a reference is gven, those that were updated"
    echo "Then it compiles everything"
    echo "Usage: ./build.sh <reference>"
    exit 1
}

# Just checking the git refernece is valid
reference_validation() {
    GIT_REF=${1}
    if git rev-parse --verify --quiet ${GIT_REF} > /dev/null; then
        info "Comparing against ${GIT_REF}"
    else
        error "Reference ${GIT_REF} does not exists"
        exit 2
    fi
}

# Check for all changed *.sp files inside ${WORKING_DIR}, then remove their *.smx counterparts and write the list to a file
list_updated(){
    UPDATED=$(git diff --name-only HEAD "${GIT_REF}" . | grep "\.sp$" | grep -v -e "/stac/" -e "/include/" -e "/disabled/" -e "/external/" -e "/economy/")
    
    info "Generating list of updated scripts:"
    while IFS= read -r line; do
        rm -f "${COMPILED_DIR}/$(basename ${line/.sp/.smx})"
        echo ${line/${WORKING_DIR}\//} >> ${UPDATED_LIST}
    done <<< "${UPDATED}"
}

# Find all *.sp files inside ${WORKING_DIR} that do not have a *.smx counterpart and write the list to a file
list_uncompiled(){
    UNCOMPILED=$(find ${SCRIPTS_DIR} -iname "*.sp" ! -path "*/stac/*" ! -path "*/include/*" ! -path "*/disabled/*" ! -path "*/external/*" ! -path "*/economy/*")

    info "Generating list of uncompiled scripts:"
    while IFS= read -r line; do
        [[ ! -f "${COMPILED_DIR}/$(basename ${line/.sp/.smx})" ]] && echo ${line} >> ${UNCOMPILED_LIST}
    done <<< "${UNCOMPILED}"
}

# This function takes a file as an argument
compile() {
    info "Compiling $(wc -l < ${1}) files"
    while read -r plugin; do
        info "Compiling ${plugin}"
        ./${SPCOMP_PATH} "${plugin}" -o "${COMPILED_DIR}/$(basename ${plugin/.sp/.smx})" -v0 #-E
        [[ $? -ne 0 ]] && compile_error ${plugin}
    done < ${1}
}

# Auxiliary function to catch errors on spcomp64
compile_error(){
    error "spcomp64 error while compiling ${1}"
    exit 255
}

###
# Script begins here ↓
pushd ${WORKING_DIR} >/dev/null
[[ ! -x ${SPCOMP_PATH} ]] && chmod u+x ${SPCOMP_PATH}

# Compile all scripts that have been updated
if [[ -n ${1} ]]; then
    reference_validation ${1}
    info "Looking for all .sp files that have been updated"
    list_updated
    info "Compiling updated plugins"
    compile ${UPDATED_LIST}
fi

# Compile all scripts that have not been compiled
info "Looking for all .sp files in ${WORKING_DIR}/${SCRIPTS_DIR}"
list_uncompiled
info "Compiling uncompiled plugins"
compile ${UNCOMPILED_LIST}

ok "All plugins compiled successfully !"
exit 0
