#!/bin/bash -efu

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
# See LICENSE for more details.
#
# Copyright: Red Hat Inc. 2021
# Author: Andrei Stepanov <astepano@redhat.com>

debug() {
    if [ -n "$DEBUG" ]; then
        echo "$*" >&2
    fi
}

PROG="${PROG:-${0##*/}}"
DEBUG="${DEBUG:-}"
DEF_PREFIX="mirror"

msg_usage() {
    cat << EOF

Mirror docker.io images to quay.io

Usage:
$PROG <options>

Options:
-h, --help              display this help and exit
-v, --verbose           turn on debug
-u, --user=USER         quay.io user, env: SYNC_USER
-p, --password=PASSWORD quay.io password, env: SYNC_PASSWORD
-n, --namespace=NS      quay.io destination namespace. env: SYNC_DST_NAMESPACE
-f, --file=FILE         path to file with repos, env: SYNC_INPUT_FILE
    --prefix=PREFIX     add prefix to destination repos. Default: '${DEF_PREFIX}'
EOF
}

opt_str="$@"
opt=$(getopt -n "$0" --options "hvu:p:f:" --longoptions "help,verbose,user:,password:,file:,prefix:,namespace:" -- "$@")
eval set -- "$opt"
while [[ $# -gt 0 ]]; do
    case "$1" in
        -r|--repo)
            OPT_REPO="$2"
            shift 2
            ;;
        -u|--user)
            OPT_USER="$2"
            shift 2
            ;;
        -p|--password)
            OPT_PASSWORD="$2"
            shift 2
            ;;
        -f|--file)
            OPT_FILE="$2"
            shift 2
            ;;
        --prefix)
            OPT_PREFIX="$2"
            shift 2
            ;;
        -n|--namespace)
            OPT_NAMESPACE="$2"
            shift 2
            ;;
        -v|--verbose)
            DEBUG="yes"
            shift
            ;;
        -h|--help)
            msg_usage
            exit 0
            ;;
        --)
            shift
            ;;
        *)
            msg_usage
            exit 1
    esac
done

# Command-line opts take priority ower env vars
DEBUG="${DEBUG:-}"
USER="${OPT_USER:-${SYNC_USER:-}}"
FILE="${OPT_FILE:-${SYNC_INPUT_FILE:-}}"
NAMESPACE="${OPT_NAMESPACE:-${SYNC_DST_NAMESPACE:-}}"
PASSWORD="${OPT_PASSWORD:-${SYNC_PASSWORD:-}}"
PREFIX="${OPT_PREFIX:-${DEF_PREFIX}}"

# Test correct invocation
if [ "${NAMESPACE}" = ''  -o  "${USER}" = ''  -o  "${FILE}" = '' -o "${PASSWORD}" = '' ]; then
    echo "Use: $PROG -h for help."
    exit
fi

if ! [ -r "$FILE" ]; then
    echo "Cannot open input file: $FILE"
    exit 1
fi

OLDIFS=$IFS
IFS=$'\n'
REPOS=($(cat "$FILE"))
IFS=$OLDIFS

for i in "${REPOS[@]}"; do
    if [ -z "${i###*}" ]; then
        # ignore comments, lines starting in '#'
        continue
    fi
    # Expected format: docker://docker.io/centos/nodejs-10-centos7:latest
    src="${i}"
    image="${src#*//*/}"
    image="${image////-}"
    dst="docker://quay.io/${NAMESPACE}/${PREFIX}-${image}"
    echo "[COPY] $src -> $dst"
    skopeo copy --dest-creds "${USER}:${PASSWORD}" "$src" "$dst"
done
