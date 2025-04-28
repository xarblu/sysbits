# setup XCURSOR_* vars to defaults from KDE session
# keep values if they're already set
_kcminputrc="${XDG_CONFIG_HOME:-${HOME}/.config}/kcminputrc"
XCURSOR_THEME="${XCURSOR_THEME:-$(perl -ne 'if (/cursorTheme=(.+)/) { print $1 }' "${_kcminputrc}" 2>/dev/null)}"
XCURSOR_SIZE="${XCURSOR_SIZE:-$(perl -ne 'if (/cursorSize=(.+)/) { print $1 }' "${_kcminputrc}" 2>/dev/null)}"
XCURSOR_PATH="${XCURSOR_PATH:-/usr/share/icons}"
unset _kcminputrc
export XCURSOR_THEME XCURSOR_SIZE XCURSOR_PATH
