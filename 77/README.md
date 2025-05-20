# icu-build-scripts

ICU library build scripts for Mac, iOS and Android. All scripts are intended to run from Mac.

Edit file prefix.sh - change directories

#Build for ICU 77.1 - there is an "error" with system call on iOS. Build script will apply patch to file icu/source/tools/pkgdata/#pkgdata.cpp.
#Fixed based on this: https://stackoverflow.com/questions/48128150/build-icu-for-ios

To modify data in final build, use https://github.com/unicode-org/icu/blob/main/docs/userguide/icu_data/buildtool.md
and set FILTER variable to path to JSON (default value is filters.json)

1) Run Mac script - it will create prebuild data for cross compilation - build_icu_mac.sh
2) Run Android - build.sh
3) Run iOS - build-universal.sh (or call only build-iphonesimulator, build-iphoneos, run-lipo)
