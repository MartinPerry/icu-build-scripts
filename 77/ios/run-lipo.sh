#!/bin/bash

source "$PWD/../prefix.sh"

mkdir -p "${IOS_INSTALL_DIR}/include/"
mkdir -p "${IOS_INSTALL_DIR}/include/unicode"

cp ${ICU_SOURCE}/common/unicode/*.h "${IOS_INSTALL_DIR}/include/unicode"

echo "======================================================================="
echo "===== Combining platform libraries ====="
echo "======================================================================="

function runLipo {
    MODULE_NAME=$1

    lipo \
        "${BUILD_DIR}/install-arm64-iphoneos/lib/${MODULE_NAME}arm64.a" \
        "${BUILD_DIR}/install-arm64e-iphoneos/lib/${MODULE_NAME}arm64e.a" \
        -create -output "${IOS_INSTALL_DIR}/lib/${MODULE_NAME}_iOS.a"

    lipo \
        "${BUILD_DIR}/install-x86_64-iphonesimulator/lib/${MODULE_NAME}x86_64.a" \
        "${BUILD_DIR}/install-arm64-iphonesimulator/lib/${MODULE_NAME}arm64.a" \
        -create -output "${IOS_INSTALL_DIR}/lib/${MODULE_NAME}_iOS_simulator.a"
}

mkdir -p "${IOS_INSTALL_DIR}/lib/"

runLipo "libicui18n"
runLipo "libicuio"
#runLipo "libicule"
#runLipo "libiculx"
runLipo "libicutu"
runLipo "libicuuc"
runLipo "libicudata"

