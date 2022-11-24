@echo off
setlocal EnableDelayedExpansion
:: PARAMETER(COUNT 1): String : GIT-Directory : Default(CurrentVersion)
:: Use this when you want to create a patch from an older version.
:: Example: imagine that your current Version of AV1 is 1.58.0.0 but you already developed a mod for 1.57.0.0
:: Now you can supply AV1-1.57.0.0 to publish all the files from the old active branch

:: Get Executeable
for /f %%i in ('dir /b ..\AxiomVerge*.exe') do set NAME=%%~ni
set EXEC=%NAME%.exe 

:: Get Game and Version
if "%NAME%" equ "AxiomVerge" set GAME=AV1
if "%NAME%" equ "AxiomVerge2" set GAME=AV2
for /f %%i in ('powershell "(gi ../AxiomVerge.exe).VersionInfo.ProductVersion"') do set GAMEVERSION=%%i
set REPO=%GAME%-%GAMEVERSION%

:: Get Platform (Steam/Epic)
if exist ../CSteamworks.bundle/ (set PLATFORM=Steam 
) else set PLATFORM=Epic

:: Execute build script because it was not or use legacy directory
if not exist %REPO% call build.bat
if %1.==. set REPO=%1
if not exist %REPO% ( echo ERROR: Your supplied directory does not exist
exit /b 1)

:: Get ModName and ModVersion
for /f %%i in ('git -C %REPO% rev-parse --abbrev-ref HEAD') do set MODNAME=%%i
for /f %%i in ('git -C %REPO% describe --tags') do set LASTMODVERSION=%%i
for /f %%i in ('git -C %REPO% describe --tags --exact-match') do set MODVERSION=%%i

if %LASTMODVERSION% equ %MODVERSION% (
if "%MODVERSION%" equ "Start" set MODVERSION=V0.0.0
) else (
if "%LASTMODVERSION%" equ "Start" (set MODVERSION=V0.0.1
git -C %REPO% tag "V0.0.1" HEAD
:: Increment existing Version
) else (for /F "tokens=1-3 delims=." %%i in (%LASTMODVERSION%) do (set /A k=+1
set MODVERSION=%%i.%%j.!k!
git -C %REPO% tag "%MODVERSION%" HEAD)))

set FULLNAME=%GAME%-%MODNAME%-%MODVERSION%-%PLATFORM%-%GAMEVERSION%

:: Create
rmdir /q /s mods\%FULLNAME%
mkdir mods\%FULLNAME%
mkdir mods\%FULLNAME%\Code
copy mods *.* mods\%FULLNAME%

:: Custom files
:: Patch the most recent applicable file, otherwise give specific error
(echo bspatch.exe %EXEC% %FULLNAME%.exe %FULLNAME%.patch
) > mods\%FULLNAME%\applyPatch-%MODNAME%.bat

(echo Install: run applyPatch-%MODNAME%.bat as Admin
echo Look out for Errors and seek help in the discord modding channel.
) > mods\%FULLNAME%\READ-%MODNAME%.txt

if "%NAME%" equ "AxiomVerge" ((echo 332200) > mods\%FULLNAME%\steam_appid.txt)
if "%NAME%" equ "AxiomVerge2" ((echo 946030) > mods\%FULLNAME%\steam_appid.txt)

git -C %REPO% diff Start..HEAD > mods\%FULLNAME%\Code\%FULLNAME%.patch
mods\bsdiff.exe backup\%EXEC% ..\%EXEC% mods\%FULLNAME%\%FULLNAME%.patch

:: Create Zip
powershell Compress-Archive -f mods/%FULLNAME%/* mods/%FULLNAME%/%FULLNAME%.zip

timeout 5