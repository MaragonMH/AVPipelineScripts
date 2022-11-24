@echo off

:: Apply patches
for /f %%i in ('dir /b *.patch') do (echo Applying patch: %%~ni
git -C temp checkout master
git -C temp apply -C 1 --recount --reject --ignore-whitespace ../%%~ni.patch
git -C temp checkout -b %%~ni
git -C temp add -A
git -C temp commit -m New%%~ni)

:: Zip EmbeddedContents.zip
powershell Compress-Archive -f temp/OuterBeyond/EmbeddedContent.Content/* temp/OuterBeyond/EmbeddedContent.Content.zip

:: Build source
dotnet build temp

@echo off
echo Finished. Check for errors above. Warnings are ok
timeout 5