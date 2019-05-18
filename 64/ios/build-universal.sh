#!/bin/bash

source "$PWD/../prefix.sh"

echo "==============================="
echo "===== Run build for iOS (universal) ====="
echo "==============================="

sh build-iphoneos.sh

sh build-iphonesimulator.sh

sh run-lipo.sh

exit
rm -rf "${PWD}/build-x86_64"
rm -rf "${PWD}/build-i386"
rm -rf "${PWD}/build-armv7s"
rm -rf "${PWD}/build-armv7"
rm -rf "${PWD}/build-arm64"

