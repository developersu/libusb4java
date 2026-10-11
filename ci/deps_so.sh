#!/bin/bash
set -euo pipefail

# apt ships no static libusb-1.0.a, so build one from source.
# --disable-udev keeps the .a free of a libudev dependency -> fully self-contained.
sudo apt update -y
sudo apt install -y build-essential autoconf automake libtool pkg-config

LIBUSB_VERSION="${VERSION}"
PREFIX=/usr/local

curl -L https://github.com/libusb/libusb/releases/download/v${LIBUSB_VERSION}/libusb-${LIBUSB_VERSION}.tar.bz2 | tar xj
cd "libusb-${LIBUSB_VERSION}"
autoreconf -fi
./configure --prefix="$PREFIX" --disable-shared --enable-static --disable-udev
make -j"$(nproc)"
make install

test -f "$PREFIX/lib/libusb-1.0.a" || { echo "ERROR: static libusb-1.0.a not built" >&2; exit 1; }

# Version guard: the built libusb must match the workflow VERSION exactly.
INSTALLED="$(grep -m1 '^Version:' "$PREFIX/lib/pkgconfig/libusb-1.0.pc" | awk '{print $2}')"
if [ "$INSTALLED" != "$LIBUSB_VERSION" ]; then
    echo "ERROR: built libusb version is '$INSTALLED', expected '$LIBUSB_VERSION'" >&2
    exit 1
fi

# LIBUSB_ROOT -> FindLibUsb.cmake uses <root>/lib and <root>/include as search hints
echo "LIBUSB_ROOT=$PREFIX" >> "$GITHUB_ENV"
# Static libusb on Linux needs pthread/rt linked into libusb4java.so
echo "LIBUSB_LDFLAGS=-lpthread -lrt" >> "$GITHUB_ENV"
