#!/bin/bash

source "../prefix.sh"



function build {
# $1: Toolchain Name
# $2: Toolchain architecture
# $3: Android arch
# $4: host for configure
# $5: additional CPP flags

echo "preparing $1 toolchain"

export PLATFORM_PREFIX=${PWD}/$2-toolchain
export BUILD_DIR=${PWD}/build-$2

#https://developer.android.com/ndk/guides/standalone_toolchain.html
$ANDROID_NDK/build/tools/make_standalone_toolchain.py \
   --api=26 \
   --install-dir=$PLATFORM_PREFIX \
   --stl=libc++ \
   --arch=$3

export PATH=$PLATFORM_PREFIX/bin:$PATH

export CPPFLAGS="-I$PLATFORM_PREFIX/include $CFLAGS -I$ANDROID_NDK/sources/android/cpufeatures $5"
export LDFLAGS="-L$PLATFORM_PREFIX/lib"
export PKG_CONFIG_PATH=$PLATFORM_PREFIX/lib/pkgconfig
export PKG_CONFIG_LIBDIR=$PKG_CONFIG_PATH
export TARGET_HOST="$4"
export CC="$TARGET_HOST-clang"
export CXX="$TARGET_HOST-clang++"
if [ "$ENABLE_CCACHE" ]; then
   export CC="ccache $TARGET_HOST-clang"
   export CXX="ccache $TARGET_HOST-clang++"
fi

mkdir -p ${BUILD_DIR}
cd ${BUILD_DIR}

sh $ICU_SOURCE/configure --host=$TARGET_HOST -with-cross-build=${PREBUILD} ${CONFIG_PREFIX} --prefix=$PLATFORM_PREFIX

make clean
make -j4
make install

cd ..

mkdir -p lib/$2

cp ${BUILD_DIR}/lib/* ./lib/$2/

rm -rf ${PLATFORM_PREFIX}
rm -rf ${BUILD_DIR}

}


echo "==============================="
echo "==== Run build for Android ===="
echo "==============================="

mkdir lib

####################################################
# Install standalone toolchain x86

build "x86" "x86" "x86" "i686-linux-android" ""

####################################################
# Install standalone toolchain x86_64

build "x86_64" "x86_64" "x86_64" "x86_64-linux-android" ""


################################################################
# Install standalone toolchain ARMeabi

build "ARMeabi" "armeabi" "arm" "arm-linux-androideabi" ""

################################################################
# Install standalone toolchain ARMeabi-v7a

build "ARMeabi-v7a" "armeabi-v7a" "arm" "arm-linux-androideabi" "-march=armv7-a -mfloat-abi=softfp -mfpu=vfpv3"

################################################################
# Install standalone toolchain ARM64-v8a

build "ARM64-v8a" "arm64-v8a" "arm64" "aarch64-linux-android" ""

################################################################
# Install standalone toolchain MIPS

build "MIPS" "mips" "mips" "mipsel-linux-android" ""

################################################################
# Install standalone toolchain MIPS64

build "MIPS64" "mips64" "mips64" "mips64el-linux-android" ""


mkdir include
mkdir include/unicode
cp ${ICU_SOURCE}/common/unicode/*.h ./include/unicode



