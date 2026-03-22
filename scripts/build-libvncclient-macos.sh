#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_DIR="${LIBVNC_SOURCE_DIR:-$ROOT_DIR/Vendor/LibVNC/libvncserver}"
BUILD_ROOT="${LIBVNC_BUILD_ROOT:-$ROOT_DIR/Vendor/Build/libvncclient-macos}"
INSTALL_ROOT="${LIBVNC_INSTALL_ROOT:-$ROOT_DIR/Vendor/Build/libvncclient-install}"

if [[ ! -d "$SOURCE_DIR" ]]; then
  echo "LibVNC source tree not found: $SOURCE_DIR" >&2
  echo "Set LIBVNC_SOURCE_DIR or vendor LibVNC/libvncserver into Vendor/LibVNC/libvncserver" >&2
  exit 1
fi

build_arch() {
  local arch="$1"
  local build_dir="$BUILD_ROOT/$arch"
  local install_dir="$INSTALL_ROOT/$arch"

  cmake -S "$SOURCE_DIR" -B "$build_dir" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_OSX_ARCHITECTURES="$arch" \
    -DCMAKE_INSTALL_PREFIX="$install_dir" \
    -DBUILD_SHARED_LIBS=OFF \
    -DWITH_EXAMPLES=OFF \
    -DWITH_TESTS=OFF \
    -DWITH_WEBSOCKETS=OFF

  cmake --build "$build_dir" --config Release -j"$(sysctl -n hw.ncpu)"
  cmake --install "$build_dir"
}

build_arch arm64
build_arch x86_64

echo "Build complete."
echo "Static libraries and headers are under: $INSTALL_ROOT"
echo "Next step: package both installs into an xcframework or add them as vendored static libraries in Xcode."
