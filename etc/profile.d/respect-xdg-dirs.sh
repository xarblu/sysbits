# Make more things use the XDG defined dirs
# https://github.com/b3nj5m1n/xdg-ninja

### Define XDG dirs ###
export XDG_CACHE_HOME="${HOME}/.cache"
export XDG_CONFIG_HOME="${HOME}/.config"
export XDG_DATA_HOME="${HOME}/.local/share"
export XDG_STATE_HOME="${HOME}/.local/state"

### Move things to XDG dirs ###
# To XDG_DATA_HOME
export CARGO_HOME="${XDG_DATA_HOME}/cargo"
export DOTNET_CLI_HOME="${XDG_DATA_HOME}/dotnet"
export DVDCSS_CACHE="${XDG_DATA_HOME}/dvdcss"
export GNUPGHOME="${XDG_DATA_HOME}/gnupg"
export GOPATH="${XDG_DATA_HOME}/go"
export LESSHISTFILE="${XDG_DATA_HOME}/less-history"
export MYSQL_HISTFILE="${XDG_DATA_HOME}/mysql_history"
export ROSWELL_HOME="${XDG_DATA_HOME}/roswell"
export WINEPREFIX="${XDG_DATA_HOME}/wineprefixes/default"

# To XDG_CONFIG_HOME
#export _JAVA_OPTIONS="-Djava.util.prefs.userRoot=${XDG_CONFIG_HOME}/java"
export ANDROID_HOME="${XDG_DATA_HOME}/android"
export ANDROID_USER_HOME="${XDG_CONFIG_HOME}/android"
export DOCKER_CONFIG="${XDG_CONFIG_HOME}/docker"
export FFMPEG_DATADIR="${XDG_CONFIG_HOME}/ffmpeg"
export GTK2_RC_FILES="${XDG_CONFIG_HOME}/gtk-2.0/gtkrc"
export KDEHOME="${XDG_CONFIG_HOME}/kde"
export NPM_CONFIG_USERCONFIG="${XDG_CONFIG_HOME}/npm/npmrc"
export PARALLEL_HOME="${XDG_CONFIG_HOME}/parallel"
export PYTHONSTARTUP="${XDG_CONFIG_HOME}/python/pythonrc" #requires pythonrc file but should only apply to interactive console anyway
export RIPGREP_CONFIG_PATH="${XDG_CONFIG_HOME}/ripgreprc"
export W3M_DIR="${XDG_DATA_HOME}/w3m"
export ZDOTDIR="${XDG_CONFIG_HOME}/zsh"

# To XDG_CACHE_HOME
export ERRFILE="${XDG_CACHE_HOME}/X11/xsession-errors"
export SQLITE_HISTORY="${XDG_CACHE_HOME}/sqlite_history"
export TEXMFVAR="${XDG_CACHE_HOME}/texlive/texmf-var"

# To XDG_STATE_HOME
export NODE_REPL_HISTORY="${XDG_STATE_HOME}/node_repl_history"

# To XDG_RUNTIME_DIR
#export XAUTHORITY="$XDG_RUNTIME_DIR"/Xauthority #breaks xwayland

### Move things with aliases ###
alias adb='HOME="$XDG_DATA_HOME"/android adb'
alias wget='wget --hsts-file=${XDG_DATA_HOME}/wget-hsts'
