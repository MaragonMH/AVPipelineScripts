Write-Output "This Script will take a few minutes to complete"

# Get Executeable
$NAME = (Get-ChildItem ..\AxiomVerge*.exe).BaseName
$EXEC = ($NAME + ".exe")

# Get Game and Version
if ($NAME -eq "AxiomVerge"){ $GAME="AV1" }
if ($NAME -eq "AxiomVerge2"){ $GAME="AV2" }
$GAMEVERSION = (Get-Item ../AxiomVerge.exe).VersionInfo.ProductVersion
$REPO = ("$GAME-$GAMEVERSION")

# Do certain steps only once
if (!(Test-Path $REPO)){

	# Install IlSpyCmd
	dotnet tool install --global ilspycmd --version 7.1.0.6543

	# Decompile executable
	New-Item $REPO -ItemType Directory
	ilspycmd ../$EXEC -o $REPO -p -lv CSharp7_3

	# Backup original executable
	if (!(Test-Path backup)){ New-Item backup -ItemType Directory }
	if (!(Test-Path backup\$EXEC)){ Copy-Item ..\$EXEC backup\$GAME-$GAMEVERSION.exe }

	# Restore project
	dotnet restore $REPO

	# Change build directory to original directory for convienience in vs
	$BRANCH = '$([System.IO.File]::ReadAlltext("$(GitRoot)\.git\HEAD").Replace("ref: refs/heads/", "").Trim())'
	$FILECONTENT = Get-Content $REPO\$Name.csproj
	$FILECONTENT = $FILECONTENT.Replace("<TargetFramework>net40</TargetFramework>", "<TargetFramework>net481</TargetFramework>")
	$FILECONTENT = $FILECONTENT.Replace("<TargetFramework>net45</TargetFramework>", "<TargetFramework>net481</TargetFramework>")
	$FILECONTENT = $FILECONTENT.Replace("<LangVersion>7.3</LangVersion>", "<LangVersion>latest</LangVersion>")
	$FILECONTENT = $FILECONTENT.Replace("<AssemblyName>$NAME</AssemblyName>", "<AssemblyName>$GAME-$GAMEVERSION-$BRANCH</AssemblyName>`r`n<OutDir>../../</OutDir>")
	$FILECONTENT | Set-Content $REPO\$Name.csproj

	# Unzip the EmbeddedContent Files
	Set-Location $REPO/OuterBeyond
	if (!(Test-Path EmbeddedContent.Content)){ New-Item EmbeddedContent.Content -ItemType Directory }
	Set-Location EmbeddedContent.Content
	tar -xf ../EmbeddedContent.Content.zip
	Set-Location ../../../

	# Initialize Repository for patches
	git init $REPO
	"/bin/`r`n/obj/`r`n/.vs/`r`n/*.sln`r`n/*.csproj.user`r`n/OuterBeyond/EmbeddedContent.Content.zip" | Out-File $REPO\.gitignore
	git -C $REPO add -A
	git -C $REPO commit -m "Initialized Repo"
	git -C $REPO tag "Untouched" HEAD


	if ($NAME -eq "AxiomVerge") { git -C $REPO apply -C 1 --recount --reject --ignore-whitespace ../startAV1.diff }
	if ($NAME -eq "AxiomVerge2") { git -C $REPO apply -C 1 --recount --reject --ignore-whitespace ../startAV2.diff }
	git -C $REPO add -A
	git -C $REPO commit -m "Compileable Repo"
	git -C $REPO tag "Start" HEAD
}

Write-Output "Finished"
timeout 5