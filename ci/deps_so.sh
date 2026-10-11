#!/bin/bash
# Build a self-contained static libusb from source for Linux.
# apt has no static libusb-1.0.a, so we build one. --disable-udev keeps the .a
# free of a libudev dependency so libusb4java.so stays fully self-contained.
set -euo pipefail

# shellcheck source=ci/libusb_build.sh
source ci/libusb_build.sh

sudo apt update -y
sudo apt install -y build-essential autoconf automake libtool pkg-config

cd "${LIBUSB_SRC}"
autoreconf -fi
# -fPIC is required: libusb4java.so is a shared object and pulls libusb's
# objects out of the static .a, so they must be position-independent.
CFLAGS="-fPIC" ./configure --prefix="${LIBUSB_PREFIX}" --disable-shared --enable-static --disable-udev
make -j"$(nproc)"
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
# Static libusb on Linux needs pthread/rt linked into libusb4java.so
echo "LIBUSB_LDFLAGS=-lpthread -lrt" >> "$GITHUB_ENV"
