# This file used for generation
# Get Executeable
if (!(Test-Path AxiomVerge*.exe)) { Write-Error "DirectoryError: This directory is not the game directory" -ErrorAction Stop}
$NAME = (Get-ChildItem AxiomVerge*.exe).BaseName
$EXEC = "$NAME.exe"

# Get Game and Version
if ($NAME -eq "AxiomVerge"){ $GAME="AV1" }
if ($NAME -eq "AxiomVerge2"){ $GAME="AV2" }
$GAMEVERSION = "V$((Get-Item "AxiomVerge*.exe").VersionInfo.ProductVersion)"

# Get Platform (Steam/Epic)
if (Test-Path CSteamworks.bundle/) { $PLATFORM="Steam" }
else { $PLATFORM="Epic" }

# Check for updates
$CURRENTREMOTEGAMEVERSION = "V0.0.0.0"
$CURRENTREMOTEMODVERSION = "V0.0.0"
$RESULT = Invoke-WebRequest "https://api.github.com/repos/MaragonMH/AxiomVergeMods/contents"
if($RESULT.StatusCode -ne 200) { Write-Error "FetchError: Something went wrong while fetching the download" -ErrorAction Stop }
$RESULT.Content | ConvertFrom-Json | ForEach-Object{
	$REMOTEFULLNAME = $_.name -replace ".{4}$"
	$REMOTEGAME = $REMOTEFULLNAME.Split("-")[0]
	$REMOTEMODNAME = $REMOTEFULLNAME.Split("-")[1]
	$REMOTEMODVERSION = $REMOTEFULLNAME.Split("-")[2]
	$REMOTEPLATFORM = $REMOTEFULLNAME.Split("-")[3]
	$REMOTEGAMEVERSION = $REMOTEFULLNAME.Split("-")[4]
}
Write-Error "OutdatedGameError: Your game is outdated for the mod you are requesting" -ErrorAction Stop
Write-Error "OutdatedModError: Your mod is outdated" -ErrorAction Stop

# Download newer version if available
if($OUTDATED){
	$RESULT = Invoke-WebRequest -Uri "https://raw.githubusercontent.com/MaragonMH/AxiomVergeMods/$NEWFULLNAME.zip" -OutFile "$NEWFULLNAME.zip"
	if($RESULT.StatusCode -ne 200) { Write-Error "DownloadError: Something went wrong during the download" -ErrorAction Stop }
}

# Check required files
if (!(Test-Path "bspatch.exe" -and (Test-Path "steam_appid.txt" -and $PLATFORM -eq "Steam"))){ 
	Write-Error "DownloadError: The download did not contain all required files" -ErrorAction Stop
}

# Define Errors
$ERRORS = @("None", "PatchFileError", "GameError", "PlatformError", "GameVersionError", "ModNameError")
$ERRORLEVEL = $ERRORS.IndexOf("PatchFileError")

# Get Patch
$CURRENTMODVERSION = "V0.0.0"
(Get-Item *.patch).BaseName | ForEach-Object{
	$PATCHGAME = $_.Split("-")[0]
	$PATCHMODNAME = $_.Split("-")[1]
	$PATCHMODVERSION = $_.Split("-")[2]
	$PATCHPLATFORM = $_.Split("-")[3]
	$PATCHGAMEVERSION = $_.Split("-")[4]

	# Check for Errors
	if($GAME -ne $PATCHGAME){ continue }
	$ERRORLEVEL = (($ERRORLEVEL, $ERRORS.IndexOf("GameError") | Measure-Object -Max).Maximum)
	if($PLATFORM -ne $PATCHPLATFORM){ continue }
	$ERRORLEVEL = (($ERRORLEVEL, $ERRORS.IndexOf("PlatformError") | Measure-Object -Max).Maximum)
	if($GAMEVERSION -ne $PATCHGAMEVERSION){ continue }
	$ERRORLEVEL = (($ERRORLEVEL, $ERRORS.IndexOf("GameVersionError") | Measure-Object -Max).Maximum)
	if(GENERATED-PARAMETER-MODNAME -ne $PATCHMODNAME){ continue }
	$ERRORLEVEL = (($ERRORLEVEL, $ERRORS.IndexOf("ModNameError") | Measure-Object -Max).Maximum)

	# Check Mod Version
	if($CURRENTMODVERSION.Split(".")[0].Replace("V", "") -lt $PATCHMODVERSION.Split(".")[0].Replace("V", "")){ $CURRENTMODVERSION = $PATCHMODVERSION; continue }
	if($CURRENTMODVERSION.Split(".")[0].Replace("V", "") -gt $PATCHMODVERSION.Split(".")[0].Replace("V", "")){ continue }
	if($CURRENTMODVERSION.Split(".")[1] -lt $PATCHMODVERSION.Split(".")[1]){ $CURRENTMODVERSION = $PATCHMODVERSION; continue }
	if($CURRENTMODVERSION.Split(".")[1] -gt $PATCHMODVERSION.Split(".")[1]){ continue }
	if($CURRENTMODVERSION.Split(".")[2] -lt $PATCHMODVERSION.Split(".")[2]){ $CURRENTMODVERSION = $PATCHMODVERSION; continue }
	
}

# Error Handling
if ($ERRORS[$ERRORLEVEL] -eq "PatchFileError"){ Write-Error "PatchFileError: This directory contains no *.patch file." -ErrorAction Stop }
if ($ERRORS[$ERRORLEVEL] -eq "GameError"){ Write-Error "GameError: Difference between Patch ($PATCHGAME) and Game ($GAME)." -ErrorAction Stop }
if ($ERRORS[$ERRORLEVEL] -eq "PlatformError"){ Write-Error "PlatformError: Difference between Patch ($PATCHPLATFORM) and Game ($PLATFORM)." -ErrorAction Stop }
if ($ERRORS[$ERRORLEVEL] -eq "GameVersionError"){ Write-Error "GameVersionError: Difference between Patch ($PATCHGAMEVERSION) and Game ($GAMEVERSION)" -ErrorAction Stop }
if ($ERRORS[$ERRORLEVEL] -eq "ModNameError"){ Write-Error "ModNameError: Patch file for this mod does not exist (GENERATED-PARAMETER-MODNAME)." -ErrorAction Stop }

# Generate
$FULLNAME = "$GAME-GENERATED-PARAMETER-MODNAME-$CURRENTMODVERSION-$PLATFORM-$GAMEVERSION"

# Execute
try { bspatch.exe "$EXEC $FULLNAME.exe $FULLNAME.patch" }
catch { Write-Error "UnexpectedError: An unexpected error occured during the patch process." -ErrorAction Stop}
Write-Output "Sucessfully applied $FULLNAME.patch to $EXEC".
Write-Output "Open $FULLNAME.exe to start your new mod"