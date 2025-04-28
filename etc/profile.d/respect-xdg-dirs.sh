# Make more things use the XDG defined dirs
# https://github.com/b3nj5m1n/xdg-ninja

### Define XDG dirs ###
export XDG_DATA_HOME="${HOME}/.local/share"
export XDG_CONFIG_HOME="${HOME}/.config"
export XDG_STATE_HOME="${HOME}/.local/state"
export XDG_CACHE_HOME="${HOME}/.cache"

### Move things to XDG dirs ###
# To XDG_DATA_HOME
export LESSHISTFILE="${XDG_DATA_HOME}/less-history"
export CARGO_HOME="${XDG_DATA_HOME}/cargo"
export GNUPGHOME="${XDG_DATA_HOME}/gnupg"
export DVDCSS_CACHE="${XDG_DATA_HOME}/dvdcss"
export WINEPREFIX="${XDG_DATA_HOME}/wineprefixes/default"
export GOPATH="${XDG_DATA_HOME}/go"

# To XDG_CONFIG_HOME
export ZDOTDIR="${XDG_CONFIG_HOME}/zsh"
export GTK2_RC_FILES="${XDG_CONFIG_HOME}/gtk-2.0/gtkrc"
export KDEHOME="${XDG_CONFIG_HOME}/kde"
export NPM_CONFIG_USERCONFIG="${XDG_CONFIG_HOME}/npm/npmrc"
#export _JAVA_OPTIONS="-Djava.util.prefs.userRoot=${XDG_CONFIG_HOME}/java"
export FFMPEG_DATADIR="${XDG_CONFIG_HOME}/ffmpeg"
export ANDROID_USER_HOME="${XDG_CONFIG_HOME}/android"
export ANDROID_HOME="${XDG_DATA_HOME}/android"
export PYTHONSTARTUP="${XDG_CONFIG_HOME}/python/pythonrc" #requires pythonrc file but should only apply to interactive console anyway
export RIPGREP_CONFIG_PATH="${XDG_CONFIG_HOME}/ripgreprc"
export DOCKER_CONFIG="${XDG_CONFIG_HOME}/docker"
export PARALLEL_HOME="${XDG_CONFIG_HOME}/parallel"
export W3M_DIR="${XDG_DATA_HOME}/w3m"

# To XDG_CACHE_HOME
export ERRFILE="${XDG_CACHE_HOME}/X11/xsession-errors"

# To XDG_RUNTIME_DIR
#export XAUTHORITY="$XDG_RUNTIME_DIR"/Xauthority #breaks xwayland

### Move things with aliases ###
alias wget="wget --hsts-file=\${XDG_DATA_HOME}/wget-hsts"
