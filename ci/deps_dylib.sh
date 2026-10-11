#!/bin/bash
# Build a self-contained static libusb from source for macOS (no brew libusb).
# macOS does not ship autoconf/automake/libtool, so install just the autotools
# chain via brew (build tooling only -- libusb itself is still built from source).
# libusb has no udev backend on macOS, so no --disable-udev is needed.
set -euo pipefail

# shellcheck source=ci/libusb_build.sh
source ci/libusb_build.sh

brew install autoconf automake libtool

cd "${LIBUSB_SRC}"
autoreconf -fi
./configure --prefix="${LIBUSB_PREFIX}" --disable-shared --enable-static
make -j"$(sysctl -n hw.ncpu)"
make install

test -f "${LIBUSB_PREFIX}/lib/libusb-1.0.a" || { echo "ERROR: static libusb-1.0.a not built" >&2; exit 1; }
test -f "${LIBUSB_PREFIX}/include/libusb-1.0/libusb.h" || { echo "ERROR: libusb-1.0/libusb.h not installed" >&2; exit 1; }

# Version guard: the built libusb must match the workflow VERSION exactly.
INSTALLED="$(grep -m1 '^Version:' "${LIBUSB_PREFIX}/lib/pkgconfig/libusb-1.0.pc" | awk '{print $2}')"
if [ "${INSTALLED}" != "${LIBUSB_VERSION}" ]; then
    echo "ERROR: built libusb version is '${INSTALLED}', expected '${LIBUSB_VERSION}'" >&2
    exit 1
fi

# LIBUSB_ROOT -> FindLibUsb.cmake uses <root>/lib and <root>/include as search hints
echo "LIBUSB_ROOT=${LIBUSB_PREFIX}" >> "$GITHUB_ENV"
# Static libusb on macOS needs these frameworks linked into libusb4java.dylib
echo "LIBUSB_LDFLAGS=-framework IOKit -framework CoreFoundation -framework Security" >> "$GITHUB_ENV"
