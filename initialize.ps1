Write-Output "This Script will take a few minutes to complete"

# Get Executeable
$Name = (Get-ChildItem ..\AxiomVerge*.exe).BaseName
$Exec = "$Name.exe"

# Get Game and Version
if ($Name -eq "AxiomVerge"){ $Game="AV1" }
if ($Name -eq "AxiomVerge2"){ $Game="AV2" }
$Gameversion = "$((Get-Item ../AxiomVerge*.exe).VersionInfo.ProductVersion)"
$Repo = "$Game-$Gameversion"

# Do certain steps only once
if (!(Test-Path $Repo)){

	# Install IlSpyCmd
	dotnet tool install --global ilspycmd --version 7.1.0.6543

	# Decompile executable
	New-Item $Repo -ItemType Directory
	ilspycmd ../$Exec -o $Repo -p -lv CSharp7_3

	# Backup original executable
	if (!(Test-Path backup\)){ New-Item backup -ItemType Directory }
	if (!(Test-Path backup\$Exec)){ Copy-Item ..\$Exec "backup\$Game-$Gameversion.exe" }

	# Restore project
	dotnet restore $Repo

	# Change build directory to original directory for convienience in vs
	$Branch = '$([System.IO.File]::ReadAlltext("$(GitRoot)\.git\HEAD").Replace("ref: refs/heads/", "").Trim())'
	$FileContent = Get-Content "$Repo\$Name.csproj"
	$FileContent = $FileContent.Replace("<TargetFramework>net40</TargetFramework>", "<TargetFramework>net481</TargetFramework>")
	$FileContent = $FileContent.Replace("<TargetFramework>net45</TargetFramework>", "<TargetFramework>net481</TargetFramework>")
	$FileContent = $FileContent.Replace("<LangVersion>7.3</LangVersion>", "<LangVersion>latest</LangVersion>")
	$FileContent = $FileContent.Replace("<AssemblyName>$Name</AssemblyName>", "<AssemblyName>$Game-$Gameversion-$Branch</AssemblyName>`r`n<OutDir>../../</OutDir>")
	$FileContent | Out-File "$Repo\$Name.csproj"

	# Unzip the EmbeddedContent Files
	Set-Location $Repo/OuterBeyond
	if (!(Test-Path EmbeddedContent.Content\)){ New-Item EmbeddedContent.Content -ItemType Directory }
	Set-Location EmbeddedContent.Content
	tar -xf ../EmbeddedContent.Content.zip
	Set-Location ../../../

	# Initialize Repository for patches
	git init $Repo
	"/bin/`r`n/obj/`r`n/.vs/`r`n/*.sln`r`n/*.csproj.user`r`n/OuterBeyond/EmbeddedContent.Content.zip`r`n*.rej" | Out-File $Repo\.gitignore
	git -C $Repo add -A
	git -C $Repo commit -m "Initialized Repo"
	git -C $Repo tag "Untouched" HEAD


	if ($Name -eq "AxiomVerge") { git -C $Repo apply -C 1 --recount --reject --ignore-whitespace ../startAV1.diff }
	if ($Name -eq "AxiomVerge2") { git -C $Repo apply -C 1 --recount --reject --ignore-whitespace ../startAV2.diff }
	git -C $Repo add -A
	git -C $Repo commit -m "Compileable Repo"
	git -C $Repo tag "Start" HEAD
}

Write-Output "Finished"
timeout 5