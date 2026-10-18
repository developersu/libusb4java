#!/bin/bash
# Cross-compile libusb4java.so for 32-bit Raspberry Pi (armv7 /
# arm-linux-gnueabihf) and package it as the `linux-arm` classifier JAR.
#
# Why a dedicated build:
#   * Raspberry Pi OS (32-bit) is an armv7 system, so it cannot load
#     aarch64 binaries.
#   * The .so must be link-compatible with the Pi's glibc. The
#     debian:bookworm cross toolchain ships glibc 2.36, exactly what
#     Raspberry Pi OS (Debian 12 based) runs.
#
# Everything is cross-compiled inside a native amd64 debian:bookworm docker
# container using gcc-arm-linux-gnueabihf, so no qemu/binfmt emulation is
# required and the build works on any x86_64 machine (GitHub's ubuntu-latest
# runner included).
#
# Output: target/libusb4java-$VERSION-linux-arm.jar containing
#   org/usb4java/linux-arm/libusb4java.so
# which is picked up by ci/deploy.sh (JARs live in target/ by convention).
#
# Usage (locally and in CI):
#   bash ci/build_arm.sh
#
# Requirements: docker and jar (any JDK) on the host.
# VERSION defaults to the pom.xml version and can be overridden via env.
set -euo pipefail

cd "$(dirname "$0")/.."

# Defaults so the script also works outside CI (CI sets both variables).
GITHUB_WORKSPACE="${GITHUB_WORKSPACE:-$(pwd)}"
VERSION="${VERSION:-$(grep -m1 -oP '(?<=<version>).+(?=</version>)' pom.xml)}"
export VERSION

# shellcheck source=ci/libusb_build.sh
source ci/libusb_build.sh

EUD_VERSION=3.2.6
EUD_DIR="${WORKSPACE}/arm-deps"
PREFIX="${WORKSPACE}/arm-prefix"

# Download the eudev source (host side, like libusb_build.sh does for libusb).
# eudev 3.2.6 provides a static libudev.a for libusb' udev/hotplug support.
rm -rf "${EUD_DIR}"
mkdir -p "${EUD_DIR}"
curl -fsSL "https://dev.gentoo.org/~blueness/eudev/eudev-${EUD_VERSION}.tar.gz" \
    | tar xz --strip-components 1 -C "${EUD_DIR}"
test -f "${EUD_DIR}/configure" || { echo "ERROR: failed to download/extract eudev-${EUD_VERSION}" >&2; exit 1; }

rm -rf "${PREFIX}"

# Cross-compile eudev + libusb + libusb4java in one container invocation.
# The script is single-quoted so nothing is expanded on the host; all
# values are passed via -e.
docker run --rm \
    --network host \
    -v "${WORKSPACE}":/workspace \
    -w /workspace \
    -e LIBUSB_VERSION="${LIBUSB_VERSION}" \
    -e EUD_VERSION="${EUD_VERSION}" \
    -e HOST_UID="$(id -u)" \
    -e HOST_GID="$(id -g)" \
    debian:bookworm \
    /bin/bash -c '
        set -euo pipefail
        # The workspace is mounted at /workspace in the container; the install
        # prefix must live there (it maps to ${WORKSPACE}/arm-prefix on host).
        PREFIX=/workspace/arm-prefix
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -y
        apt-get install -y --no-install-recommends \
            build-essential autoconf automake libtool pkg-config \
            ca-certificates curl bzip2 gperf cmake \
            gcc-arm-linux-gnueabihf libc6-dev-armhf-cross default-jdk
        # libc6-dev-armhf-cross provides the cross libc startup objects
        # (Scrt1.o, crti.o) needed to *link* test binaries during configure;
        # autoconf then detects cross-compilation from the failed *execution*.

        # 1) eudev -> static libudev.a (keeps libusb hotplug support)
        cd /workspace/arm-deps
        ./configure \
            --build=x86_64-linux-gnu \
            --host=arm-linux-gnueabihf \
            --prefix="$PREFIX" \
            --libdir="$PREFIX/lib" \
            --with-rootlibdir="$PREFIX/lib" \
            --disable-shared --enable-static --with-pic \
            --enable-split-usr \
            --disable-manpages --disable-kmod --disable-selinux --disable-blkid
        make -j"$(nproc)"
        make install

        # 2) libusb -> static libusb-1.0.a. The C/CPP/LDFLAGS point its
        #    configure at the prefix so its libudev check passes and udev
        #    (hotplug) support stays enabled.
        cd "/workspace/libusb-build/libusb-${LIBUSB_VERSION}"
        CFLAGS="-I${PREFIX}/include" \
        CPPFLAGS="-I${PREFIX}/include" \
        LDFLAGS="-L${PREFIX}/lib" \
        ./configure \
            --build=x86_64-linux-gnu \
            --host=arm-linux-gnueabihf \
            --prefix="$PREFIX" \
            --libdir="$PREFIX/lib" \
            --disable-shared --enable-static --with-pic
        make -j"$(nproc)"
        make install

        # 3) libusb4java -> shared JNI .so, cross-linked against the
        #    static libraries above.
        mkdir -p /workspace/build-arm
        cd /workspace/build-arm
        cmake /workspace \
            -DCMAKE_SYSTEM_NAME=Linux \
            -DCMAKE_SYSTEM_PROCESSOR=arm \
            -DCMAKE_C_COMPILER=arm-linux-gnueabihf-gcc \
            -DCMAKE_BUILD_TYPE=Release \
            -DLibUsb_LIBRARIES="$PREFIX/lib/libusb-1.0.a;$PREFIX/lib/libudev.a" \
            -DLibUsb_INCLUDE_DIRS="$PREFIX/include/libusb-1.0" \
            -DLibUsb_LDFLAGS="-pthread -lrt"
        cmake --build . --config Release

        # The container runs as root; return ownership of the generated
        # artifacts to the host user so host-side steps (verification, JAR
        # packaging, re-running the script) keep working.
        chown -R "${HOST_UID}:${HOST_GID}" \
            /workspace/arm-deps /workspace/libusb-build \
            /workspace/arm-prefix /workspace/build-arm
    '

# Artifact verification
test -f "${PREFIX}/lib/libusb-1.0.a" || { echo "ERROR: static libusb-1.0.a not built" >&2; exit 1; }
test -f "${PREFIX}/lib/libudev.a" || { echo "ERROR: static libudev.a not built" >&2; exit 1; }
test -f "${PREFIX}/include/libusb-1.0/libusb.h" || { echo "ERROR: libusb-1.0/libusb.h not installed" >&2; exit 1; }
test -f "${WORKSPACE}/build-arm/out/libusb4java.so" || { echo "ERROR: libusb4java.so not built" >&2; exit 1; }

# Version guard: the built libusb must match VERSION exactly.
INSTALLED="$(grep -m1 '^Version:' "${PREFIX}/lib/pkgconfig/libusb-1.0.pc" | awk '{print $2}')"
if [ "${INSTALLED}" != "${LIBUSB_VERSION}" ]; then
    echo "ERROR: built libusb version is '${INSTALLED}', expected '${LIBUSB_VERSION}'" >&2
    exit 1
fi

# Package the JAR with the usb4java layout: org/usb4java/<classifier>/<lib>
command -v jar >/dev/null || { echo "ERROR: jar (a JDK) is required to package the JAR" >&2; exit 1; }
CLASSES="${WORKSPACE}/target/classes-arm"
rm -rf "${CLASSES}"
mkdir -p "${CLASSES}/org/usb4java/linux-arm"
cp "${WORKSPACE}/build-arm/out/libusb4java.so" "${CLASSES}/org/usb4java/linux-arm/"
mkdir -p "${WORKSPACE}/target"
jar cf "${WORKSPACE}/target/libusb4java-${VERSION}-linux-arm.jar" -C "${CLASSES}" org

echo "Built: ${WORKSPACE}/target/libusb4java-${VERSION}-linux-arm.jar"
