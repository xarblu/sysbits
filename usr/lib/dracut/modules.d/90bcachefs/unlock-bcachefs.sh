#!/bin/sh

if [ "${fstype}" != bcachefs ]; then
    return 0
fi

dev="${root#block:}"

command -v ask_for_password > /dev/null || . /lib/dracut-crypt-lib.sh

if bcachefs unlock -c "${dev}" >/dev/null 2>&1; then
    systemd-ask-password | bcachefs unlock "${dev}"
else
    info "${dev} not encrypted"
fi
