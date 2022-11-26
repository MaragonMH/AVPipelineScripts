# Get Game and Version
if ($NAME -eq "AxiomVerge"){ $GAME="AV1" }
if ($NAME -eq "AxiomVerge2"){ $GAME="AV2" }
$GAMEVERSION = "V$((Get-Item ../AxiomVerge*.exe).VersionInfo.ProductVersion)"
$REPO = "$GAME-$GAMEVERSION"

# Execute initialize script because it was not 
if (!(Test-Path $REPO\)){ & .\initialize.ps1 }

# Apply patches
Get-Item *.patch | ForEach-Object{
	$PATCHMODNAME = $_.BaseName.Split("-")[1]
	$PATCHMODVERSION = $_.BaseName.Split("-")[2]
	git -C $REPO checkout master
	git -C $REPO apply -C 1 --recount --reject --ignore-whitespace ../$_.Name
	git -C $REPO checkout -b $PATCHMODNAME
	git -C $REPO add -A
	git -C $REPO commit -m "New Mod $PATCHMODNAME at $PATCHMODVERSION"
	git -C $REPO tag $PATCHMODVERSION HEAD
}

# Zip EmbeddedContents.zip
Compress-Archive -f $REPO/OuterBeyond/EmbeddedContent.Content/* $REPO/OuterBeyond/EmbeddedContent.Content.zip

# Build source
dotnet build $REPO

Write-Output "Finished. Check for errors above. Warnings are ok"
timeout 5