#!/bin/bash
set -euo pipefail

# :static builds msvc/libusb_static.vcxproj -> libusb-1.0.lib
vcpkg install libusb:static

LIBUSB_ROOT="C:/vcpkg/packages/libusb_x64-windows/"

# Version guard: vcpkg's libusb must match the workflow VERSION exactly.
# (vcpkg resolves to the registry version, not a pinned one, so this fails the
# build if the registry serves a different libusb than $VERSION.)
VERSION="${VERSION}"
INSTALLED="$(grep -m1 '^Version:' "$LIBUSB_ROOT/lib/pkgconfig/libusb-1.0.pc" | awk '{print $2}')"
if [ "$INSTALLED" != "$VERSION" ]; then
    echo "ERROR: vcpkg libusb version is '$INSTALLED', expected '$VERSION'" >&2
    exit 1
fi

# LIBUSB_ROOT -> FindLibUsb.cmake uses <root>/lib and <root>/include as search hints
echo "LIBUSB_ROOT=$LIBUSB_ROOT" >> "$GITHUB_ENV"
# Static libusb on Windows needs the WinUSB system library linked in
echo "LIBUSB_LDFLAGS=setupapi.lib" >> "$GITHUB_ENV"
