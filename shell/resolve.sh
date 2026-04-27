export BMD_RESOLVE_CONFIG_DIR="${XDG_CONFIG_HOME}"
export BMD_RESOLVE_LICENSE_DIR="${XDG_DATA_HOME}/license"
export BMD_RESOLVE_LOGS_DIR="${XDG_DATA_HOME}/logs"
export QT_AUTO_SCREEN_SCALE_FACTOR=1

# Pre-create writable directories Resolve expects.
mkdir -p "${XDG_DATA_HOME}/logs/LogArchive"
mkdir -p "${XDG_DATA_HOME}/license"

# The flatpak NVIDIA GL extension provides versioned .so.1 symlinks but
# not the unversioned .so symlinks that Resolve needs to dlopen NVENC
# libraries for H.264/H.265 encoding in the Deliver page.
NVIDIA_SYMLINK_DIR="${XDG_CACHE_HOME}/nvidia-symlinks"
mkdir -p "${NVIDIA_SYMLINK_DIR}"
for lib in libnvidia-encode libnvcuvid libnvidia-opticalflow; do
  REAL_LIB=$(ldconfig -p | grep "${lib}.so.1 " | awk '{print $NF}')
  if [ -n "${REAL_LIB}" ]; then
    ln -sf "${REAL_LIB}" "${NVIDIA_SYMLINK_DIR}/${lib}.so"
  fi
done
export LD_LIBRARY_PATH="${NVIDIA_SYMLINK_DIR}:${LD_LIBRARY_PATH}"

# Bridge /app/Extras (build-time symlink to /var/tmp/resolve-extras) to a
# persistent per-user location so optional component downloads survive
# across launches.
mkdir -p "${XDG_DATA_HOME}/Extras"
ln -sfn "${XDG_DATA_HOME}/Extras" /var/tmp/resolve-extras

exec /app/bin/resolve "$@"
