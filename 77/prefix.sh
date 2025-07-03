export ICU_VERSION="77-1"

#==========
# Base setup
#==========

#base directory
export BASE_ICU_DIR="/Users/perry/Development/icu/77"

#Where buidling data are put
export BUILD_DIR="${BASE_ICU_DIR}/build"

export ICU_DIR="${BASE_ICU_DIR}/build/icu-${ICU_VERSION}"

export ICU_SOURCE="${ICU_DIR}/source"

#==========
# Mac
#==========

export MAC_PREBUILD="${BUILD_DIR}/scripts/mac/icu_build"

export MAC_INSTALL_DIR="${BASE_ICU_DIR}/mac/mac-install"

#==========
# IOS
#==========

export IOS_MIN_SDK_VERSION="12.0"

export IOS_INSTALL_DIR="${BASE_ICU_DIR}/ios/ios-install"

#==========
# Android
#==========

#31 compileSdkVersion, 21 minSdkVersion
export ANDROID_API_VERSION=21

export ANDROID_NDK_HOME="/Users/perry/Library/Android/sdk/ndk/28.1.13356709"

#Where final builded data are put
export ANDROID_INSTALL_DIR="${BASE_ICU_DIR}/android/android-install"

#====================================================================================
#====================================================================================
#====================================================================================

#if FILTER variable is not set, all settings are used
#https://github.com/unicode-org/icu/blob/master/docs/userguide/icu_data/buildtool.md
export FILTER="${BASE_ICU_DIR}/filters.json"

export CONFIG_PREFIX=" --enable-extras=yes \
--enable-tools=yes \
--enable-icuio=yes \
--enable-strict=no \
--enable-static \
--enable-shared=no \
--enable-tests=yes \
--disable-renaming \
--enable-samples=no \
--enable-dyload=no \
--with-data-packaging=static"

export CFLAGS="-O3 -D__STDC_INT64__ -fno-exceptions -fno-short-wchar -fno-short-enums"

export CXXFLAGS="${CFLAGS} -std=c++17"

#will set value to 1
defines_config_set_1=( \
"UCONFIG_NO_COLLATION" \
"UCONFIG_NO_LEGACY_CONVERSION" \
"UCONFIG_NO_BREAK_ITERATION" \
"UCONFIG_NO_COLLATION" \
"UCONFIG_NO_FORMATTING" \
"UCONFIG_NO_REGULAR_EXPRESSIONS" \
"UCONFIG_NO_LEGACY_CONVERSION" \
"CONFIG_NO_CONVERSION" \
"U_DISABLE_RENAMING" \
)

#will set value to 0
defines_config_set_0=( \
"U_HAVE_NL_LANGINFO_CODESET" \
"UCONFIG_NO_TRANSLITERATION" \
"U_USING_ICU_NAMESPACE" \
)

#will set value to 1
defines_utypes=( \
"U_CHARSET_IS_UTF8" \
)

