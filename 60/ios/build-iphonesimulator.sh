#!/bin/bash

echo "==============================="
echo "===== Run build for iOS (simulator) ====="
echo "==============================="

source "ios.sh"

build "i386" "i386" "i386-apple-darwin" "iphonesimulator"

build "x86_64" "x86_64" "x86_64-apple-darwin" "iphonesimulator"


