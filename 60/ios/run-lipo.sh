#!/bin/bash

source "$PWD/../prefix.sh"

mkdir include
mkdir include/unicode
cp ${ICU_SOURCE}/common/unicode/*.h ./include/unicode

echo "Combining i386, x86 64, armv7, armv7s, and arm64 libraries."

function buildUniversal {
lipo -create -output "${PWD}/lib/$1.a" \
    "${PWD}/build-arm64/lib/$1arm64.a" \
    "${PWD}/build-armv7s/lib/$1armv7s.a" \
    "${PWD}/build-i386/lib/$1i386.a" \
    "${PWD}/build-x86_64/lib/$1x86_64.a" \
    "${PWD}/build-armv7/lib/$1armv7.a"
}

mkdir lib

buildUniversal "libicui18n"
buildUniversal "libicuio"
buildUniversal "libicule"
buildUniversal "libiculx"
buildUniversal "libicutu"
buildUniversal "libicuuc"
buildUniversal "libicudata"

