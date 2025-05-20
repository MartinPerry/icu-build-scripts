#!/bin/bash

source "../prefix.sh"



function build {
# $1: Toolchain Name
# $2: Toolchain architecture
# $3: Android arch
# $4: host for configure
# $5: additional CPP flags

export API_VERSION=26

echo "preparing ${1} toolchain"

if [[ ! -d "${ANDROID_NDK_ROOT}/platforms/android-${API_VERSION}/arch-${3}" ]]; then
    echo "Architecture ${3} not exist for API ${API_VERSION}"
    return
fi

export PLATFORM_PREFIX="${PWD}/$2-toolchain"
export BUILD_DIR="${PWD}/build-$2"

#https://developer.android.com/ndk/guides/standalone_toolchain.html
${ANDROID_NDK_ROOT}/build/tools/make_standalone_toolchain.py \
   --api=${API_VERSION} \
   --install-dir=${PLATFORM_PREFIX} \
   --stl=libc++ \
   --arch=$3

export PATH=${PLATFORM_PREFIX}/bin:${PATH}

export CPPFLAGS="-I${PLATFORM_PREFIX}/include ${CFLAGS} -I${ANDROID_NDK_ROOT}/sources/android/cpufeatures $5"
export LDFLAGS="-L${PLATFORM_PREFIX}/lib"
export PKG_CONFIG_PATH=${PLATFORM_PREFIX}/lib/pkgconfig
export PKG_CONFIG_LIBDIR=${PKG_CONFIG_PATH}
export TARGET_HOST="$4"
export CC="${TARGET_HOST}-clang"
export CXX="${TARGET_HOST}-clang++"
if [ "${ENABLE_CCACHE}" ]; then
    export CC="ccache ${TARGET_HOST}-clang"
    export CXX="ccache ${TARGET_HOST}-clang++"
fi

mkdir -p ${BUILD_DIR}
cd ${BUILD_DIR}

if [ -z ${FILTER+x} ]; then
    echo "No filters"
else
    echo "Using filters ${FILTER}"
    export ICU_DATA_FILTER_FILE="${FILTER}"
fi

sh ${ICU_SOURCE}/configure \
    --host=${TARGET_HOST} \
    -with-cross-build=${PREBUILD} \
    --prefix=${PLATFORM_PREFIX} \
    ${CONFIG_PREFIX}

make clean
make -j4
make install

cd ..

mkdir -p "${ANDROID_INSTALL_DIR}/lib/$2"

cp ${BUILD_DIR}/lib/* "${ANDROID_INSTALL_DIR}/lib/$2/"

rm -rf ${PLATFORM_PREFIX}
rm -rf ${BUILD_DIR}

}


echo "==============================="
echo "==== Run build for Android ===="
echo "==============================="

mkdir "${ANDROID_INSTALL_DIR}/lib"

####################################################
# Install standalone toolchain x86

build "x86" "x86" "x86" "i686-linux-android" ""

####################################################
# Install standalone toolchain x86_64

#build "x86_64" "x86_64" "x86_64" "x86_64-linux-android" ""


################################################################
# Install standalone toolchain ARMeabi

build "ARMeabi" "armeabi" "arm" "arm-linux-androideabi" ""

################################################################
# Install standalone toolchain ARMeabi-v7a

build "ARMeabi-v7a" "armeabi-v7a" "arm" "arm-linux-androideabi" "-march=armv7-a -mfloat-abi=softfp -mfpu=vfpv3"

################################################################
# Install standalone toolchain ARM64-v8a

#build "ARM64-v8a" "arm64-v8a" "arm64" "aarch64-linux-android" ""

################################################################
# Install standalone toolchain MIPS

#build "MIPS" "mips" "mips" "mipsel-linux-android" ""

################################################################
# Install standalone toolchain MIPS64

#build "MIPS64" "mips64" "mips64" "mips64el-linux-android" ""


mkdir -p "${ANDROID_INSTALL_DIR}/include/"
mkdir -p "${ANDROID_INSTALL_DIR}/include/unicode"

cp ${ICU_SOURCE}/common/unicode/*.h "${ANDROID_INSTALL_DIR}/include/unicode"



