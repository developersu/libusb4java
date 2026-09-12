#!/bin/bash
# LIBUSB_VERSION=v1.0.30
# curl -L "https://github.com/libusb/libusb/archive/$LIBUSB_VERSION.zip" -o libusb.zip
# unzip -q libusb.zip
# cd libusb
vcpkg install libusb
ls 'C:\vcpkg\packages\libusb_x64-windows\include\'
ls 'C:\vcpkg\packages\libusb_x64-windows\*\*'
ls 'C:\vcpkg\packages\libusb_x64-windows\lib\'
echo "---"
ls 'C:\vcpkg\packages\libusb_x64-windows\lib\libusb-1.0.lib'
echo 'LibUsb_INCLUDE_DIR=C:\vcpkg\packages\libusb_x64-windows\'  >> $GITHUB_ENV
echo 'LibUsb_LIBRARIES=C:\vcpkg\packages\libusb_x64-windows\lib\libusb-1.0.lib'  >> $GITHUB_ENV
set LibUsb_INCLUDE_DIR='C:\vcpkg\packages\libusb_x64-windows\'
set LibUsb_LIBRARIES='C:\vcpkg\packages\libusb_x64-windows\lib\libusb-1.0.lib'
