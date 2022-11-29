Param([Parameter(Mandatory=$False)][string]$Gitdirectory = "")
# PARAMETER(COUNT 1): String : GIT-Directory : Default(CurrentVersion)
# Use this when you want to create a patch from an older version.
# Example: imagine that your current Version of AV1 is 1.58.0.0 but you already developed a mod for 1.57.0.0
# Now you can supply AV1-1.57.0.0 to publish all the files from the old active branch

# Get Executeable
$Name = (Get-ChildItem ..\AxiomVerge*.exe).BaseName
$Exec = "$Name.exe"

# Get Game and Version
if ($Name -eq "AxiomVerge"){ $Game="AV1" }
if ($Name -eq "AxiomVerge2"){ $Game="AV2" }
$Gameversion = "$((Get-Item ../AxiomVerge*.exe).VersionInfo.ProductVersion)"
$Repo = "$Game-$Gameversion"

# Get Platform (Steam/Epic)
if (Test-Path ../CSteamworks.bundle/) { $Platform="Steam" }
else { $Platform="Epic" }

# Execute build script because it was not or use legacy directory
if (!(Test-Path $Repo\)){ & .\build.ps1 }
if (($Gitdirectory -ne "") -and (Test-Path $Gitdirectory\)){ $Repo = $Gitdirectory }
else{ Write-Error "ERROR: Your supplied directory does not exist" -ErrorAction Stop }

# Get ModName and ModVersion
$Modname = git -C $Repo rev-parse --abbrev-ref HEAD
$LastModversion = git -C $Repo describe --tags
$Modversion = git -C $Repo describe --tags --exact-match

# Determine new ModVersion
if ($LastModversion -eq $Modversion) {
	if ($Modversion -eq "Start"){ $Modversion = "0.0.0" }
	else{
		if($LastModversion -eq "Start"){
			$Modversion = "0.0.1"
			git -C $Repo tag "0.0.1" HEAD
}}}
# Increment existing Version
else {
	$Modversion = $Modversion.Split(".")
	$Modversion[2] = [int]$Modversion[2] + 1
	$Modversion = $Modversion -join "."
	git -C $Repo tag $Modversion HEAD
}

$Fullname="$Game-$Modname-$Modversion-$Platform-$Gameversion"

# Create Publish-Folder
Remove-Item mods\$Fullname -Recurse -Force
New-Item mods\$Fullname -ItemType Directory
New-Item mods\$Fullname\Code -ItemType Directory

# General Files
Copy-Item mods\*.* mods\$Fullname\ -Exclude applyPatch-.ps1, bsdiff.exe 

# Custom files
(Get-Content mods\applyPatch-.ps1).Replace("GENERATED-PARAMETER-MODNAME", $Modname) | 
	Out-File "mods\$Fullname\applyPatch-$Modname.patch"

"Install: run applyPatch-$Modname.bat as Admin`r`nLook out for Errors and seek help in the discord modding channel." |
	Out-File "mods\$Fullname\READ-$Modname.txt"

if ($Name -eq "AxiomVerge") { "332200" | Out-File mods\$Fullname\steam_appid.txt }
if ($Name -eq "AxiomVerge2") { "946030" | Out-File mods\$Fullname\steam_appid.txt }

git -C $Repo diff Start..HEAD | Out-File "mods\$Fullname\Code\$Fullname.patch"
mods\bsdiff.exe backup\$Exec | Out-File "..\$Exec mods\$Fullname\$Fullname.patch"

# Create Zip
powershell Compress-Archive -f mods/$Fullname/* mods/$Fullname/$Fullname.zip

timeout 5