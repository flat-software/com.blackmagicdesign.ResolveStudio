#!/bin/bash

# Inspired by:
# https://github.com/pobthebuilder/resolve-flatpak
# https://www.danieltufvesson.com/makeresolvedeb

PREFIX='/app'
APP_ID="com.blackmagicdesign.ResolveStudio"

echo "Building ${APP_ID}"

./DaVinci_Resolve_*_Linux.run --appimage-extract 2>&1
rm ./DaVinci_Resolve_*_Linux.run
find squashfs-root -type f -exec chmod a+r,u+w {} \;
find squashfs-root -type d -exec chmod a+rx,u+w {} \;

# Create directories.
mkdir -p ${PREFIX} ${PREFIX}/easyDCP ${PREFIX}/scripts ${PREFIX}/share ${PREFIX}/Fairlight
chmod 755 ${PREFIX}/easyDCP ${PREFIX}/scripts ${PREFIX}/share ${PREFIX}/Fairlight

# Copy objects.
cp -rp squashfs-root/bin ${PREFIX}/
cp -rp squashfs-root/Control ${PREFIX}/
cp -rp squashfs-root/Certificates ${PREFIX}/
cp -rp squashfs-root/DaVinci\ Control\ Panels\ Setup ${PREFIX}/
cp -rp squashfs-root/Developer ${PREFIX}/
cp -rp squashfs-root/docs ${PREFIX}/
cp -rp squashfs-root/Fairlight\ Studio\ Utility ${PREFIX}/
cp -rp squashfs-root/Fusion ${PREFIX}/
cp -rp squashfs-root/graphics ${PREFIX}/

# Use system libraries instead of the outdated ones provided.
# https://www.reddit.com/r/Fedora/comments/12z32r1/davinci_resolve_libpango_undefined_symbol_g/
rm squashfs-root/libs/libglib*
rm squashfs-root/libs/libgio*
rm squashfs-root/libs/libgmodule*
rm squashfs-root/libs/libgobject*
# Can we use system Qt5? Not yet.
# rm squashfs-root/libs/libQt5*

cp -rp squashfs-root/libs ${PREFIX}/

cp -rp squashfs-root/LUT ${PREFIX}/
cp -rp squashfs-root/Onboarding ${PREFIX}/
cp -rp squashfs-root/plugins ${PREFIX}/
cp -rp squashfs-root/Technical\ Documentation ${PREFIX}/
cp -rp squashfs-root/UI_Resource ${PREFIX}/
cp -rp squashfs-root/scripts/script.checkfirmware ${PREFIX}/scripts/
cp -rp squashfs-root/scripts/script.getlogs.v4 ${PREFIX}/scripts/
cp -rp squashfs-root/scripts/script.start ${PREFIX}/scripts/
cp -rp squashfs-root/share/default-config.dat ${PREFIX}/share/
cp -rp squashfs-root/share/default_cm_config.bin ${PREFIX}/share/
cp -rp squashfs-root/share/log-conf.xml ${PREFIX}/share/
if [[ -e squashfs-root/share/remote-monitoring-log-conf.xml ]]; then
    cp -rp squashfs-root/share/remote-monitoring-log-conf.xml ${PREFIX}/share/
fi

tar -xzvf squashfs-root/share/panels/dvpanel-framework-linux-x86_64.tgz -C ${PREFIX}/libs libDaVinciPanelAPI.so libFairlightPanelAPI.so

# Quiet some errors.
mkdir -p ${PREFIX}/bin/BlackmagicRawAPI/
ln -s ../libs/libBlackmagicRawAPI.so ${PREFIX}/bin/libBlackmagicRawAPI.so
ln -s ../../libs/libBlackmagicRawAPI.so ${PREFIX}/bin/BlackmagicRawAPI/libBlackmagicRawAPI.so
