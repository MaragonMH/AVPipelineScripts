# Get Game and Version
if ($Name -eq "AxiomVerge"){ $Game="AV1" }
if ($Name -eq "AxiomVerge2"){ $Game="AV2" }
$Gameversion = "$((Get-Item ../AxiomVerge*.exe).VersionInfo.ProductVersion)"
$Repo = "$Game-$Gameversion"

# Execute initialize script because it was not 
if (!(Test-Path $Repo\)){ & .\initialize.ps1 }

# Apply patches
Get-Item *.patch | ForEach-Object{
	$PatchModname = $_.BaseName.Split("-")[1]
	$PatchModversion = $_.BaseName.Split("-")[2]
	git -C $Repo checkout master
	git -C $Repo apply -C 1 --recount --reject --ignore-whitespace ../$_.Name
	git -C $Repo checkout -b $PatchModname
	git -C $Repo add -A
	git -C $Repo commit -m "New Mod $PatchModname at $PatchModversion"
	git -C $Repo tag $PatchModversion HEAD
}

# Zip EmbeddedContents.zip
Compress-Archive -f $Repo/OuterBeyond/EmbeddedContent.Content/* $Repo/OuterBeyond/EmbeddedContent.Content.zip

# Build source
dotnet build $Repo

Write-Output "Finished. Check for errors above. Warnings are ok"
timeout 5