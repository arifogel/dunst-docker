#!/usr/bin/env bash

set -euo pipefail

set -x

DUNST_VERSION="$(grep "Release Notes" dunst/RELEASE_NOTES | head -n1 | awk '{print $4}' | cut -dv -f2)"
DUNST_DEB_VERSION="${DUNST_VERSION}-dev1"
DEB_FILE="dunst_${DUNST_DEB_VERSION}_amd64.deb"
docker build -t dunst-build .
SCRIPT_DIR="${PWD}"
COMMIT="$(git -C "${SCRIPT_DIR}" rev-parse --short HEAD)"
WORKDIR="$(mktemp -d)"
pushd "${WORKDIR}"
mkdir -p usr
pushd usr
docker run dunst-build cat /root/workdir/dunst.tar.gz | tar -xz
popd
strip usr/bin/dunst
strip usr/bin/dunstify
mkdir -p etc/xdg/dunst
mv usr/share/dunst/dunstrc etc/xdg/dunst/dunstrc
rmdir usr/share/dunst
mkdir -p usr/share/doc/dunst
gzip --best < etc/xdg/dunst/dunstrc > usr/share/doc/dunst/dunstrc.gz 
cp "${SCRIPT_DIR}/dunst_copyright" usr/share/doc/dunst/copyright
pushd usr/share/man/man1
gzip --best < dunst.1 > dunst.1.gz
rm dunst.1
gzip --best < dunstctl.1 > dunstctl.1.gz
rm dunstctl.1
popd

# changelog
pushd usr/share/doc/dunst
cat > changelog <<EOF
dunst (${DUNST_DEB_VERSION}) unstable; urgency=medium

  * Check repo for changes, using commit ${COMMIT}
    from https://github.com/dunst-project/dunst

 -- Ari Fogel <ari@fogelti.me>  $(date -R)

EOF
gunzip < "${SCRIPT_DIR}/changelog.Debian.gz" >> changelog
gzip --best < changelog >> changelog.Debian.gz
cat changelog
rm changelog
popd

cat > control <<EOF
Package: dunst
Version: ${DUNST_DEB_VERSION}
Architecture: amd64
Maintainer: Ubuntu Developers <ubuntu-devel-discuss@lists.ubuntu.com>
Original-Maintainer: Michael Stapelberg <stapelberg@debian.org>
Depends: libc6 (>= 2.4), libcairo2 (>= 1.2.4), libgdk-pixbuf2.0-0 (>= 2.22.0), libglib2.0-0 (>= 2.36), libpango-1.0-0 (>= 1.14.0), libpangocairo-1.0-0 (>= 1.22.0), libx11-6, libxdg-basedir1, libxinerama1, libxrandr2 (>= 2:1.5.0), libxss1
Provides: notification-daemon
Section: x11
Priority: optional
Homepage: https://dunst-project.org/
Description: dmenu-ish notification-daemon
 Dunst is a highly configurable and lightweight notification-daemon: The
 only thing it displays is a colored box with unformatted text. The whole
 notification specification (non-optional parts and the "body" capability) is
 supported as long as it fits into this look & feel.
 .
 Dunst is designed to fit nicely into minimalistic windowmanagers like dwm, but
 it should work on any Linux desktop.
EOF

echo 2.0 > debian-binary

echo /etc/xdg/dunst/dunstrc > conffiles

find usr -type f -exec md5sum {} \; | sort -k2 > md5sums

# permissions
find usr etc conffiles control md5sums -type f -exec chmod 0644 {} \;
find usr etc -type d -exec chmod 0755 {} \;
chmod 0755 \
  usr/bin/dunst \
  usr/bin/dunstctl \
  usr/bin/dunstify

tar --owner=root:0 --group=root:0 -cJf control.tar.xz \
  conffiles \
  control \
  md5sums

tar --owner=root:0 --group=root:0 -cJf data.tar.xz \
  etc \
  usr

ar q "${DEB_FILE}" \
  debian-binary \
  control.tar.xz \
  data.tar.xz

cp "${DEB_FILE}" "${SCRIPT_DIR}/"

popd

rm -rf "${WORKDIR}"
