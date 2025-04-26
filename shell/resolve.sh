export BMD_RESOLVE_CONFIG_DIR="${XDG_CONFIG_HOME}"
export BMD_RESOLVE_LICENSE_DIR="${XDG_DATA_HOME}/license"
export BMD_RESOLVE_LOGS_DIR="${XDG_DATA_HOME}/logs"
exec /app/resolve/resolve $@
