#!/bin/sh

if [ "${fstype}" != bcachefs ]; then
    return 0
fi

dev="${root#block:}"

command -v ask_for_password > /dev/null || . /lib/dracut-crypt-lib.sh

if bcachefs unlock -c "${dev}" >/dev/null 2>&1; then
    ask_for_password \
        --cmd "read -rs p && echo \"\$p\" | bcachefs unlock \"${dev}\"" \
        --prompt "Password (${dev})" \
        --tty-echo-off
else
    info "${dev} not encrypted"
fi
