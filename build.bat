@echo off

:: Get Game and Version
if "%NAME%" equ "AxiomVerge" set GAME=AV1
if "%NAME%" equ "AxiomVerge2" set GAME=AV2
for /f %%i in ('powershell "(gi ../AxiomVerge.exe).VersionInfo.ProductVersion"') do set GAMEVERSION=%%i
set REPO=%GAME%-%GAMEVERSION%

:: Execute initialize script because it was not 
if not exist %REPO% call initialize.bat

:: Apply patches
for /f %%i in ('dir /b *.patch') do (echo Applying patch: %%~ni
git -C %REPO% checkout master
git -C %REPO% apply -C 1 --recount --reject --ignore-whitespace ../%%~ni.patch
git -C %REPO% checkout -b %%~ni
git -C %REPO% add -A
git -C %REPO% commit -m New%%~ni)

:: Zip EmbeddedContents.zip
powershell Compress-Archive -f %REPO%/OuterBeyond/EmbeddedContent.Content/* %REPO%/OuterBeyond/EmbeddedContent.Content.zip

:: Build source
dotnet build %REPO%

echo Finished. Check for errors above. Warnings are ok
timeout 5