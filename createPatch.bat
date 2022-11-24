:: Get Executeable
for /f %%i in ('dir .. /b *.exe') do set NAME=%%~ni
set EXEC=%NAME%.exe 

for /f %%i in ('git -C temp rev-parse --abbrev-ref HEAD') do set VAR=%%i
rmdir /q /s mods\%VAR%
mkdir mods\%VAR%
mkdir mods\%VAR%\Code
copy mods\removePatchFinal.bat mods\%VAR%\removePatchFinal.bat
copy mods\READ.txt mods\%VAR%\READ-%VAR%.txt
copy mods\bsdiff.exe mods\%VAR%\bsdiff.exe
copy mods\bspatch.exe mods\%VAR%\bspatch.exe
copy mods\LICENSE mods\%VAR%\LICENSE
copy "mods\EOSSDK-Win32-Shipping.dll" "mods\%VAR%\EOSSDK-Win32-Shipping.dll"
copy "mods\EOSSDK-Win64-Shipping.dll" "mods\%VAR%\EOSSDK-Win64-Shipping.dll"
(echo ren %EXEC% Old%EXEC%
echo bspatch.exe Old%EXEC% %EXEC% %VAR%.patch
) > mods\%VAR%\applyPatch%VAR%.bat
(echo copy Old%EXEC% %EXEC%
) > mods\%VAR%\removePatchFinal.bat
(echo Install: run applyPatch%VAR%.bat as Admin
echo Uninstall: run removePatchFinal.bat
) > mods\%VAR%\READ-%VAR%.txt
git -C temp diff Start..HEAD > mods\%VAR%\Code\%VAR%.patch
mods\bsdiff.exe backup\%EXEC% ..\%EXEC% mods\%VAR%\%VAR%.patch
timeout 5