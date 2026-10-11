#!/bin/bash
vcpkg install libusb
echo 'LIBUSB_ROOT=C:/vcpkg/packages/libusb_x64-windows/' >> $GITHUB_ENV
