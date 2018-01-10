export ICU_VERSION="60-2"

export BASE_ICU_DIR="/Users/perry/Development/icu-cross-compile-master"

export ICU_DIR="${BASE_ICU_DIR}/icu-${ICU_VERSION}"

export ICU_SOURCE="${ICU_DIR}/source"

export PREBUILD="${BASE_ICU_DIR}/scripts/mac/icu_build"

export NDK_STANDALONE_TOOLCHAIN_ROOT="${BASE_ICU_DIR}/scripts/android/toolchains"

export ANDROID_NDK="/Users/perry/Library/Android/sdk/ndk-bundle"

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

export CXXFLAGS="${CFLAGS} -std=c++11"

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
