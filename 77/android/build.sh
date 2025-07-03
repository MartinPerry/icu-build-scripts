#!/bin/bash

source "../prefix.sh"

#==============================================================================
initToolchain() {

    local TARGET=$1

    export isValid=1

    export TOOLCHAIN="${ANDROID_NDK_HOME}/toolchains/llvm/prebuilt/darwin-x86_64"

    export NDK_CLANG="${TOOLCHAIN}/bin/${TARGET}${ANDROID_API_VERSION}-clang++"
    if [[ ! -f "${NDK_CLANG}" ]]; then
        echo "Target ${TARGET} not exist for API ${ANDROID_API_VERSION}: ${NDK_CLANG}"
        isValid=0
        return
    fi

    export PATH="${TOOLCHAIN}/bin":${PATH}

    export AR="${TOOLCHAIN}/bin/llvm-ar"
    export CC="${TOOLCHAIN}/bin/${TARGET}${ANDROID_API_VERSION}-clang"
    export AS="$CC"
    export CXX="${TOOLCHAIN}/bin/${TARGET}${ANDROID_API_VERSION}-clang++"
    export LD="${TOOLCHAIN}/bin/ld"
    export RANLIB="${TOOLCHAIN}/bin/llvm-ranlib"
    export STRIP="${TOOLCHAIN}/bin/llvm-strip"
        
}

#==============================================================================

initCompilerFlags() {
  local ARCH=$1
  
  local optim="-O2"
  local cppv="-std=c++17"
  
  #local globalCFLAGS="-ffunction-sections -fdata-sections -fno-exceptions -fno-short-wchar -fno-short-enums"
  local globalCFLAGS="-fno-exceptions -fno-short-wchar -fno-short-enums"
  
  #local globalLDFLAGS="-Wl,--gc-sections ${optim} -ffunction-sections -fdata-sections"
  local globalLDFLAGS="${optim}"
  
  case "${ARCH}" in
  "armv7a")
    export CFLAGS="-march=armv7-a -mfpu=vfpv3-d16 -mfloat-abi=softfp -Wno-unused-function -fstrict-aliasing -fPIC -DANDROID -D__ANDROID_API__=${ANDROID_API_VERSION} ${optim} ${globalCFLAGS}"
    export LDFLAGS="-march=armv7-a -mfpu=vfpv3-d16 -mfloat-abi=softfp -Wl,--fix-cortex-a8 ${globalLDFLAGS}"
    ;;
  "aarch64")
    export CFLAGS="-march=armv8-a -Wno-unused-function -fstrict-aliasing -fPIC -DANDROID -D__ANDROID_API__=${ANDROID_API_VERSION} ${optim} ${globalCFLAGS}"
    export LDFLAGS="-march=armv8-a ${globalLDFLAGS}"
    ;;
  "i686")
    export CFLAGS="-march=i686 -Wno-unused-function -fstrict-aliasing -fPIC -DANDROID -D__ANDROID_API__=${ANDROID_API_VERSION} ${optim} ${globalCFLAGS}"
    export LDFLAGS="-march=i686 ${globalLDFLAGS}"
    ;;
  "x86_64")
    export CFLAGS="-march=x86-64 -msse4.2 -mpopcnt -Wno-unused-function -fstrict-aliasing -fPIC -DANDROID -D__ANDROID_API__=${ANDROID_API_VERSION} ${optim} ${globalCFLAGS}"
    export LDFLAGS="-march=x86-64 ${globalLDFLAGS}"
    ;;
  esac
  
  export CXXFLAGS="${cppv} ${optim} ${globalCFLAGS}"
  export CPPFLAGS=${CFLAGS}
}

#==============================================================================

function build() {
# $1: Android Arch Name

#ARCH = aarch64, armv7a, i686, x86_64
export ARCH=$1
export HOST=$2

export TARGET="${ARCH}-linux-android"
if [[ ${ARCH} == "armv7a" ]]; then
    TARGET="${TARGET}eabi"
fi

echo "Building ${ICU_VERSION} for ${ARCH} / ${TARGET}"

initToolchain "${TARGET}"
if [[ ${isValid} == 0 ]]; then
    return
fi

initCompilerFlags "${ARCH}"

export ARCH_BUILD_DIR="${BUILD_DIR}/build-${ARCH}"
export ARCH_INSTALL_DIR="${BUILD_DIR}/install-${ARCH}"

mkdir -p ${ARCH_BUILD_DIR}
cd ${ARCH_BUILD_DIR}

if [ -z ${FILTER+x} ]; then
    echo "No filters"
else
    echo "Using filters ${FILTER}"
    export ICU_DATA_FILTER_FILE="${FILTER}"
fi

sh ${ICU_SOURCE}/configure --prefix=${ANDROID_INSTALL_DIR} \
    --host=${HOST} \
    --with-library-suffix=${ARCH} \
    --with-cross-build=${MAC_PREBUILD} \
    ${CONFIG_PREFIX}

make clean
make -j4
make install

cd ..

}


echo "==============================="
echo "==== Run build for Android ===="
echo "==============================="

mkdir -p "lib"

####################################################
# Install standalone toolchain x86

build "x86" "i686-linux-android"

####################################################
# Install standalone toolchain x86_64

build "x86_64" "x86_64-linux-android"

################################################################
# Install standalone toolchain arm64

build "aarch64" "aarch64-linux-android"

################################################################
# Install standalone toolchain armv7a

build "armv7a" "arm-linux-androideabi"


mkdir -p "${ANDROID_INSTALL_DIR}/include/"
mkdir -p "${ANDROID_INSTALL_DIR}/include/unicode"

cp ${ICU_SOURCE}/common/unicode/*.h "${ANDROID_INSTALL_DIR}/include/unicode"

echo "done"

