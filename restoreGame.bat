@echo off

:: Get Executeable
for /f %%i in ('dir /b ..\AxiomVerge*.exe') do set NAME=%%~ni
set EXEC=%NAME%.exe

copy /y backup\%EXEC% ..\%EXEC%
rmdir /s temp
timeout 5