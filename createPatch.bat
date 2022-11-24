@echo off
setlocal EnableDelayedExpansion

:: Get Executeable
for /f %%i in ('dir /b ..\AxiomVerge*.exe') do set NAME=%%~ni
set EXEC=%NAME%.exe 

:: Get Game and Version
if "%NAME%" equ "AxiomVerge" set GAME=AV1
if "%NAME%" equ "AxiomVerge2" set GAME=AV2
for /f %%i in ('powershell "(gi ../AxiomVerge.exe).VersionInfo.ProductVersion"') do set GAMEVERSION=%%i

:: Get Platform (Steam/Epic)
if exist ../CSteamworks.bundle/ (set PLATFORM=Steam 
) else set PLATFORM=Epic

:: Get ModName and ModVersion
for /f %%i in ('git -C temp rev-parse --abbrev-ref HEAD') do set MODNAME=%%i
for /f %%i in ('git -C temp describe --tags') do set LASTMODVERSION=%%i
for /f %%i in ('git -C temp describe --tags --exact-match') do set MODVERSION=%%i

if %LASTMODVERSION% equ %MODVERSION% (
if "%MODVERSION%" equ "Start" set MODVERSION=V0.0.0
) else (
if "%LASTMODVERSION%" equ "Start" (set MODVERSION=V0.0.1
git -C temp tag "V0.0.1" HEAD
:: Increment existing Version
) else (for /F "tokens=1-3 delims=." %%i in (%LASTMODVERSION%) do (set /A k=+1
set MODVERSION=%%i.%%j.!k!
git -C temp tag "%MODVERSION%" HEAD)))

set FULLNAME=%GAME%-%MODNAME%-%MODVERSION%-%PLATFORM%-%GAMEVERSION%

:: Create
rmdir /q /s mods\%FULLNAME%
mkdir mods\%FULLNAME%
mkdir mods\%FULLNAME%\Code
copy mods *.* mods\%FULLNAME%

:: Custom files
(echo ren %EXEC% Old%EXEC%
echo bspatch.exe Old%EXEC% %EXEC% %FULLNAME%.patch
) > mods\%FULLNAME%\applyPatch-%MODNAME%.bat

(echo copy Old%EXEC% %EXEC%
) > mods\%FULLNAME%\removePatchFinal.bat

(echo Install: run applyPatch-%MODNAME%.bat as Admin
echo Uninstall: run removePatchFinal.bat
) > mods\%FULLNAME%\READ-%FULLNAME%.txt

git -C temp diff Start..HEAD > mods\%FULLNAME%\Code\%FULLNAME%.patch
mods\bsdiff.exe backup\%EXEC% ..\%EXEC% mods\%FULLNAME%\%FULLNAME%.patch

:: Create Zip
powershell Compress-Archive -f mods/%FULLNAME%/* mods/%FULLNAME%/%FULLNAME%.zip

timeout 5