#!/usr/bin/env bash

# env config options and their defaults

# directory containing Mod and World directories
: "${TMLSAVEDIR:=/tModLoader}"

# the config file to use
: "${TMLCONFIG:="${TMLSAVEDIR}/serverconfig.txt"}"


# if arg 1 doesn't look like a flag run it
if [[ "${1}" != -*  ]]; then
    exec "${@}"
fi

die() { echo "${@}"; exit 1; }

if [[ ! -d "${TMLSAVEDIR}" ]]; then
    echo "TMLSAVEDIR ${TMLSAVEDIR@Q} does not exist"
    echo "Creating..."
    mkdir -p "${TMLSAVEDIR}" || die "Failed to create TMLSAVEDIR"
fi

if [[ ! -f "${TMLCONFIG}" ]]; then
    echo "TMLCONFIG ${TMLCONFIG@Q} does not exist"
    echo "Copying from ${PWD}/serverconfig.txt.example"
    cp "${PWD}/serverconfig.txt.example" "${TMLCONFIG}" || die "Failed to copy TMLCONFIG"

    echo "Adjusting examples to current environment..."
    sed -i \
        -e "/^#world=/s|^.*$|#world=${TMLSAVEDIR}/Worlds/world1.wld|" \
        -e "/^#worldpath=/s|^.*$|#worldpath=${TMLSAVEDIR}/Worlds|" \
        -e "/^#banlist=/s|^.*$|#banlist=${TMLSAVEDIR}/banlist.txt|" \
        -e "/^#modpath=/s|^.*$|#modpath=${TMLSAVEDIR}/Mods|" \
        "${TMLCONFIG}" || die "Failed to adjust example config"
fi

SERVER_ARGS=(
    -server
    -tmlsavedirectory "${TMLSAVEDIR}"
    -config "${TMLCONFIG}"
)

# run server with flags appended
set -- \
    dotnet \
    /opt/tModLoader/tModLoader.dll \
    "${SERVER_ARGS[@]}" \
    "${@}"

exec "${@}"
