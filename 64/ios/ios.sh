#!/bin/bash




function build {
# $1: Toolchain Name
# $2: Toolchain architecture
# $3: host for configure
# $4: build version

unset CXX
unset CC
unset CFLAGS
unset CXXFLAGS
unset LDFLAGS

source "$PWD/../prefix.sh"

echo "preparing $1 toolchain"

#export BUILD_DIR="${IOS_INSTALL_DIR}/build-${2}"
export BUILD_DIR="${PWD}/build-${2}"

DEVELOPER="$(xcode-select --print-path)"
SDKROOT="$(xcodebuild -version -sdk $4 | grep -E '^Path' | sed 's/Path: //')"
ARCH=$2

ICU_FLAGS="-I${ICU_SOURCE}/common/ -I${ICU_SOURCE}/tools/tzcode/ "

export ADDITION_FLAG="-DIOS_SYSTEM_FIX"

export CXX="${DEVELOPER}/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang++"
export CC="${DEVELOPER}/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang"
export CFLAGS="-isysroot ${SDKROOT} -I${SDKROOT}/usr/include/ -I./include/ -arch ${ARCH} -miphoneos-version-min=9.0 ${ICU_FLAGS} ${CFLAGS} ${ADDITION_FLAG}"
export CXXFLAGS="${CXXFLAGS} -stdlib=libc++ -isysroot ${SDKROOT} -I${SDKROOT}/usr/include/ -I./include/ -arch ${ARCH} -miphoneos-version-min=9.0 ${ICU_FLAGS} ${ADDITION_FLAG}"
export LDFLAGS="-stdlib=libc++ -L${SDKROOT}/usr/lib/ -isysroot ${SDKROOT} -Wl,-dead_strip -miphoneos-version-min=9.0 -lstdc++ ${ADDITION_FLAG}"

mkdir -p ${BUILD_DIR}
cd ${BUILD_DIR}

if [ -z ${FILTER+x} ]; then
    echo "No filters"
else
    echo "Using filters ${FILTER}"
    export ICU_DATA_FILTER_FILE="${FILTER}"
fi

sh ${ICU_SOURCE}/configure --host=$3 --with-library-suffix=${2} --with-cross-build=${PREBUILD} ${CONFIG_PREFIX}

make clean
make -j4
make install

cd ..


}


