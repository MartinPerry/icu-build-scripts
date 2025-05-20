#!/bin/bash

function build {
# $1: Toolchain architecture
# $2: host for configure
# $3: build version

ARCH=$1
HOST=$2
PLATFORM=$3

unset CXX
unset CC
unset CFLAGS
unset CXXFLAGS
unset LDFLAGS

source "${PWD}/../prefix.sh"

echo "preparing ${ARCH} toolchain for ${PLATFORM}"

export ARCH_BUILD_DIR="${BUILD_DIR}/build-${ARCH}-${PLATFORM}"
export ARCH_INSTALL_DIR="${BUILD_DIR}/install-${ARCH}-${PLATFORM}"

DEVELOPER="$(xcode-select --print-path)"
SDKROOT="$(xcodebuild -version -sdk ${PLATFORM} | grep -E '^Path' | sed 's/Path: //')"


ICU_FLAGS="-I${ICU_SOURCE}/common/ -I${ICU_SOURCE}/tools/tzcode/ "

export ADDITION_FLAG="-DIOS_SYSTEM_FIX"

export CXX="${DEVELOPER}/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang++"
export CC="${DEVELOPER}/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang"
export CFLAGS="-isysroot ${SDKROOT} -I${SDKROOT}/usr/include/ -I./include/ -arch ${ARCH} -miphoneos-version-min=${IOS_MIN_SDK_VERSION} ${ICU_FLAGS} ${CFLAGS} ${ADDITION_FLAG}"
export CXXFLAGS="${CXXFLAGS} -stdlib=libc++ -isysroot ${SDKROOT} -I${SDKROOT}/usr/include/ -I./include/ -arch ${ARCH} -miphoneos-version-min=${IOS_MIN_SDK_VERSION} ${ICU_FLAGS} ${ADDITION_FLAG}"
export LDFLAGS="-stdlib=libc++ -L${SDKROOT}/usr/lib/ -isysroot ${SDKROOT} -Wl,-dead_strip -miphoneos-version-min=${IOS_MIN_SDK_VERSION} -lstdc++ ${ADDITION_FLAG}"


mkdir -p ${ARCH_BUILD_DIR}
cd ${ARCH_BUILD_DIR}

if [ -z ${FILTER+x} ]; then
    echo "No filters"
else
    echo "Using filters ${FILTER}"
    export ICU_DATA_FILTER_FILE="${FILTER}"
fi

sh ${ICU_SOURCE}/configure \
    --host=${HOST} \
    --with-library-suffix=${ARCH} \
    --with-cross-build=${PREBUILD} \
    --prefix=${ARCH_INSTALL_DIR} \
    ${CONFIG_PREFIX}

make clean
make -j4
make install

cd ..

#rm -rf ${ARCH_BUILD_DIR}

}


