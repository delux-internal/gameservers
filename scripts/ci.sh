#!/usr/bin/env bash

# by invaderctf and sappho.io

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# Helper functions
source ${SCRIPT_DIR}/helpers.sh

PULL_SH="1-pull.sh"
BUILD_SH="2-build.sh"


usage()
{
    echo "Usage, assuming you are running this as a ci script, which you should be"
    echo "  ./scripts/ci.sh pull|build <arguments>"
    echo "    pull: Cleans and pulls the repo (if applicable)"
    echo "    build: Build unbuilt and updated plugins"
    echo "    <arguments>: All arguments are passed down to the command, for more info check"
    echo "      ./scripts/${PULL_SH} usage"
    echo "      ./scripts/${BUILD_SH} usage"
    exit 1
}

# [[ ${CI} ]] || { error "This script is only to be executed in GitLab CI"; exit 1; }

# Input check
[[ "$#" == 0 ]] && usage

# Variable initialisation

# get first arg, pass it as command to run after iterating
COMMAND=${1}
# shift args down, deleting first arg as we just set it to a var
shift 1

# dumb bullshit logic for checking what folder our gameserver is in
# dirs to check for possible gameserver folders
TARGET_DIRS=(
    /srv/daemon-data
    /var/lib/pterodactyl/volumes
)

WORK_DIR=$(du -s "${TARGET_DIRS[@]}" 2> /dev/null | sort -n | tail -n1 | cut -f2)

# when one of those dirs doesn't exist we gotta run this
if [[ $? != 0 ]]; then

    if ! [ -d "/srv/daemon-data" ] && ! [ -d "/var/lib/pterodactyl/volumes" ]; then
        echo "no work dir!"
        exit 1

    elif ! [ -d "/srv/daemon-data" ]; then
        WORK_DIR="/var/lib/pterodactyl/volumes"

    elif ! [ -d "/var/lib/pterodactyl/volumes" ]; then
        WORK_DIR="/srv/daemon-data"

    else
        WORK_DIR=$(du -s "${TARGET_DIRS[@]}" 2> /dev/null  | sort -n | tail -n1 | cut -f2)

    fi
fi


if [[ -z "${WORK_DIR}" ]]; then
    hook "Couldn't find work dir!"
    echo "Couldn't find work dir!"
    exit 255
fi

debug "working dir: ${WORK_DIR}"

# go to our directory with (presumably) gameservers in it or die trying
cd "${WORK_DIR}" || { error "can't cd to workdir ${WORK_DIR}!!!"; hook "can't cd to workdir ${WORK_DIR}"; exit 1; }

# iterate thru directories in our work dir which we just cd'd to
for dir in ./*/ ; do
    # we didn't find a git folder
    if [ ! -d "${dir}/.git" ]; then
        warn "${dir} has no .git folder! skipping"
        hook "${dir} has no .git folder!"
        # maybe remove these in the future
        continue
    fi
    # we did find a git folder! print out our current folder
    important "Operating on: ${dir}"

    # go to our server dir or die trying
    cd "${dir}" || { error "can't cd to ${dir}"; continue; }

    # branches and remotes

    # sets ${thisbranch} to this dir's current git branch
    getThisBranch

    CI_LOCAL_REMOTE=$(git remote get-url origin)
    CI_LOCAL_REMOTE="${CI_LOCAL_REMOTE##*@}"
    CI_LOCAL_REMOTE="${CI_LOCAL_REMOTE/://}"
    CI_LOCAL_REMOTE="${CI_LOCAL_REMOTE%.git*}"
    CI_REMOTE_REMOTE="${CI_SERVER_HOST}/${CI_PROJECT_PATH}"

    info "Comparing branches ${thisbranch} and ${CI_COMMIT_REF_NAME}."
    info "Comparing local ${CI_LOCAL_REMOTE} and remote ${CI_REMOTE_REMOTE}."

    if [[ "${thisbranch}" == "${CI_COMMIT_REF_NAME}" ]] && [[ "${CI_LOCAL_REMOTE}" == "${CI_REMOTE_REMOTE}" ]]; then
        debug "branches match"
        case "${COMMAND}" in
            pull)
                info "Pulling git repo"
                # DON'T QUOTE THIS
                bash ${SCRIPT_DIR}/${PULL_SH} $*
                ;;
            build)
                COMMIT_OLD=$(git rev-parse HEAD~1)
                info "Building updated and uncompiled .sp files"
                # DON'T QUOTE THIS EITHER
                bash ${SCRIPT_DIR}/${BUILD_SH} ${COMMIT_OLD}
                ;;
            *)
                error "${COMMAND} is not supported"
                exit 1
                ;;
        esac
    else
        important "Branches do not match, doing nothing"
    fi
    cd ..
done


