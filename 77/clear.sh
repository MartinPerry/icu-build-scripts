#!/bin/bash

source "./prefix.sh"

rm -rf "${BUILD_DIR}"

rm -rf "${BASE_ICU_DIR}/mac/${MAC_INSTALL_DIR}"
rm -rf "${BASE_ICU_DIR}/ios/${IOS_INSTALL_DIR}"
rm -rf "${BASE_ICU_DIR}/android/${ANDROID_INSTALL_DIR}"


