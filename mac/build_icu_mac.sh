#!/bin/bash

source "../prefix.sh"


svn export http://source.icu-project.org/repos/icu/tags/release-${ICU_VERSION}/icu4c/ ${ICU_DIR} --native-eol LF


echo "===== REMOVING data from bundle ====="

#Data bundle reduction
{
echo "GENRB_CLDR_VERSION = 32.0.1"
echo "GENRB_SYNTHETIC_ALIAS = "
echo "GENRB_ALIAS_SOURCE = \$(GENRB_SYNTHETIC_ALIAS) "
echo "GENRB_SOURCE = "
} > "${ICU_SOURCE}/data/locales/reslocal.mk"

{
echo "LANG_CLDR_VERSION = 32.0.1"
echo "LANG_SYNTHETIC_ALIAS = "
echo "LANG_ALIAS_SOURCE = \$(LANG_SYNTHETIC_ALIAS) "
echo "LANG_SOURCE = "
} > "${ICU_SOURCE}/data/lang/reslocal.mk"

{
echo "CURR_CLDR_VERSION = 32.0.1"
echo "CURR_SYNTHETIC_ALIAS = "
echo "CURR_ALIAS_SOURCE = \$(CURR_SYNTHETIC_ALIAS) "
echo "CURR_SOURCE = "
} > "${ICU_SOURCE}/data/curr/reslocal.mk"

{
echo "REGION_CLDR_VERSION = 32.0.1"
echo "REGION_SYNTHETIC_ALIAS = "
echo "REGION_ALIAS_SOURCE = \$(REGION_SYNTHETIC_ALIAS) "
echo "REGION_SOURCE = "
} > "${ICU_SOURCE}/data/region/reslocal.mk"

{
echo "UNIT_CLDR_VERSION = 32.0.1"
echo "UNIT_SYNTHETIC_ALIAS = "
echo "UNIT_ALIAS_SOURCE = \$(UNIT_SYNTHETIC_ALIAS) "
echo "UNIT_SOURCE = "
} > "${ICU_SOURCE}/data/unit/reslocal.mk"

{
echo "ZONE_CLDR_VERSION = 32.0.1"
echo "ZONE_SYNTHETIC_ALIAS = "
echo "ZONE_ALIAS_SOURCE = \$(ZONE_SYNTHETIC_ALIAS) "
echo "ZONE_SOURCE = "
} > "${ICU_SOURCE}/data/zone/reslocal.mk"

#find "${ICU_SOURCES}/data/mappings/" -name '*.mk' ! -name 'ucmcore.mk' -type f -exec rm -f {} +

mv "${ICU_SOURCE}/data/mappings/ucmcore.mk" "${ICU_SOURCE}/data/mappings/ucmcore.not_used" 2>/dev/null
mv "${ICU_SOURCE}/data/mappings/ucmfiles.mk" "${ICU_SOURCE}/data/mappings/ucmfiles.not_used" 2>/dev/null
mv "${ICU_SOURCE}/data/mappings/ucmebcdic.mk" "${ICU_SOURCE}/data/mappings/ucmebcdic.not_used" 2>/dev/null
mv "${ICU_SOURCE}/data/mappings/ucmlocal.mk" "${ICU_SOURCE}/data/mappings/ucmlocal.not_used" 2>/dev/null



echo "===== Modify icu/source/common/unicode/uconfig.h ====="

cp "${ICU_SOURCE}/common/unicode/uconfig" "${ICU_SOURCE}/common/unicode/uconfig.h" 2>/dev/null
cp "${ICU_SOURCE}/common/unicode/uconfig.h" "${ICU_SOURCE}/common/unicode/uconfig" 2>/dev/null

for var in "${defines_config_set_1[@]}"
do
sed "/define __UCONFIG_H__/a \\
#ifndef ${var} \\
#define ${var} 1 \\
#endif \\
" "${ICU_SOURCE}/common/unicode/uconfig.h" > "${ICU_SOURCE}/common/unicode/uconfig.tmp"

mv "${ICU_SOURCE}/common/unicode/uconfig.tmp" "${ICU_SOURCE}/common/unicode/uconfig.h"
done

for var in "${defines_config_set_0[@]}"
do
sed "/define __UCONFIG_H__/a \\
#ifndef ${var} \\
#define ${var} 0 \\
#endif \\
" "${ICU_SOURCE}/common/unicode/uconfig.h" > "${ICU_SOURCE}/common/unicode/uconfig.tmp"

mv "${ICU_SOURCE}/common/unicode/uconfig.tmp" "${ICU_SOURCE}/common/unicode/uconfig.h"
done

echo "===== Modify icu/source/common/unicode/utypes.h ====="

cp "${ICU_SOURCE}/common/unicode/utypes" "${ICU_SOURCE}/common/unicode/utypes.h" 2>/dev/null
cp "${ICU_SOURCE}/common/unicode/utypes.h" "${ICU_SOURCE}/common/unicode/utypes" 2>/dev/null

for var in "${defines_utypes[@]}"
do
sed "/define UTYPES_H/a \\
#ifndef ${var} \\
#define ${var} 1 \\
#endif \\
" "${ICU_SOURCE}/common/unicode/utypes.h" > "${ICU_SOURCE}/common/unicode/utypes.tmp"

mv "${ICU_SOURCE}/common/unicode/utypes.tmp" "${ICU_SOURCE}/common/unicode/utypes.h"

done

echo "===== Patching icu/source/tools/pkgdata/pkgdata.cpp for iOS ====="

cp "${ICU_SOURCE}/tools/pkgdata/pkgdata" "${ICU_SOURCE}/tools/pkgdata/pkgdata.cpp" 2>/dev/null
cp "${ICU_SOURCE}/tools/pkgdata/pkgdata.cpp" "${ICU_SOURCE}/tools/pkgdata/pkgdata" 2>/dev/null

sed "s/int result = system(cmd);/ \\
#if defined(IOS_SYSTEM_FIX) \\
pid_t pid; \\
char * argv[2]; argv[0] = cmd; argv[1] = NULL; \\
posix_spawn(\&pid, argv[0], NULL, NULL, argv, environ); \\
waitpid(pid, NULL, 0); \\
int result = 0; \\
#else \\
int result = system(cmd); \\
#endif \\
/g" "${ICU_SOURCE}/tools/pkgdata/pkgdata.cpp" > "${ICU_SOURCE}/tools/pkgdata/pkgdata.tmp"

sed "/#include <stdlib.h>/a \\
#if defined(IOS_SYSTEM_FIX) \\
#include <spawn.h> \\
extern char **environ; \\
#endif \\
" "${ICU_SOURCE}/tools/pkgdata/pkgdata.tmp" > "${ICU_SOURCE}/tools/pkgdata/pkgdata.cpp"


#mv "${ICU_SOURCE}/tools/pkgdata/pkgdata.tmp" "${ICU_SOURCE}/tools/pkgdata/pkgdata.cpp"

echo "==============================="
echo "===== Run build for MacOS ====="
echo "==============================="

export PLATFORM_PREFIX="${PWD}/mac-build"

export CPPFLAGS=${CFLAGS}

mkdir ${PREBUILD}
cd ${PREBUILD}

sh ${ICU_SOURCE}/runConfigureICU MacOSX --prefix=${PLATFORM_PREFIX} ${CONFIG_PREFIX}

make clean
make -j4
make install

cd ..

