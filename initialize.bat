@echo off
echo This Script will take a few minutes to complete

:: Get Executeable
for /f %%i in ('dir /b ..\*.exe') do set NAME=%%~ni
set EXEC=%NAME%.exe 

:: Do certain steps only once
IF NOT EXIST temp\ (

:: Install IlSpyCmd
dotnet tool install --global ilspycmd --version 7.1.0.6543

:: Decompile executable
mkdir temp
ilspycmd ../%EXEC% -o temp -p -lv CSharp7_3

:: Backup original executable
mkdir backup
IF NOT EXIST backup\%EXEC% copy ..\%EXEC% backup

:: Restore project
dotnet restore temp

:: Change build directory to original directory for convienience in vs
for /F "tokens=*" %%i in (temp\%NAME%.csproj) do (
if not "%%i" equ "<TargetFramework>net40</TargetFramework>" if not "%%i" equ "<TargetFramework>net45</TargetFramework>" (echo %%i)
if "%%i" equ "<AssemblyName>%NAME%</AssemblyName>" (echo ^<OutDir^>../../^</OutDir^> & echo ^<TargetFramework^>net481^</TargetFramework^>)) >> temp.txt
move /y temp.txt temp\%NAME%.csproj

:: Unzip the EmbeddedContent Files
cd temp/OuterBeyond
mkdir EmbeddedContent.Content
cd EmbeddedContent.Content
tar -xf ../EmbeddedContent.Content.zip
cd ../../../

:: Initialize Repository for patches
git init temp
(echo /bin/ & echo /obj/ & echo /.vs/ & echo /%NAME%.sln & echo /%NAME%.csproj.user & echo /OuterBeyond/EmbeddedContent.Content.zip) > temp\.gitignore
git -C temp add -A
git -C temp commit -m "Initialized Repo"
git -C temp tag "Untouched" HEAD

if "%NAME%" equ "AxiomVerge" (
git -C temp apply -C 1 --recount --reject --ignore-whitespace ../startAV1.diff 
git -C temp add -A
git -C temp commit -m "Compileable Repo")
git -C temp tag "Start" HEAD)

echo Finished
timeout 5