#!/bin/bash
# Download + extract libusb $VERSION source into the workspace
# Sourced by the per-platform deps_*.sh scripts. After sourcing, these are set:
#   LIBUSB_VERSION    libusb version to build (single source of truth: workflow VERSION)
#   LIBUSB_BUILD_DIR  workspace dir that holds the source tree
#   LIBUSB_PREFIX     install prefix the platform build script must install into
#   LIBUSB_SRC        extracted source root  ($LIBUSB_BUILD_DIR/libusb-$LIBUSB_VERSION)
set -euo pipefail

# VERSION is the single source of truth, set in .github/workflows/ci.yml.
LIBUSB_VERSION="${VERSION:?ERROR: VERSION is not set; define it in .github/workflows/ci.yml}"

# On Windows (Git Bash) GITHUB_WORKSPACE is a Windows path (D:\a\...); the bash
# tools in this script need a POSIX path, so convert it. On Linux/macOS it is
# already POSIX and cygpath is absent, so leave it untouched.
WORKSPACE="${GITHUB_WORKSPACE}"
if [ -n "${MSYSTEM:-}" ]; then
    WORKSPACE="$(cygpath -u "${GITHUB_WORKSPACE}")"
fi
LIBUSB_BUILD_DIR="${WORKSPACE}/libusb-build"
LIBUSB_PREFIX="${LIBUSB_BUILD_DIR}/prefix"
LIBUSB_SRC="${LIBUSB_BUILD_DIR}/libusb-${LIBUSB_VERSION}"

rm -rf "${LIBUSB_BUILD_DIR}"
mkdir -p "${LIBUSB_BUILD_DIR}"
curl -fsSL "https://github.com/libusb/libusb/releases/download/v${LIBUSB_VERSION}/libusb-${LIBUSB_VERSION}.tar.bz2" \
    | tar xj -C "${LIBUSB_BUILD_DIR}"

test -d "${LIBUSB_SRC}" || { echo "ERROR: failed to download/extract libusb-${LIBUSB_VERSION}" >&2; exit 1; }
