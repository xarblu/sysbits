#!/bin/sh

if [ "${fstype}" != bcachefs ]; then
    return 0
fi

dev="${root#block:}"

if bcachefs unlock -c "${dev}" >/dev/null 2>&1; then
    command -v ask_for_password > /dev/null || . /lib/dracut-crypt-lib.sh
    ask_for_password \
        --cmd "bcachefs unlock ${dev}" \
        --prompt "Password (${dev})" \
        --tty-echo-off
else
    info "${dev} not encrypted"
fi
