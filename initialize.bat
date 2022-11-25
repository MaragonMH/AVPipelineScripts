@echo off
echo This Script will take a few minutes to complete

:: Get Executeable
for /f %%i in ('dir /b ..\AxiomVerge*.exe') do set NAME=%%~ni
set EXEC=%NAME%.exe

:: Get Game and Version
if "%NAME%" equ "AxiomVerge" set GAME=AV1
if "%NAME%" equ "AxiomVerge2" set GAME=AV2
for /f %%i in ('powershell "(gi ../AxiomVerge.exe).VersionInfo.ProductVersion"') do set GAMEVERSION=%%i
set REPO=!GAME!-!GAMEVERSION!

:: Do certain steps only once
IF NOT EXIST %REPO%\ (

:: Install IlSpyCmd
dotnet tool install --global ilspycmd --version 7.1.0.6543

:: Decompile executable
mkdir %REPO%
ilspycmd ../%EXEC% -o %REPO% -p -lv CSharp7_3

:: Backup original executable
mkdir backup
IF NOT EXIST backup\%EXEC% copy ..\%EXEC% backup\%GAME%-%GAMEVERSION%.exe

:: Restore project
dotnet restore %REPO%

:: Change build directory to original directory for convienience in vs
set BRANCH=$^(^[System.IO.File^]::ReadAlltext^('$^(GitRoot^)\.git\HEAD'^).Replace^('ref: refs/heads/', ''^).Trim^(^)^)
for /F "tokens=*" %%i in (%REPO%\%NAME%.csproj) do (
if not "%%i" equ "<TargetFramework>net40</TargetFramework>" if not "%%i" equ "<TargetFramework>net45</TargetFramework>" echo %%i
if "%%i" equ "<AssemblyName>%GAME%-%GAMEVERSION%-%BRANCH%</AssemblyName>" (echo ^<OutDir^>../../^</OutDir^> & echo ^<TargetFramework^>net481^</TargetFramework^>)) >> temp.txt
move /y temp.txt %REPO%\%NAME%.csproj

:: Unzip the EmbeddedContent Files
cd %REPO%/OuterBeyond
mkdir EmbeddedContent.Content
cd EmbeddedContent.Content
tar -xf ../EmbeddedContent.Content.zip
cd ../../../

:: Initialize Repository for patches
git init %REPO%
(echo /bin/ & echo /obj/ & echo /.vs/ & echo /%NAME%.sln & echo /%NAME%.csproj.user & echo /OuterBeyond/EmbeddedContent.Content.zip) > %REPO%\.gitignore
git -C %REPO% add -A
git -C %REPO% commit -m "Initialized Repo"
git -C %REPO% tag "Untouched" HEAD


if "%NAME%" equ "AxiomVerge" (git -C %REPO% apply -C 1 --recount --reject --ignore-whitespace ../startAV1.diff)
if "%NAME%" equ "AxiomVerge2" (git -C %REPO% apply -C 1 --recount --reject --ignore-whitespace ../startAV2.diff)
git -C %REPO% add -A
git -C %REPO% commit -m "Compileable Repo"
git -C %REPO% tag "Start" HEAD)

echo Finished
timeout 5