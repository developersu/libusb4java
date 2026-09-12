#!/bin/bash
# LIBUSB_VERSION=v1.0.30
# curl -L "https://github.com/libusb/libusb/archive/$LIBUSB_VERSION.zip" -o libusb.zip
# unzip -q libusb.zip
# cd libusb
vcpkg install libusb
echo "--- bin"
ls 'C:\vcpkg\packages\libusb_x64-windows\bin\'
echo "--- include"
ls 'C:\vcpkg\packages\libusb_x64-windows\include\'
echo "--- include libusb-1.0"
ls 'C:\vcpkg\packages\libusb_x64-windows\include\libusb-1.0'
echo "--- lib"
ls 'C:\vcpkg\packages\libusb_x64-windows\lib\'

echo 'LibUsb_INCLUDE_HINTS=C:\vcpkg\packages\libusb_x64-windows\include' >> $GITHUB_ENV
echo 'LibUsb_LIBRARY_HINTS=C:\vcpkg\packages\libusb_x64-windows\bin' >> $GITHUB_ENV
