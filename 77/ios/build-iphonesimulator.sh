#!/bin/bash

echo "==============================="
echo "===== Run build for iOS (simulator) ====="
echo "==============================="

source "ios.sh"

build "x86_64" "x86_64-apple-darwin" "iphonesimulator"

build "arm64" "aarch64-apple-darwin" "iphonesimulator"


