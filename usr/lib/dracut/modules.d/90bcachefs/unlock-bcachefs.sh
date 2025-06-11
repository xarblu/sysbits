#!/bin/sh

if [ "${fstype}" != bcachefs ]; then
    return 0
fi

dev="${root#block:}"

command -v ask_for_password > /dev/null || . /lib/dracut-crypt-lib.sh

if bcachefs unlock -c "${dev}" >/dev/null 2>&1; then
    ask_for_password \
        --cmd "bcachefs unlock \"${dev}\" <<<\"\$(read -r p; echo \"\${p}\")\"" \
        --prompt "Password (${dev})" \
        --tty-echo-off
else
    info "${dev} not encrypted"
fi
