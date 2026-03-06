#!/bin/sh
#
# Build OpenWrt .ipk package for prometheus-node-exporter-lua-wireguard
# without using the OpenWrt SDK. Uses same format as OpenWrt ipkg-build
# (gzipped tarball of debian-binary + data.tar.gz + control.tar.gz).
# Requires: tar (GNU), gzip.
#
# Usage: ./build-ipk.sh [version]
#   version defaults to 1.0.0
# Output: prometheus-node-exporter-lua-wireguard_<version>_all.ipk
#

set -e

PKG_NAME="prometheus-node-exporter-lua-wireguard"
VERSION="${1:-1.0.0}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$(mktemp -d)"
trap 'rm -rf "$BUILD_DIR"' EXIT

# Package layout
DATA_DIR="${BUILD_DIR}/data"
CONTROL_DIR="${BUILD_DIR}/control"
DEST_DIR="${DATA_DIR}/usr/lib/lua/prometheus-collectors"

mkdir -p "$DEST_DIR"
mkdir -p "$CONTROL_DIR"

# Copy collector (single source of truth at repo root)
cp "${SCRIPT_DIR}/wireguard.lua" "${DEST_DIR}/wireguard.lua"

# Control file
cat > "${CONTROL_DIR}/control" << EOF
Package: ${PKG_NAME}
Version: ${VERSION}
Depends: prometheus-node-exporter-lua
Architecture: all
Maintainer: Prometheus Node Exporter Lua WG contributors
License: Apache-2.0
Section: utils
Description: WireGuard/Amnezia WG collector for prometheus-node-exporter-lua.
 Exports wg_latest_handshake_seconds from wg and amneziawg CLIs.
EOF

# Debian package format: 2.0
echo "2.0" > "${BUILD_DIR}/debian-binary"

# Data and control tarballs (GNU tar format, same as OpenWrt ipkg-build)
( cd "$DATA_DIR" && tar --format=gnu --numeric-owner --owner=0 --group=0 -czf "${BUILD_DIR}/data.tar.gz" . )
( cd "$CONTROL_DIR" && tar --format=gnu --numeric-owner --owner=0 --group=0 -czf "${BUILD_DIR}/control.tar.gz" . )

# Assemble .ipk: OpenWrt ipkg-build uses gzip(tar(...)), not ar (see scripts/ipkg-build)
# Order: debian-binary, data.tar.gz, control.tar.gz
IPK_NAME="${PKG_NAME}_${VERSION}_all.ipk"
( cd "$BUILD_DIR" && tar --format=gnu --numeric-owner -cf - ./debian-binary ./data.tar.gz ./control.tar.gz | gzip -n - > "${SCRIPT_DIR}/${IPK_NAME}" )

echo "Built: ${IPK_NAME}"
