#!/bin/bash
# Build a self-contained static libusb from source for Windows (no vcpkg).
# Built with MSVC via the libusb msvc/ static project so it matches the MSVC
# toolchain used to build libusb4java.dll. Runs under Git Bash; the prefix is
# converted to a Windows path (cygpath -w) because CMake/MSVC needs one.
set -euo pipefail

# shellcheck source=ci/libusb_build.sh
source ci/libusb_build.sh

# Locate MSBuild via vswhere (present on the GH windows image).
MSBUILD="$(vswhere -latest -find 'MSBuild\**\Bin\MSBuild.exe' | head -n1)"
[ -n "${MSBUILD}" ] || { echo "ERROR: MSBuild not found via vswhere" >&2; exit 1; }

# Build the static lib (libusb_static.vcxproj -> libusb-1.0.lib).
# The .vcxproj lives inside the extracted libusb source tree, so pass its
# absolute Windows path (cygpath -w). MSYS2_ARG_CONV_EXCL stops Git Bash from
# mangling the backslash path and the /p:... arguments before they reach MSBuild.
VCPROJ_WIN="$(cygpath -w "${LIBUSB_SRC}/msvc/libusb_static.vcxproj")"
export MSYS2_ARG_CONV_EXCL="*"
"${MSBUILD}" "${VCPROJ_WIN}" /p:Configuration=Release /p:Platform=x64 /m /v:minimal

# msbuild emits the .lib under <src>/build/<toolset>/<platform>/<config>/lib/
LIB_ARTIFACT="$(find "${LIBUSB_SRC}/build" -name 'libusb-1.0.lib' 2>/dev/null | head -n1)"
[ -n "${LIB_ARTIFACT}" ] && [ -f "${LIB_ARTIFACT}" ] || { echo "ERROR: libusb-1.0.lib not found after msbuild" >&2; exit 1; }

# Stage into a conventional prefix: <prefix>/lib/libusb-1.0.lib and
# <prefix>/include/libusb-1.0/libusb.h (mirrors `make install` on Unix).
mkdir -p "${LIBUSB_PREFIX}/lib" "${LIBUSB_PREFIX}/include/libusb-1.0"
cp "${LIB_ARTIFACT}" "${LIBUSB_PREFIX}/lib/libusb-1.0.lib"
cp "${LIBUSB_SRC}/libusb/libusb.h" "${LIBUSB_SRC}/libusb/version.h" "${LIBUSB_SRC}/libusb/version_nano.h" "${LIBUSB_PREFIX}/include/libusb-1.0/"

test -f "${LIBUSB_PREFIX}/lib/libusb-1.0.lib" || { echo "ERROR: libusb-1.0.lib not staged" >&2; exit 1; }
test -f "${LIBUSB_PREFIX}/include/libusb-1.0/libusb.h" || { echo "ERROR: libusb-1.0/libusb.h not staged" >&2; exit 1; }

# Version guard: the built libusb must match the workflow VERSION exactly.
MAJOR="$(grep -m1 '^#define LIBUSB_MAJOR' "${LIBUSB_SRC}/libusb/version.h" | awk '{print $3}')"
MINOR="$(grep -m1 '^#define LIBUSB_MINOR' "${LIBUSB_SRC}/libusb/version.h" | awk '{print $3}')"
MICRO="$(grep -m1 '^#define LIBUSB_MICRO' "${LIBUSB_SRC}/libusb/version.h" | awk '{print $3}')"
INSTALLED="${MAJOR}.${MINOR}.${MICRO}"
if [ "${INSTALLED}" != "${LIBUSB_VERSION}" ]; then
    echo "ERROR: built libusb version is '${INSTALLED}', expected '${LIBUSB_VERSION}'" >&2
    exit 1
fi

# LIBUSB_ROOT (Windows path) -> FindLibUsb.cmake uses <root>\lib and <root>\include
LIBUSB_ROOT_WIN="$(cygpath -w "${LIBUSB_PREFIX}")"
echo "LIBUSB_ROOT=${LIBUSB_ROOT_WIN}" >> "$GITHUB_ENV"
# Static libusb on Windows needs the WinUSB system library linked in
echo "LIBUSB_LDFLAGS=setupapi.lib" >> "$GITHUB_ENV"
