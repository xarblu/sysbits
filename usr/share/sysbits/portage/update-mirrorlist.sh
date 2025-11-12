#!/usr/bin/env bash

DEST="${BASH_SOURCE[0]%/*}/gentoo_mirrors.list"

function do_mirrorselect() {
    mirrorselect \
        --servers 50 \
        --http \
        --deep \
        --output
}

function do_header() {
    printf '# Auto-generated Gentoo mirror list\n'
    printf '# Run %s to update\n' "${BASH_SOURCE[0]##*/}"
    printf '\n'
    printf '# Last Update: %(%Y-%m-%d)T\n'
    printf '\n'
}

function main() {
    printf 'Updating mirror list file: %s\n' "${DEST}"
    do_header > "${DEST}" || exit 1
    do_mirrorselect >> "${DEST}" || exit 1
}

main "${@}"
