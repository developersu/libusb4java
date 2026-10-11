#!/bin/bash
set -euo pipefail

brew install libusb pkgconf

PREFIX="$(brew --prefix)"
if [ ! -f "$PREFIX/lib/libusb-1.0.a" ]; then
    echo "ERROR: static libusb-1.0.a not found under $PREFIX/lib (brew may not provide a static lib; fall back to building libusb from source)" >&2
    exit 1
fi

# Version guard: brew's libusb must match the workflow VERSION exactly.
# (brew cannot pin a version, so this fails the build if Homebrew serves a
# different libusb than $VERSION.)
VERSION="${VERSION}"
INSTALLED="$(grep -m1 '^Version:' "$PREFIX/lib/pkgconfig/libusb-1.0.pc" | awk '{print $2}')"
if [ "$INSTALLED" != "$VERSION" ]; then
    echo "ERROR: brew libusb version is '$INSTALLED', expected '$VERSION'" >&2
    exit 1
fi

# LIBUSB_ROOT -> FindLibUsb.cmake uses <root>/lib and <root>/include as search hints
echo "LIBUSB_ROOT=$PREFIX" >> "$GITHUB_ENV"
# Static libusb on macOS needs these frameworks linked into libusb4java.dylib
echo "LIBUSB_LDFLAGS=-framework IOKit -framework CoreFoundation -framework Security" >> "$GITHUB_ENV"
