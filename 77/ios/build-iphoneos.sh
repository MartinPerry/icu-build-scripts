#!/bin/bash

echo "==============================="
echo "===== Run build for iOS (phone) ====="
echo "==============================="

source "ios.sh"


build "arm64" "aarch64-apple-darwin" "iphoneos"

build "arm64e" "aarch64-apple-darwin" "iphoneos"
