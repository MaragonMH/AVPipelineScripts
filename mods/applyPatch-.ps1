# This file is used for generation
# Get Executeable
$Name = (Get-ChildItem ..\AxiomVerge*.exe).BaseName
$Exec = "$Name.exe"

# Get Game and Version
if ($Name -eq "AxiomVerge"){ $Game="AV1" }
if ($Name -eq "AxiomVerge2"){ $Game="AV2" }
$Gameversion = "$((Get-Item ../AxiomVerge*.exe).VersionInfo.ProductVersion)"

# Get Platform (Steam/Epic)
if (Test-Path ../CSteamworks.bundle/) { $Platform="Steam" }
else { $Platform="Epic" }

# Get current version
$Candidates = (Get-Item "$Game-GENERATED-PARAMETER-MODNAME-*-$Platform-*.exe").BaseName
if($Candidates.Length -le 0) { $Candidates = (Get-Item "$Game-GENERATED-PARAMETER-MODNAME-*-$Platform-*.patch").BaseName}
$Fullname = ($Candidates | Sort-Object { [version]($_.Split("-")[4])}, {[version]($_.Split("-")[2])})[-1]

# Get most recent online version
$Result = Invoke-WebRequest "https://api.github.com/repos/MaragonMH/AxiomVergeMods/contents"
if($Result.StatusCode -ne 200) { Write-Output "FetchError: Something went wrong while fetching the download"; return 0 }
$Candidates = ($Result.Content | ConvertFrom-Json | Where-Object { $_.name.Split("-")[0] -eq $Game } | 
	Where-Object { $_.name.Split("-")[3] -eq $Platform } |
	Where-Object { $_.name.Split("-")[1] -eq "GENERATED-PARAMETER-MODNAME" } |
	ForEach-Object { $_.name.Replace(".zip", "")})
if($Candidates.Length -le 0) { Write-Output "FetchError: Something went wrong while fetching the download"; return 0 }
$NewFullname = ($Candidates | Sort-Object { [version]($_.Split("-")[4])}, {[version]($_.Split("-")[2])})[-1]

# If everything is up to date return success
if(($NewFullname -eq $Fullname) -and (Test-Path "$Fullname.exe")) { return 0 }

# If game is outdated return error
if(($NewFullname.Split("-")[4], $Fullname.Split("-")[4] | Sort-Object {[version] $_})[-1] -ne $Fullname.Split("-")[4]) { 
	Write-Error "OutdatedGameError: Your game is outdated please update your game first" -ErrorAction Stop }

# Else download new mod
$Result = Invoke-WebRequest -Uri "https://raw.githubusercontent.com/MaragonMH/AxiomVergeMods/$NewFullname.zip" -OutFile "$NewFullname.zip"
if($Result.StatusCode -ne 200) { Write-Error "DownloadError: Something went wrong during the download" -ErrorAction Stop }
# Unzip mod
Expand-Archive "$NewFullname.zip" -Force
Remove-Item "$NewFullname.zip" -Force
# Check required files
if (!(Test-Path "bspatch.exe" -and Test-Path "$NewFullname.patch" -and (Test-Path "steam_appid.txt" -and $Platform -eq "Steam"))){ 
	Write-Error "ModError: The mod did not contain all required files" -ErrorAction Stop
}

# Install new mod
try { bspatch.exe "$Exec $NewFullname.exe $NewFullname.patch" }
catch { Write-Error "UnexpectedError: An unexpected error occured during the patch process." -ErrorAction Stop}
Write-Output "Sucessfully applied $NewFullname.patch to $Exec".
Write-Output "Open $NewFullname.exe to start your new mod"
return 0