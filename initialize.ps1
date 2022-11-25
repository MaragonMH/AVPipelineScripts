Write-Output This Script will take a few minutes to complete

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
	New-ITEM $REPO
	ilspycmd ../$EXEC -o $REPO -p -lv CSharp7_3

	# Backup original executable
	New-ITEM backup
	if (!(Test-Path backup\$EXEC)){ Copy-Item ..\$EXEC backup\$GAME-$GAMEVERSION.exe }

	# Restore project
	dotnet restore $REPO

	# Change build directory to original directory for convienience in vs
	$BRANCH = '$([System.IO.File]::ReadAlltext("$(GitRoot)\.git\HEAD").Replace("ref: refs/heads/", "").Trim())'
	$FILECONTENT = Get-Content $REPO\$Name.csproj
	$FILECONTENT = $FILECONTENT.Replace("<TargetFramework>net40</TargetFramework>", "<TargetFramework>net481</TargetFramework>")
	$FILECONTENT = $FILECONTENT.Replace("<TargetFramework>net45</TargetFramework>", "<TargetFramework>net481</TargetFramework>")
	$FILECONTENT = $FILECONTENT.Replace("<LangVersion>7.3</LangVersion>", "<LangVersion>latest</LangVersion>")
	$FILECONTENT = $FILECONTENT.Replace("<AssemblyName>$GAME-$GAMEVERSION-$BRANCH</AssemblyName>", "<AssemblyName>$GAME-$GAMEVERSION-$BRANCH</AssemblyName>")
	$FILECONTENT | Set-Content $REPO\$Name.csproj

	for /F "tokens=*" %%i in (%REPO%\%NAME%.csproj) do (
	if not "%%i" equ  if not "%%i" equ "<TargetFramework>net45</TargetFramework>" if not "%%i" equ "<LangVersion>7.3</LangVersion>" (echo %%i
	) else echo <LangVersion>latest</LangVersion>
	if "%%i" equ "<AssemblyName>%GAME%-%GAMEVERSION%-%BRANCH%</AssemblyName>" (echo ^<OutDir^>../../^</OutDir^> & echo ^<TargetFramework^>net481^</TargetFramework^>)) >> temp.txt
	Move-Item /y temp.txt %REPO%\%NAME%.csproj

	:: Unzip the EmbeddedContent Files
	cd %REPO%/OuterBeyond
	mkdir EmbeddedContent.Content
	cd EmbeddedContent.Content
	tar -xf ../EmbeddedContent.Content.zip
	cd ../../../

	:: Initialize Repository for patches
	git init %REPO%
	(echo /bin/ & echo /obj/ & echo /.vs/ & echo /%NAME%.sln & echo /%NAME%.csproj.user & echo /OuterBeyond/EmbeddedContent.Content.zip) > %REPO%\.gitignore
	git -C %REPO% add -A
	git -C %REPO% commit -m "Initialized Repo"
	git -C %REPO% tag "Untouched" HEAD


	if ($NAME -eq "AxiomVerge") { git -C %REPO% apply -C 1 --recount --reject --ignore-whitespace ../startAV1.diff }
	if ($NAME -eq "AxiomVerge2") { git -C %REPO% apply -C 1 --recount --reject --ignore-whitespace ../startAV2.diff }
	git -C %REPO% add -A
	git -C %REPO% commit -m "Compileable Repo"
	git -C %REPO% tag "Start" HEAD
}

Write-Output Finished
timeout 5