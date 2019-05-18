#!/bin/bash

echo "==============================="
echo "===== Run build for iOS (phone) ====="
echo "==============================="

source "ios.sh"

build "armv7s" "armv7s" "armv7s-apple-darwin" "iphoneos"

build "armv7" "armv7" "armv7-apple-darwin" "iphoneos"

build "arm64" "arm64" "aarch64-apple-darwin" "iphoneos"



