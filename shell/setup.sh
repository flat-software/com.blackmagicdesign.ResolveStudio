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

# Create directories.
mkdir -p ${PREFIX} ${PREFIX}/easyDCP ${PREFIX}/scripts ${PREFIX}/share ${PREFIX}/Fairlight
chmod 755 ${PREFIX}/easyDCP ${PREFIX}/scripts ${PREFIX}/share ${PREFIX}/Fairlight

# Copy objects.
mv squashfs-root/bin ${PREFIX}/
mv squashfs-root/Control ${PREFIX}/
mv squashfs-root/Certificates ${PREFIX}/
mv squashfs-root/DaVinci\ Control\ Panels\ Setup ${PREFIX}/
mv squashfs-root/Developer ${PREFIX}/
mv squashfs-root/docs ${PREFIX}/
mv squashfs-root/Fairlight\ Studio\ Utility ${PREFIX}/
mv squashfs-root/Fusion ${PREFIX}/
mv squashfs-root/graphics ${PREFIX}/

# Use system libraries instead of the outdated ones provided.
# https://www.reddit.com/r/Fedora/comments/12z32r1/davinci_resolve_libpango_undefined_symbol_g/
rm squashfs-root/libs/libglib*
rm squashfs-root/libs/libgio*
rm squashfs-root/libs/libgmodule*
rm squashfs-root/libs/libgobject*
# Can we use system Qt5? Not yet.
# rm squashfs-root/libs/libQt5*

mv squashfs-root/libs ${PREFIX}/

mv squashfs-root/LUT ${PREFIX}/
mv squashfs-root/Onboarding ${PREFIX}/
mv squashfs-root/plugins ${PREFIX}/
mv squashfs-root/Technical\ Documentation ${PREFIX}/
mv squashfs-root/UI_Resource ${PREFIX}/
mv squashfs-root/scripts/script.checkfirmware ${PREFIX}/scripts/
mv squashfs-root/scripts/script.getlogs.v4 ${PREFIX}/scripts/
mv squashfs-root/scripts/script.start ${PREFIX}/scripts/
mv squashfs-root/share/default-config.dat ${PREFIX}/share/
mv squashfs-root/share/default_cm_config.bin ${PREFIX}/share/
mv squashfs-root/share/log-conf.xml ${PREFIX}/share/
if [[ -e squashfs-root/share/remote-monitoring-log-conf.xml ]]; then
  mv squashfs-root/share/remote-monitoring-log-conf.xml ${PREFIX}/share/
fi

tar -xzvf squashfs-root/share/panels/dvpanel-framework-linux-x86_64.tgz -C ${PREFIX}/libs libDaVinciPanelAPI.so libFairlightPanelAPI.so

# Quiet some errors.
mkdir -p ${PREFIX}/bin/BlackmagicRawAPI/
ln -s ../libs/libBlackmagicRawAPI.so ${PREFIX}/bin/libBlackmagicRawAPI.so
ln -s ../../libs/libBlackmagicRawAPI.so ${PREFIX}/bin/BlackmagicRawAPI/libBlackmagicRawAPI.so
