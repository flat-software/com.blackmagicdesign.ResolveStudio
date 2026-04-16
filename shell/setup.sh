#!/bin/bash

# Inspired by:
# https://github.com/pobthebuilder/resolve-flatpak
# https://www.danieltufvesson.com/makeresolvedeb

PREFIX='/app'
APP_ID="com.blackmagicdesign.ResolveStudio"

echo "Building ${APP_ID}"

./DaVinci_Resolve_*_Linux.run --appimage-extract > /dev/null 2>&1
rm ./DaVinci_Resolve_*_Linux.run
find squashfs-root -type f -exec chmod a+r,u+w {} \;
find squashfs-root -type d -exec chmod a+rx,u+w {} \;

# Use system libraries instead of the outdated ones provided.
# https://www.reddit.com/r/Fedora/comments/12z32r1/davinci_resolve_libpango_undefined_symbol_g/
rm squashfs-root/libs/libglib*
rm squashfs-root/libs/libgio*
rm squashfs-root/libs/libgmodule*
rm squashfs-root/libs/libgobject*
# Can we use system Qt5? Not yet.
# rm squashfs-root/libs/libQt5*

# Extract panel framework libraries into libs.
tar -xzvf squashfs-root/share/panels/dvpanel-framework-linux-x86_64.tgz -C squashfs-root/libs libDaVinciPanelAPI.so libFairlightPanelAPI.so

# scripts/ and share/ contain installer artifacts and the bulky panels tarball,
# so only copy the specific runtime files we need from them.
mkdir -p ${PREFIX}/scripts ${PREFIX}/share
mv squashfs-root/scripts/script.checkfirmware ${PREFIX}/scripts/
mv squashfs-root/scripts/script.getlogs.v4 ${PREFIX}/scripts/
mv squashfs-root/scripts/script.start ${PREFIX}/scripts/
mv squashfs-root/share/default-config.dat ${PREFIX}/share/
mv squashfs-root/share/default_cm_config.bin ${PREFIX}/share/
mv squashfs-root/share/log-conf.xml ${PREFIX}/share/
if [[ -e squashfs-root/share/remote-monitoring-log-conf.xml ]]; then
  mv squashfs-root/share/remote-monitoring-log-conf.xml ${PREFIX}/share/
fi
rm -rf squashfs-root/scripts squashfs-root/share

# Remove AppImage artifacts we don't need in the flatpak.
rm -rf squashfs-root/installer squashfs-root/AppRun squashfs-root/*.desktop squashfs-root/.DirIcon

# Move all remaining top-level directories to the prefix.
shopt -s dotglob
mv squashfs-root/* ${PREFIX}/
shopt -u dotglob

# Ensure directories that Resolve tries to create at runtime exist,
# since /app is read-only in flatpak.
mkdir -p "${PREFIX}/Apple Immersive/Calibration"
mkdir -p ${PREFIX}/Extras
mkdir -p ${PREFIX}/easyDCP
mkdir -p ${PREFIX}/Fairlight
mkdir -p ${PREFIX}/IOPlugins

# The BRAW SDK looks for its decoder backends (CUDA, OpenCL, AVX) in a
# BlackmagicRawAPI/ directory next to the resolve binary. Without them,
# opening .braw files fails with "codec DUMMY is not supported".
# Reuse the full set of decoders bundled with BlackmagicRAWPlayer.
ln -s ../libs/libBlackmagicRawAPI.so ${PREFIX}/bin/libBlackmagicRawAPI.so
ln -s ../BlackmagicRAWPlayer/BlackmagicRawAPI ${PREFIX}/bin/BlackmagicRawAPI
