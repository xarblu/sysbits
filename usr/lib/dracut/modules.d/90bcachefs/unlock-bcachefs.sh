#!/bin/sh

if [ "${fstype}" != bcachefs ]; then
    return 0
fi

dev="${root#block:}"

if bcachefs unlock -c "${dev}" >/dev/null 2>&1; then
    info "Unlocking ${dev}:"
    for _ in 1 2 3 4 5; do
        bcachefs unlock "${dev}" && return 0
    done

    die "Failed to unlock ${dev}"
else
    info "${dev} not encrypted"
fi
