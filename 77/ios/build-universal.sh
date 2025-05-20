#!/bin/bash

source "$PWD/../prefix.sh"

echo "==============================="
echo "===== Run build for iOS (universal) ====="
echo "==============================="

bash build-iphoneos.sh

bash build-iphonesimulator.sh

bash run-lipo.sh


