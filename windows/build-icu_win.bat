@echo off
SETLOCAL EnableExtensions EnableDelayedExpansion
::
:: ========================================================================================================
:: ==== ICU Library compilation Cygwin/MSVC
:: ========================================================================================================
:: 
:: This script can be used to compile the ICU Library with Cygwin/MSVC.
::
:: The script builds all (8) permutations of ICU:
::              (x86 | x64) - (static | shared) - (debug | release)
:: 
:: It is still under development and you have to configure it (see <CONFIGURATION> section below)
:: 
::    Author: stathis <stathis@npcglib.org>
::  Revision: $Id: build-icu_59.1.bat 4868 2017-04-18 17:17:56Z stathis $
::
:: Changelog:
::
:: - Upstream ICU 59.x requires a compiler with c++11 support.
::   Therefore, currently only MSVC 2015 and 2017 are supported.
::   MSVC 2008/2010/2013 compiles are no more!
:: 
:: - Updated this batch script to support MSVC 2017.
::
:: - Fixed a bug in cintltst that prevented the tests from compiling on MSVC 2012, 2010 and 2008.
::   see ICU Ticket: http://bugs.icu-project.org/trac/ticket/12840
::
:: - I no longer build ICU with the deprecated Layout Engine (--disable-layout --disable-layoutex)
::   For more info on the deprecation see: http://userguide.icu-project.org/layoutengine
::
:: - Fixed a bug with 7z detection and spaces in its directory.
::
:: - MSVC 2008 fails intltest fails: http://www.icu-project.org/trac/ticket/11964
::
:: - ICU ticket 10909 is no longer a problem 
::   bugs.icu-project.org/trac/ticket/10909
::
:: - MSVC2008 is no longer supported. (there are tests that fail - not sure if ICU works properly)
:: - By default I use the ICU data without any modifications. If you need to reduce the size of your
::   application, this is the first place to look at. Use the ICU data lib customizer, explained below.
::
:: - Added support for custom ICU data packages generated with the 
::   ICU Data Library Customizer  http://apps.icu-project.org/datacustom/)
::   To use, generate an ICU data file: icudtXXl.dat and place it in the same directory with this script
::   It will be copied to the correct location to build ICU with it (in source/data/out/tmp/)
::
:: - Fixed a bug in the packaging of the binaries
:: - The configuration is now printed on the console
:: - Added local configuration file support
:: - Cygwin is added before VS in the path. This is necessary to use Cygwin's linked instead of VS.
:: - multiple cores at make time are no longer supported (error building data on some platforms)
:: - Added the ability to compile different flavors of the library (see usage)
:: - Removed --with-data-packaging=static, auto is used instead (thx Yi Z.)
:: - Added double quotes to handle a problem with VISUAL_STUDIO_VC path containing spaces (thx Yi Z.)
:: - Improved the directory naming to include the VS version used. (works ok with VS2010 and VS2012)
:: - Fixed a bug that caused the debug built libraries to link against the wrong runtime. (thx Robert M.)
:: - ICU's "make install" doesn't deploy the PDB files, we copy them ourselves. (thx Robert M.)
::
:: ========================================================================================================
:: ==== <CONFIGURATION>
:: ========================================================================================================

:: Set the version of Visual Studio. This will just add a suffix to the string
:: of your directories to avoid mixing them up.
SET VS_VERSION=2022

:: Set this to the directory that contains vcvarsall.bat file of the 
:: VC Visual Studio version you want to use for building.
:: You can always replace it with the actual directory
SET VISUAL_STUDIO_VC=C:\Program Files\Microsoft Visual Studio\2022\Enterprise\VC\Auxiliary\Build

:: Set CYGWIN_DIR to the location of your Cygwin root ( one level up from /bin )
:: I use Cygwin Portable (http://symbiosoft.net/projects/cygwin-portable)
:: Make sure you install the following packages:
::  p7zip, md5sum, patch
SET CYGWIN_DIR=C:\cygwin64

rem ========================================================================================================

:: Set here the 7z command line to use for creating packages
:: Use an absolute path to the 7z.exe utility if it is not in your path.
:: -mx0 store compression
:: -mx9 ultimate compression
SET SEVENZIP_CMD=7z
::SET SEVENZIP_CMD_OPTIONS=a -r -mx9

:: Set here the location of the md5sum command, which is used to create md5 
:: checksums for the archives after packaging
:: Use an absolute path to the md5sum.exe utility or append its directory in your PATH.
SET MD5SUM_CMD=md5sum

:: Set here the date command
:: Use an absolute path to the date.exe utility or append its directory in your PATH.
SET DATE_CMD=date

:: Set here the patch command
:: Use an absolute path to the patch.exe utility or append its directory in your PATH.
SET PATCH_CMD=patch

:: Use an absolute path to the dos2unix.exe utility or append its directory in your PATH.
SET DOS2UNIX_CMD=dos2unix

rem ========================================================================================================

:: Set this to the name of the project
SET BUILD_PROJECT=icu

:: Set this to the version of the project you are building
SET PROJECT_VERSION=72.1

:: Set this to the directory containing the source code
SET PROJECT_SRC_DIR=E:\Programming\C++\icu\

SET PROJECT_INSTALL_DIR=e:\Programming\C++\icu\icu-dist-!PROJECT_VERSION!-vs!VS_VERSION!

:: This can be used to build ICU with your custom data. If missing you'll get the default .dat
:: %~dp0 represents the directory of this batch script. 
:: Meaning the .dat file must be in the same dir.
SET ICU_CUSTOM_DATA=%~dp0icudt59l.dat

rem ========================================================================================================
rem == PLEASE DO NOT EDIT BELOW THIS LINE
rem ========================================================================================================

rem We load the config file first
call :loadconfig "%~dpn0"

rem we then carry on execution
call :execScript %0 %1 %2 %3 %4

ENDLOCAL

@exit /B 0

rem ========================================================================================================
rem == Pseudo-function to load config
rem ========================================================================================================

:loadconfig
rem set the variable HOSTNAME by executing the command (that's the computer's name)
FOR /F "delims=" %%a IN ('hostname') DO @set HOSTNAME=%%a

rem strip double quotes
set scriptFile=%1
set scriptFile=%scriptFile:"=%

rem We use two files: myScript.conf and myScript.<HOSTNAME>
rem myScript.<HOSTNAME> overrides myScript.conf
rem %~dpn0 is the full file minus the extension.
FOR %%c IN (
	"!scriptFile!.conf"
	"!scriptFile!.!HOSTNAME!"
) DO (
	IF EXIST "%%c" (
		ECHO.
		ECHO # Loading local configuration from: %%c
		ECHO.
		FOR /F "usebackq delims=" %%v IN (%%c) DO (set %%v)
	)
)

GOTO :eof

rem ========================================================================================================

:execScript
rem Use this pseudo-function to write the code of your main script
SETLOCAL EnableExtensions EnableDelayedExpansion

SET scriptName=%1
SET arg[0]=%2
SET arg[1]=%3
SET arg[2]=%4
SET arg[3]=%5

:: ATTENTION: this is down here because out-of-source builds are not supported DO NOT CHANGE IT!
SET PROJECT_BUILD_DIR=!PROJECT_SRC_DIR!\build

IF "!arg[0]!" == "" GOTO usage
IF NOT EXIST "!PROJECT_SRC_DIR!" (
	ECHO.
	CALL :exitB "ERROR: Source directory !PROJECT_SRC_DIR! does not exist or does not contain the !BUILD_PROJECT! sources. Aborting."
	GOTO :eof
)

IF NOT EXIST "!PROJECT_SRC_DIR!" (
	ECHO.
	CALL :exitB "ERROR: Source directory !PROJECT_SRC_DIR! does not exist or does not contain the !BUILD_PROJECT! sources. Aborting."
	GOTO :eof
)

IF DEFINED CYGWIN_DIR (
	IF NOT EXIST "!CYGWIN_DIR!" (
		ECHO.
		CALL :exitB "ERROR: Cygwin directory !CYGWIN_DIR! does not exist. You need a valid Cygwin installation to use this script. Aborting."
		GOTO :eof
	)
	
	SET PATH=!PATH!;!CYGWIN_DIR!\bin
)


IF "!VS_VERSION!" == "2017" (
	SET VISUAL_STUDIO_VC=!VISUAL_STUDIO_VC!\Auxiliary\Build
	pushd "!VISUAL_STUDIO_VC!\..\..\..\Common7\Tools\"
	call "!VISUAL_STUDIO_VC!\..\..\..\Common7\Tools\vsdevcmd.bat" -clean_env
	popd
)

IF NOT EXIST "!VISUAL_STUDIO_VC!\vcvarsall.bat" (
	ECHO.
	CALL :exitB "ERROR: !VISUAL_STUDIO_VC!\vcvarsall.bat does not exist. Aborting."
	GOTO :eof
)

IF "!SEVENZIP_CMD_OPTIONS!" == "" (
	SET SEVENZIP_CMD_OPTIONS=a -r -mx9
)

FOR /F "delims=" %%a IN ('!CYGWIN_DIR!/bin/cygpath -p -u !SEVENZIP_CMD!') DO @set __SEVENZIP_CMD=%%a

IF "!DATE_CMD_OPTIONS!" == "" (
	SET DATE_CMD_OPTIONS=%%d %%b %%Y
)

IF "!arg[0]!" == "" GOTO usage

SET argC=-1
FOR %%x in (%*) DO SET /A argC+=1

if /i "!arg[0]!" == "build" (

	if !argC! == 2 (

		if /i "!arg[1]!" == "all" (

			echo.
			echo You are about to build all permutations [x86^|x64] [static^|shared] [debug^|release]
			echo.

			timeout /t 5
					
			call :buildall
			goto :eof
			
		) else (
			goto usage
		)
		
	) else if !argC! == 4 (

		call :callArch !arg[1]! !arg[2]! !arg[3]!
		goto :eof
		
	) else (
		goto usage
	)
	
) else if /i "!arg[0]!" == "package" (

	if !argC! == 2 (

		if /i "!arg[1]!" == "all" (

			echo.
			echo You are about to package all permutations [x86^|x64] [static^|shared] [debug^|release]
			echo.

			timeout /t 5
			
			call :createPackage
			goto :eof
			
		) else (
			goto usage
		)
		
	) else if !argC! == 3 (
		
		echo.
		echo This feature is currently unsupported. Only "package all" is supported at this time.
		echo.
			
		goto usage
		
		REM set archGood=false
		REM if /i "!arg[1]!" == "x86" set archGood=true
		REM if /i "!arg[1]!" == "x64" set archGood=true

		REM if /i "!archGood!" == "true" (

			REM call :createPackage !arg[0]! !arg[1]!
			REM goto :eof
			
		REM ) else (
			REM goto usage
		REM )
	) else (
		goto usage
	)
	
) else if /i "!arg[0]!" == "patch" (
	call :patch !PROJECT_VERSION!
	IF EXIST "!ICU_CUSTOM_DATA!" (
		copy /Y !ICU_CUSTOM_DATA! !PROJECT_SRC_DIR!\source\data\in\ 1>nul 
	) ELSE (
		echo [Build Warning]: ICU file !ICU_CUSTOM_DATA! does not exist. Using default icu data configuration.
	)
) else if /i "!arg[0]!" == "unpatch" (
	call :unpatch !PROJECT_VERSION!
) else if !argC! == 3 (
	call :callArch !arg[0]! !arg[1]! !arg[2]!
	GOTO :eof
) else (
	GOTO usage
)

ENDLOCAL
GOTO :eof

rem ========================================================================================================
:printConfiguration
SETLOCAL EnableExtensions EnableDelayedExpansion
SET PATH=!CYGWIN_DIR!\bin;!CYGWIN_DIR!\usr\sbin;!PATH!

echo.
echo                    PATH: !PATH!
echo.

echo              VS_VERSION: !VS_VERSION!
echo        VISUAL_STUDIO_VC: !VISUAL_STUDIO_VC!
echo              CYGWIN_DIR: !CYGWIN_DIR!
echo.
bash -c "echo -n \"           SEVENZIP_CMD: \" & which \"!__SEVENZIP_CMD!\""
echo    SEVENZIP_CMD_OPTIONS: !SEVENZIP_CMD_OPTIONS!
bash -c "echo -n \"             MD5SUM_CMD: \" & which !MD5SUM_CMD!"
bash -c "echo -n \"               DATE_CMD: \" & which !DATE_CMD!"
bash -c "echo -n \"              PATCH_CMD: \" & which !PATCH_CMD!"
echo.
echo           BUILD_PROJECT: !BUILD_PROJECT!
echo         PROJECT_VERSION: !PROJECT_VERSION!
echo         PROJECT_SRC_DIR: !PROJECT_SRC_DIR!
echo       PROJECT_BUILD_DIR: !PROJECT_BUILD_DIR!
echo     PROJECT_INSTALL_DIR: !PROJECT_INSTALL_DIR!
ENDLOCAL
goto :eof

rem ========================================================================================================

:callArch
set archGood=false
if /i "%1" == "x86" set archGood=true
if /i "%1" == "x64" set archGood=true
if /i "!archGood!" == "true" (

	set linkGood=false
	if /i "%2"=="static" set linkGood=true
	if /i "%2"=="shared" set linkGood=true

	if /i "!linkGood!" == "true" (

		set buildGood=false
		if /i "%3" == "debug" set buildGood=true
		if /i "%3" == "release" set buildGood=true

		if /i "!buildGood!" == "true" (
		
			call :build %1 %2 %3
			goto :eof
			
		)
	)
	
)
goto usage
goto :eof

rem ========================================================================================================

:usage
call :printConfiguration
ECHO: 
ECHO Error in script usage. The correct usage is:
ECHO:
ECHO     !scriptName! [patch^|unpatch] - apply/remove patches to the sources
ECHO     !scriptName! build [all^|x86^|x64] ^<[static^|shared] [debug^|release]^> - builds all or specific permutations
ECHO     !scriptName! package [all^|x86^|x64] ^<[static^|shared]^> - creates a package file
ECHO:    
GOTO :eof

rem ========================================================================================================

:unpatch
rem remove patches from the sources
call :patch %1 unpatch
goto :eof

:patch
rem patch sources

SETLOCAL EnableExtensions EnableDelayedExpansion

if /i "%2" == "unpatch" (
	SET EXTRA_TEXT=Removing
	SET EXTRA_FLAGS=-R
) else (
	SET EXTRA_TEXT=Applying
)

SET PATH=!CYGWIN_DIR!\bin;!CYGWIN_DIR!\usr\sbin;

SET CYGWIN=nodosfilewarning

ECHO.
ECHO !EXTRA_TEXT! patches to [!BUILD_PROJECT! v%~1] sources
ECHO.

pushd "!PROJECT_SRC_DIR!"

	SET patchfile=!BUILD_PROJECT!_%~1.patch
	
	call :applyPatch !patchfile!
	
popd

ENDLOCAL
goto :eof

:applyPatch
SET PATCH_FILE=%~dp0
SET PATCH_FILE=!PATCH_FILE!%1

IF NOT EXIST "!PATCH_FILE!" (

	call :exitB "Patch: [!PATCH_FILE!] does not exist. Aborting."

) ELSE (

	rem diff -uNr icu-svn-54.1.orig icu-svn-54.1 > icu_54.1.patch
	!DOS2UNIX_CMD! "!PATCH_FILE!"
	!PATCH_CMD! --binary !EXTRA_FLAGS! -N -p1 -i "!PATCH_FILE!"
	
)
goto :eof

rem ========================================================================================================

:createPackage

call :printConfiguration

echo:
echo Packaging ICU v!PROJECT_VERSION! Library
echo:

SET DIST_DIR=!PROJECT_INSTALL_DIR!\!BUILD_PROJECT!-!PROJECT_VERSION!-vs!VS_VERSION!

echo !DIST_DIR!

@mkdir !DIST_DIR!\bin 2>nul
@mkdir !DIST_DIR!\bin64 2>nul
@mkdir !DIST_DIR!\lib 2>nul
@mkdir !DIST_DIR!\lib64 2>nul
@mkdir !DIST_DIR!\data 2>nul
@mkdir !DIST_DIR!\include 2>nul

call :packagetype

echo:

ENDLOCAL
@exit /B 0

rem ========================================================================================================

:: %1 library type (e.g. static)
:packagetype

SET DST_DIST=!BUILD_PROJECT!-!PROJECT_VERSION!-vs!VS_VERSION!
SET DST_DIST_DIR=!PROJECT_INSTALL_DIR!\!DST_DIST!

for %%l in (static shared) do (
	for %%a in (x86 x64) do (
		for %%b in (debug release) do (

			SET __ARCH=%%a
			SET __BUILD=%%b
			SET __LINK=%%l
		
			if /i "!__ARCH!" == "x86" (
				SET BITS=32
				SET BIT_STR=
			) else (
				SET BITS=64
				SET BIT_STR=64
			)

			
			SET RUNTIME_SUFFIX=M
			IF /i "!__LINK!" == "static" (
				SET RUNTIME_SUFFIX=!RUNTIME_SUFFIX!T
			) ELSE (
				SET RUNTIME_SUFFIX=!RUNTIME_SUFFIX!D
			)
			
			IF /i "!__BUILD!" == "debug" (
				SET RUNTIME_SUFFIX=!RUNTIME_SUFFIX!d
			)			
			
			SET PDBFILE=!BUILD_PROJECT!!RUNTIME_SUFFIX!.pdb
			
			
			SET SRC_DIST_DIR=!PROJECT_INSTALL_DIR!\!BUILD_PROJECT!-!__ARCH!-!__LINK!-!__BUILD!-vs!VS_VERSION!

			echo [copy] !SRC_DIST_DIR! =^> !DST_DIST_DIR!
		
			if exist "!SRC_DIST_DIR!" (

				rem IF EXIST "!SRC_DIST_DIR!\lib\!PDBFILE!" (
				rem 	xcopy /Q /Y /S !SRC_DIST_DIR!\lib\!PDBFILE! !DST_DIST_DIR!\lib!BIT_STR! 1>nul
				rem )
				
				xcopy /Q /Y /S !SRC_DIST_DIR!\bin !DST_DIST_DIR!\bin!BIT_STR! 1>nul
				xcopy /Q /Y /S !SRC_DIST_DIR!\lib\*.lib !DST_DIST_DIR!\lib!BIT_STR! 1>nul
				xcopy /Q /Y /S !SRC_DIST_DIR!\lib\*.dll !DST_DIST_DIR!\bin!BIT_STR! 1>nul
				
				xcopy /Q /Y /S !SRC_DIST_DIR!\lib\*.pdb !DST_DIST_DIR!\bin!BIT_STR! 1>nul
				
				
				xcopy /Q /Y /S !SRC_DIST_DIR!\include !DST_DIST_DIR!\include 1>nul
				xcopy /Q /Y /S !SRC_DIST_DIR!\data\icudt*l.dat !DST_DIST_DIR!\data\ 1>nul

			)
			
		)
	)
)


echo Copied all files for: !BUILD_PROJECT! v!PROJECT_VERSION!

set README=!DST_DIST_DIR!\readme.txt
echo !README!


pushd !DST_DIST_DIR!\..

	SETLOCAL EnableExtensions EnableDelayedExpansion

	SET PATH=!CYGWIN_DIR!\bin;!CYGWIN_DIR!\usr\sbin

	echo. > !README!
	bash -c "!DATE_CMD! +\"!DATE_CMD_OPTIONS!\"" >> !README!
	echo ====================================================================================================================== >> !README!
	echo  url: http://www.npcglib.org/~stathis/blog/precompiled-icu >> !README!
	echo ====================================================================================================================== >> !README!
	echo These are the pre-built ICU Libraries v!PROJECT_VERSION!. They are compiled with Cygwin/MSVC  >> !README!
	echo for 32/64-bit Windows, using Visual Studio !VS_VERSION!. >> !README!
	echo. >> !README!
	echo ----------------------------------------------------------------------- >> !README!
	echo 32-bit shared release runtime dlls: bin\icu*.dll >> !README!
	echo 32-bit shared release import libs: lib\icu*.lib >> !README!
	
	echo 32-bit shared debug runtime dlls: bin\icu*d.dll >> !README!
	echo 32-bit shared debug import libs: lib\icu*d.lib >> !README!

	echo 32-bit static release libs: lib\sicu*.lib >> !README!
	echo 32-bit static debug libs: lib\sicu*d.lib >> !README!
	echo ----------------------------------------------------------------------- >> !README!
	echo 64-bit shared release runtime dlls: bin64\icu*.dll >> !README!
	echo 64-bit shared release import libs: lib64\icu*.lib >> !README!

	echo 64-bit shared debug runtime dlls: bin64\icu*d.dll >> !README!
	echo 64-bit shared debug import libs: lib64\icu*d.lib >> !README!

	echo 64-bit static release libs: lib64\sicu*.lib >> !README!
	echo 64-bit static debug libs: lib64\sicu*d.lib >> !README!
	echo ----------------------------------------------------------------------- >> !README!
	echo. >> !README!
	echo When using them you may need to specify an environment variable ICU_DATA pointing to the data/ folder. >> !README!
	echo This is where the icudtXXl.dat file lives. >> !README!
	echo     e.g. set ICU_DATA=F:\icu\data >> !README!
	echo ====================================================================================================================== >> !README!
	echo If you have any comments or problems send me an email at: >> !README!
	echo stathis ^<stathis@npcglib.org^> >> !README!

	set __FILENAME=!DST_DIST!

	set COMPRESSED_FILE=!__FILENAME!.7z

	echo.
	echo Packaging !BUILD_PROJECT! Library [v!PROJECT_VERSION!]
	echo ----------------------------------------------------------------------------
	echo [     Build in: !PROJECT_BUILD_DIR!] 
	echo [ Installation: !PROJECT_INSTALL_DIR!] 
	echo [    Packaging: !CD!]
	echo [   Compressed: !COMPRESSED_FILE!]
	echo [       Readme: !README!]
	echo ----------------------------------------------------------------------------
	echo.

	echo Compressing with: !__SEVENZIP_CMD! !SEVENZIP_CMD_OPTIONS! !COMPRESSED_FILE! !DST_DIST!
	bash -c "\"!__SEVENZIP_CMD!\" !SEVENZIP_CMD_OPTIONS! !COMPRESSED_FILE! !DST_DIST!"
	
	IF EXIST "!COMPRESSED_FILE!" (
		
		for %%I in (!COMPRESSED_FILE!) do (
			SET /A _fsize=%%~zI / 1024 / 1024
		)
		
		!MD5SUM_CMD! !COMPRESSED_FILE! 1> !__FILENAME!.md5
		
		echo Generated md5sum !__FILENAME!.md5 [!_fsize!MB]

	)

	ENDLOCAL

popd

goto :eof

rem ========================================================================================================

:buildall

IF NOT EXIST "!CYGWIN_DIR!\bin\make.exe" (
	ECHO.
	call :exitB "Either !CYGWIN_DIR! is not the Cygwin root, or you have to install maketools. (make.exe is missing)"
	goto :eof
)

for %%a in (x86 x64) do (
	for %%l in (shared static) do (
		for %%b in (debug release) do (
			call :build %%a %%l %%b
		)
	)
)

goto :eof

rem ========================================================================================================

:: call :build <x86|x64> <static|shared> <debug|release>
:build
SET __ARCH=%~1
SET __LINK=%~2
SET __BUILD=%~3

if /i "!__ARCH!" == "x86" (
	SET BITS=32
	SET BIT_STR=
) else (
	SET BITS=64
	SET BIT_STR=64
)

IF NOT EXIST "!CYGWIN_DIR!\bin\make.exe" (
	ECHO.
	call :exitB "Either !CYGWIN_DIR! is not the Cygwin root, or you have to install maketools. (make.exe is missing)"
	goto :eof
)

echo:
echo Building ICU Library [!__ARCH!] [!__LINK!] [!__BUILD!]
echo:

SETLOCAL EnableExtensions EnableDelayedExpansion

	IF "!VS_VERSION!" == "2017" (
		pushd "!VISUAL_STUDIO_VC!\..\..\..\Common7\Tools\"
		call "!VISUAL_STUDIO_VC!\..\..\..\Common7\Tools\vsdevcmd.bat" -clean_env
		popd
	)

	call "!VISUAL_STUDIO_VC!\vcvarsall.bat" !__ARCH!
	
	rem Place the linker and compiler of Visual Studio infront of any other binaries when searching
	SET PATH=!PATH!;!CYGWIN_DIR!\bin;!CYGWIN_DIR!\usr\sbin;
	
	call :printConfiguration
	call :buildtype !__ARCH! !__LINK! !__BUILD!
	
ENDLOCAL
goto :eof

rem ========================================================================================================

:buildtype
:: %1 architecture (e.g. x86)
:: %2 library type (e.g. static)
:: %3 build type (e.g. release)
SET __ARCH=%~1
SET __LINK=%~2
SET __BUILD=%~3

SET CYGWIN=nodosfilewarning

if /i "!__ARCH!" == "x86" (
	SET BITS=32
	SET BIT_STR=
) else (
	SET BITS=64
	SET BIT_STR=64
)

IF NOT EXIST "!PROJECT_BUILD_DIR!" (
	mkdir "!PROJECT_BUILD_DIR!"
)

pushd !PROJECT_BUILD_DIR!

	SET BUILD_DIR=!BUILD_PROJECT!-!__ARCH!-!__LINK!-!__BUILD!-vs!VS_VERSION!

	IF NOT EXIST "!BUILD_DIR!" (
		mkdir "!BUILD_DIR!"
	)
	
	SET INSTALL_DIR_WIN=!PROJECT_INSTALL_DIR!\!BUILD_DIR!
	SET BUILD_DIR_DEST=!PROJECT_BUILD_DIR!\!BUILD_DIR!

	if not exist "!BUILD_DIR_DEST!" (
		mkdir "!BUILD_DIR_DEST!"
	)
		
	rem Convert the INSTALL_DIR_WIN to a cygwin path	
	FOR /F "delims=" %%a IN ('cygpath -p -u !INSTALL_DIR_WIN!') DO @set INSTALL_DIR_CYGWIN=%%a
	
	rem Convert the PROJECT_SRC_DIR_CYGWIN to a cygwin path	
	FOR /F "delims=" %%a IN ('cygpath -p -u !PROJECT_SRC_DIR!') DO @set PROJECT_SRC_DIR_CYGWIN=%%a
	
	SET LOG_FILE="!INSTALL_DIR_WIN!\!BUILD_DIR!.log"
	rem FOR /F "delims=" %%a IN ('cygpath -p -u !LOG_FILE!') DO @set LOG_FILE_CYGWIN=%%a
	
	pushd !BUILD_DIR_DEST!
		
		ECHO. > !BUILD_DIR!.log
		
		SET B_CMD=../../source/runConfigureICU
		rem SET B_CMD=!PROJECT_SRC_DIR_CYGWIN!/source/runConfigureICU
		
		IF /i "!__BUILD!" == "debug" (
			SET B_CMD=!B_CMD! --enable-debug --disable-release
		)
		
		IF /i "!__LINK!" == "static" (
			SET B_CMD=!B_CMD! --static-runtime
		) 
		
		SET B_CMD=!B_CMD! Cygwin/MSVC --prefix=!INSTALL_DIR_CYGWIN! 

		
		IF /i "!__LINK!" == "static" (
			SET B_CMD=!B_CMD! --enable-static --disable-shared
		) ELSE (
			SET B_CMD=!B_CMD! --enable-shared --disable-static
		)
		
		IF /i "!__BUILD!" == "debug" (
			SET B_CMD=!B_CMD! --enable-debug --disable-release
		) ELSE (
			SET B_CMD=!B_CMD! --enable-release --disable-debug
		)
		
		rem Disable the deprecated layout engine
		SET B_CMD=!B_CMD! --disable-layout --disable-layoutex 
		
		echo ------------------------------
		echo   Configuring: !BUILD_DIR!
		echo   Building in: !BUILD_DIR_DEST!
		echo   Install Dir: !INSTALL_DIR_CYGWIN!
		echo   Install Win: !INSTALL_DIR_WIN!
		echo    Logging in: !LOG_FILE!
		echo       Command: !B_CMD!
		echo ------------------------------

		
		IF NOT EXIST !INSTALL_DIR_WIN! (
			mkdir !INSTALL_DIR_WIN!
		)

		
		bash -c "!B_CMD!" >> !BUILD_DIR!.log 2>&1
		make >> !BUILD_DIR!.log 2>&1

		IF NOT EXIST !INSTALL_DIR_WIN!\data (
			mkdir !INSTALL_DIR_WIN!\data
		)

		copy /Y data\out\tmp\icudt*l.dat !INSTALL_DIR_WIN!\data\ 1>nul
		
		echo ====================================================================================== >> !BUILD_DIR!.log
		echo Calling "make check" >> !BUILD_DIR!.log
		echo ====================================================================================== >> !BUILD_DIR!.log
		SETLOCAL
			SET ICU_DATA=!INSTALL_DIR_WIN!\data\
			make check >> !BUILD_DIR!.log 2>&1
		ENDLOCAL

		echo ====================================================================================== >> !BUILD_DIR!.log
		echo Calling "make install" >> !BUILD_DIR!.log
		echo ====================================================================================== >> !BUILD_DIR!.log
		make install >> !BUILD_DIR!.log 2>&1

		IF /i "!__LINK!" == "shared" (

			xcopy /Q /Y /S !BUILD_DIR_DEST!\lib\*.exp !INSTALL_DIR_WIN!\lib\ 1>nul

			IF /i "!__BUILD!" == "debug" (
				xcopy /Q /Y /S !BUILD_DIR_DEST!\lib\*.pdb !INSTALL_DIR_WIN!\lib\ 1>nul
			)

		)

		xcopy /Q /Y !BUILD_DIR_DEST!\*.pdb !INSTALL_DIR_WIN!\lib\ 1>nul

		copy !BUILD_DIR!.log !LOG_FILE!

	popd

popd

goto :eof

rem ========================================================================================================

:toLower str -- converts uppercase character to lowercase
::           -- str [in,out] - valref of string variable to be converted
:$created 20060101 :$changed 20080219 :$categories StringManipulation
:$source http://www.dostips.com
if not defined %~1 EXIT /b
for %%a in ("A=a" "B=b" "C=c" "D=d" "E=e" "F=f" "G=g" "H=h" "I=i"
            "J=j" "K=k" "L=l" "M=m" "N=n" "O=o" "P=p" "Q=q" "R=r"
            "S=s" "T=t" "U=u" "V=v" "W=w" "X=x" "Y=y" "Z=z" "Ä=ä"
            "Ö=ö" "Ü=ü") do (
    call set %~1=%%%~1:%%~a%%
)
EXIT /b

rem ========================================================================================================

:: %1 an error message
:exitB
echo:
echo Error: %1
echo:
echo Contact stathis@npcglib.org
@exit /B 0
