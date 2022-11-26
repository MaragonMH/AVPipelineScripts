Param([Parameter(Mandatory=$False)][string]$GITDIRECTORY = "")
# PARAMETER(COUNT 1): String : GIT-Directory : Default(CurrentVersion)
# Use this when you want to create a patch from an older version.
# Example: imagine that your current Version of AV1 is 1.58.0.0 but you already developed a mod for 1.57.0.0
# Now you can supply AV1-1.57.0.0 to publish all the files from the old active branch

# Get Executeable
$NAME = (Get-ChildItem ..\AxiomVerge*.exe).BaseName
$EXEC = "$NAME.exe"

# Get Game and Version
if ($NAME -eq "AxiomVerge"){ $GAME="AV1" }
if ($NAME -eq "AxiomVerge2"){ $GAME="AV2" }
$GAMEVERSION = "V$((Get-Item ../AxiomVerge*.exe).VersionInfo.ProductVersion)"
$REPO = "$GAME-$GAMEVERSION"

# Get Platform (Steam/Epic)
if (Test-Path ../CSteamworks.bundle/) { $PLATFORM="Steam" }
else { $PLATFORM="Epic" }

# Execute build script because it was not or use legacy directory
if (!(Test-Path $REPO\)){ & .\build.ps1 }
if (($GITDIRECTORY -ne "") -and (Test-Path $GITDIRECTORY\)){ $REPO = $GITDIRECTORY }
else{ Write-Error "ERROR: Your supplied directory does not exist" -ErrorAction Stop }

# Get ModName and ModVersion
$MODNAME = git -C $REPO rev-parse --abbrev-ref HEAD
$LASTMODVERSION = git -C $REPO describe --tags
$MODVERSION = git -C $REPO describe --tags --exact-match

# Determine new ModVersion
if ($LASTMODVERSION -eq $MODVERSION) {
	if ($MODVERSION -eq "Start"){ $MODVERSION = "V0.0.0" }
	else{
		if($LASTMODVERSION -eq "Start"){
			$MODVERSION = "V0.0.1"
			git -C $REPO tag "V0.0.1" HEAD
}}}
# Increment existing Version
else {
	$MODVERSION = $MODVERSION.Split(".")
	$MODVERSION[2] = [int]$MODVERSION[2] + 1
	$MODVERSION = $MODVERSION -join "."
	git -C $REPO tag $MODVERSION HEAD
}

$FULLNAME="$GAME-$MODNAME-$MODVERSION-$PLATFORM-$GAMEVERSION"

# Create Publish-Folder
Remove-Item mods\$FULLNAME -Recurse -Force
New-Item mods\$FULLNAME -ItemType Directory
New-Item mods\$FULLNAME\Code -ItemType Directory

# General Files
Copy-Item mods\*.* mods\$FULLNAME\ -Exclude applyPatch-.ps1, bsdiff.exe 

# Custom files
(Get-Content mods\applyPatch-.ps1).Replace("GENERATED-PARAMETER-MODNAME", $MODNAME) | 
	Out-File "mods\$FULLNAME\applyPatch-$MODNAME.patch"

"Install: run applyPatch-$MODNAME.bat as Admin`r`nLook out for Errors and seek help in the discord modding channel." |
	Out-File "mods\$FULLNAME\READ-$MODNAME.txt"

if ($NAME -eq "AxiomVerge") { "332200" | Out-File mods\$FULLNAME\steam_appid.txt }
if ($NAME -eq "AxiomVerge2") { "946030" | Out-File mods\$FULLNAME\steam_appid.txt }

git -C $REPO diff Start..HEAD | Out-File "mods\$FULLNAME\Code\$FULLNAME.patch"
mods\bsdiff.exe backup\$EXEC | Out-File "..\$EXEC mods\$FULLNAME\$FULLNAME.patch"

# Create Zip
powershell Compress-Archive -f mods/$FULLNAME/* mods/$FULLNAME/$FULLNAME.zip

timeout 5