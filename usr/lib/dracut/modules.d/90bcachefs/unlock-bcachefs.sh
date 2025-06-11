#!/bin/sh

if [ "${fstype}" != bcachefs ]; then
    return 0
fi

dev="${root#block:}"

if bcachefs unlock -c "${dev}" >/dev/null 2>&1; then
    info "Unlocking ${dev}:"
    while true; do
        bcachefs unlock "${dev}" && break
    done
else
    info "${dev} not encrypted"
fi
