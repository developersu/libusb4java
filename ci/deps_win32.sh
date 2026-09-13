#!/bin/bash
# LIBUSB_VERSION=v1.0.30
# curl -L "https://github.com/libusb/libusb/archive/$LIBUSB_VERSION.zip" -o libusb.zip
# unzip -q libusb.zip
# cd libusb
vcpkg install libusb
echo 'LIBUSB_ROOT=C:/vcpkg/packages/libusb_x64-windows/' >> $GITHUB_ENV
echo 'NAME_POSTFIX=libusb4java.dll' >> $GITHUB_ENV
