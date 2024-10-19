@echo off
setlocal enabledelayedexpansion

:: Define initial paths
set "CURRENT_DIR=%cd%"
set "INSTALL_DIR=install"
set "MOD_ORG_EXE=%INSTALL_DIR%\ModOrganizer.exe"
set "EXTRACT_DIR=class_extractor"
set "LSLIB_URL=https://github.com/Norbyte/lslib/releases/download/v1.19.5/ExportTool-v1.19.5.zip"
set "LSLIB_ZIP=%EXTRACT_DIR%\lslib.zip"
set "DIVINE=%CURRENT_DIR%\class_extractor\Packed\Tools\Divine.exe"
set "OUTPUT_FILE=%EXTRACT_DIR%\classlist.txt"
set "LSX_DIR=%EXTRACT_DIR%\lsx"
set "CLASSES_OUTPUT=%EXTRACT_DIR%\classes.txt"
set "ALL_OUTPUT=%EXTRACT_DIR%\all.txt"
set "TEMP_FILE=%EXTRACT_DIR%\temp_output.txt"

:: Get the absolute path of EXTRACT_DIR
set "EXTRACT_DIR=%CURRENT_DIR%\%EXTRACT_DIR%"

:: Check if .NET 8+ is installed
for /f "tokens=*" %%i in ('dotnet --list-runtimes') do (
    echo %%i | findstr "Microsoft.NETCore.App 8" >nul
    if %errorlevel%==0 set "found=true"
)

if "%found%"=="true" (
    echo Microsoft.NETCore.App version 8 or higher is installed.
) else (
    echo Microsoft.NETCore.App version 8 or higher is NOT installed.
	start https://dotnet.microsoft.com/en-us/download
	pause
	exit /b
)

:: Step 1: Use PowerShell to find ModOrganizer.exe or prompt the user for the correct folder
for /f "usebackq delims=" %%I in (`powershell -command ^
    "if (-Not (Test-Path '%MOD_ORG_EXE%')) {" ^
    "    Write-Host 'ModOrganizer.exe not found in the defined install folder (%INSTALL_DIR%).';" ^
    "    if (Test-Path 'ModOrganizer.exe') {" ^
    "        Write-Host 'Found ModOrganizer.exe in the current directory.';" ^
    "        (Get-Location).Path" ^
    "    } else {" ^
    "        Add-Type -AssemblyName System.Windows.Forms;" ^
    "        $fbd = New-Object System.Windows.Forms.FolderBrowserDialog;" ^
    "        $fbd.Description = 'Select the install folder containing ModOrganizer.exe';" ^
    "        if ($fbd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {" ^
    "            $selectedPath = (Resolve-Path $fbd.SelectedPath).Path;" ^
    "            if (Test-Path (Join-Path $selectedPath 'ModOrganizer.exe')) {" ^
    "                $selectedPath" ^
    "            } else {" ^
    "                Write-Host 'Error: The selected folder does not contain ModOrganizer.exe. Exiting...';" ^
    "                exit 1;" ^
    "            }" ^
    "        } else {" ^
    "            Write-Host 'No folder selected. Exiting...';" ^
    "            exit 1;" ^
    "        }" ^
    "    }" ^
    "} else {" ^
    "    (Resolve-Path '%INSTALL_DIR%').Path" ^
    "}"`) do (
    set "INSTALL_DIR=%%I"
)



:: Verify if the install folder was set correctly
set "MOD_ORG_EXE=%INSTALL_DIR%\ModOrganizer.exe"
if not exist "%MOD_ORG_EXE%" (
    echo Error: ModOrganizer.exe not found in the specified folder. Exiting...
    pause
    exit /b
)

:: Step 2: Locate the BG3 installation path by finding bg3.exe
set "BG3_EXE=%CURRENT_DIR%\bg3.exe"
if not exist "%BG3_EXE%" (
    echo bg3.exe not found in the default location. Please locate the BG3 installation folder.
    for /f "usebackq delims=" %%I in (`powershell -command ^
        "Add-Type -AssemblyName System.Windows.Forms;" ^
        "$fbd = New-Object System.Windows.Forms.OpenFileDialog;" ^
        "$fbd.Filter = 'BG3 Executable|bg3.exe';" ^
        "$fbd.Title = 'Locate bg3.exe';" ^
        "if ($fbd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { $fbd.FileName }"`) do (
        set "BG3_EXE=%%I"
    )
)

:: Verify that bg3.exe was selected
if not exist "%BG3_EXE%" (
    echo Error: bg3.exe not found. Exiting...
    pause
    exit /b
)

:: Extract the directory containing bg3.exe, then go up one folder to Baldurs Gate 3
for %%I in ("%BG3_EXE%") do set "BG3_DIR=%%~dpI"
set "BG3_DIR=%BG3_DIR:~0,-1%"  :: Remove the trailing backslash
for %%I in ("%BG3_DIR%") do set "BG3_INSTALL_DIR=%%~dpI"

:: Define the path for Shared.pak
set "SHARED_PAK=%BG3_INSTALL_DIR%Data\Shared.pak"

:: Verify if Shared.pak exists
if not exist "%SHARED_PAK%" (
    echo Error: Shared.pak not found in "%BG3_INSTALL_DIR%Baldurs Gate 3\Data". Exiting...
    pause
    exit /b
)

:: Step 2: Create class_extractor folder if it doesn't exist
if not exist "%EXTRACT_DIR%" (
    echo Creating class_extractor folder...
    mkdir "%EXTRACT_DIR%"
)

:: Step 3: Check if Divine.exe exists before downloading lslib
if not exist "%DIVINE%" (
    echo Divine.exe not found. Downloading the lslib.zip...
    curl -L --retry 3 --retry-delay 5 "%LSLIB_URL%" --output "%LSLIB_ZIP%"
    if %errorlevel% neq 0 (
        echo Error downloading lslib.zip. Exiting...
        pause
        exit /b
    )
    echo Download completed.

    :: Extract the downloaded lslib.zip
    echo Extracting lslib.zip...
    powershell -command "Expand-Archive -Path '%LSLIB_ZIP%' -DestinationPath '%EXTRACT_DIR%' -Force"
    if %errorlevel% neq 0 (
        echo Error extracting lslib.zip. Exiting...
        pause
        exit /b
    )
    echo lslib.zip extracted successfully.

    :: Clean up the downloaded zip file
    del "%LSLIB_ZIP%"
    echo lslib.zip removed.
) else (
    echo Divine.exe already exists, skipping download.
)

pause

:: Define paths based on the install folder
set "MODLIST=%INSTALL_DIR%\profiles\Listonomicon\modlist.txt"
echo %MODLIST%
set "MODFOLDER=%INSTALL_DIR%\mods"
echo %MODFOLDER%
set "EXTRACT_DIR=%CURRENT_DIR%\class_extractor"
echo %EXTRACT_DIR%
set "LSX_DIR=%EXTRACT_DIR%\lsx"
echo %LSX_DIR%
set "DIVINE=%CURRENT_DIR%\class_extractor\Packed\Tools\Divine.exe"
echo %DIVINE%
set "SHARED_PAK=G:\Program Files (x86)\Steam\steamapps\common\Baldurs Gate 3\Data\Shared.pak"

:: Proceed with extraction process if all paths are set correctly
:: Step 1: Extract Progressions.lsx from Shared.pak
if exist "%SHARED_PAK%" (
    echo Extracting Progressions.lsx from Shared.pak
    "%DIVINE%" -a extract-package -g bg3 -s "%SHARED_PAK%" -d "%LSX_DIR%" -x "*/Progressions.lsx" -l off

    :: Move the Progressions.lsx from Shared\Progressions
    if exist "%LSX_DIR%\Public\Shared\Progressions\Progressions.lsx" (
        echo Found Progressions.lsx in Shared\Progressions
        echo Moving Progressions.lsx to %LSX_DIR%\000_Shared.lsx
        move "%LSX_DIR%\Public\Shared\Progressions\Progressions.lsx" "%LSX_DIR%\000_Shared.lsx"
    ) else (
        echo No Progressions.lsx found in Shared\Progressions!
    )

    :: Move the Progressions.lsx from SharedDev\Progressions
    if exist "%LSX_DIR%\Public\SharedDev\Progressions\Progressions.lsx" (
        echo Found Progressions.lsx in SharedDev\Progressions
        echo Moving Progressions.lsx to %LSX_DIR%\000_SharedDev.lsx
        move "%LSX_DIR%\Public\SharedDev\Progressions\Progressions.lsx" "%LSX_DIR%\000_SharedDev.lsx"
    ) else (
        echo No Progressions.lsx found in SharedDev\Progressions!
    )
) else (
    echo Warning: Shared.pak not found!
    pause
)

:: Step 2: Read the mod list into an array and process it in reverse order
set "counter=1"
set "lineCount=0"

:: Read all lines into an array
for /f "tokens=* delims=" %%A in ('findstr /b /c:"+" "%MODLIST%"') do (
    set /a lineCount+=1
    set "modList[!lineCount!]=%%A"
)

:: Process the mod list in reverse order
for /l %%I in (%lineCount%,-1,1) do (
    set "MODNAME=!modList[%%I]!"
    set "MODNAME=!MODNAME:~1!"

    :: Pad counter with leading zeros to ensure three digits
    set "PADDED_COUNTER=00!counter!"
    set "PADDED_COUNTER=!PADDED_COUNTER:~-3!"

    :: Check if the folder exists in the mods directory
    if exist "%MODFOLDER%\!MODNAME!\" (
        echo Processing mod: !MODNAME!

        :: Check if PAK_FILES folder exists
        if exist "%MODFOLDER%\!MODNAME!\PAK_FILES\" (
            :: Find the pak file in the PAK_FILES folder
            for %%B in ("%MODFOLDER%\!MODNAME!\PAK_FILES\*.pak") do (
                echo Found pak file: %%B
                echo Attempting to extract Progressions.lsx from %%B
                "%DIVINE%" -a extract-package -g bg3 -s "%%B" -d "%LSX_DIR%" -x "*/Progressions.lsx" -l off

                :: Extract the base name of the pak file (without .pak)
                set "PAKNAME=%%~nB"

                :: Move the extracted Progressions.lsx to the mod-specific filename with a padded counter
                if exist "%LSX_DIR%\Public\!PAKNAME!\Progressions\Progressions.lsx" (
                    echo Found Progressions.lsx for !PAKNAME!
                    echo Moving Progressions.lsx to %LSX_DIR%\!PADDED_COUNTER!_!PAKNAME!.lsx
                    move "%LSX_DIR%\Public\!PAKNAME!\Progressions\Progressions.lsx" "%LSX_DIR%\!PADDED_COUNTER!_!PAKNAME!.lsx"
                    set /a counter+=1
                ) else (
                    echo No Progressions.lsx found for !PAKNAME!
                )
            )
        ) else (
            echo Warning: PAK_FILES folder not found for !MODNAME!
        )
    ) else (
        echo Warning: Mod folder not found for !MODNAME!
    )
)

:: Step 3: Clean up the Public folder at the end
if exist "%LSX_DIR%\Public" (
    echo Cleaning up Public folder...
    rd /s /q "%LSX_DIR%\Public"
)

:: Step 1: Clear the output files before starting
echo Processing LSX files in %LSX_DIR%...
> "%CLASSES_OUTPUT%" echo.
> "%ALL_OUTPUT%" echo.

:: First Pass: Extract names with ProgressionType 0 into classes.txt
echo Starting first pass to extract names with ProgressionType 0...
for %%f in ("%LSX_DIR%\*.lsx") do (
    if not "%%~nxf"=="001_CommunityLibrary.lsx" if not "%%~nxf"=="002_UtutsCoreLibrary.lsx" (
        echo Processing %%f for ProgressionType 0...
        powershell -NoProfile -Command ^
            "& { " ^
            "    [xml]$xml = Get-Content -LiteralPath \"%%~f\";" ^
            "    $nodes = $xml.save.region.node.children.node;" ^
            "    foreach ($node in $nodes) {" ^
            "        $name = ($node.attribute | Where-Object { $_.id -eq 'Name' }).value;" ^
            "        $progressionType = ($node.attribute | Where-Object { $_.id -eq 'ProgressionType' }).value;" ^
            "        if ($progressionType -eq '0' -and $name -ne '' -and -not ($name -like 'NPC_*' -or $name -like 'Origin_*' -or $name -like 'UCL_*' -or $name -eq 'MulticlassSpellSlots')) {" ^
            "            $name | Out-File -FilePath '%CLASSES_OUTPUT%' -Append -Encoding utf8;" ^
            "        }" ^
            "    }" ^
            "}"
    )
)

:: Second Pass: Extract names with ProgressionType 0 or 1 into all.txt
echo Starting second pass to extract names with ProgressionType 0 or 1...
for %%f in ("%LSX_DIR%\*.lsx") do (
    if not "%%~nxf"=="001_CommunityLibrary.lsx" if not "%%~nxf"=="002_UtutsCoreLibrary.lsx" (
        echo Processing %%f for ProgressionType 0 or 1...
        powershell -NoProfile -Command ^
            "& { " ^
            "    [xml]$xml = Get-Content -LiteralPath \"%%~f\";" ^
            "    $nodes = $xml.save.region.node.children.node;" ^
            "    foreach ($node in $nodes) {" ^
            "        $name = ($node.attribute | Where-Object { $_.id -eq 'Name' }).value;" ^
            "        $progressionType = ($node.attribute | Where-Object { $_.id -eq 'ProgressionType' }).value;" ^
            "        if (($progressionType -eq '0' -or $progressionType -eq '1') -and $name -ne '' -and -not ($name -like 'NPC_*' -or $name -like 'Origin_*' -or $name -like 'UCL_*' -or $name -eq 'MulticlassSpellSlots')) {" ^
            "            $name | Out-File -FilePath '%ALL_OUTPUT%' -Append -Encoding utf8;" ^
            "        }" ^
            "    }" ^
            "}"
    )
)

echo Extraction complete. Proceeding to remove adjacent duplicates from both files...

:: Step 2: Remove adjacent duplicates from classes.txt
> "%TEMP_FILE%" echo.
set "lastLine="
for /f "usebackq delims=" %%a in ("%CLASSES_OUTPUT%") do (
    if not "%%a"=="!lastLine!" (
        echo %%a >> "%TEMP_FILE%"
        set "lastLine=%%a"
    )
)
move /y "%TEMP_FILE%" "%CLASSES_OUTPUT%"

:: Step 3: Remove adjacent duplicates from all.txt
> "%TEMP_FILE%" echo.
set "lastLine="
for /f "usebackq delims=" %%a in ("%ALL_OUTPUT%") do (
    if not "%%a"=="!lastLine!" (
        echo %%a >> "%TEMP_FILE%"
        set "lastLine=%%a"
    )
)
move /y "%TEMP_FILE%" "%ALL_OUTPUT%"

:: Step 4: Remove all duplicates from classes.txt
echo Removing all duplicates from classes.txt...
powershell -NoProfile -Command ^
    "Get-Content '%CLASSES_OUTPUT%' | Sort-Object -Unique | Where-Object { $_ -ne '' } | Out-File '%TEMP_FILE%' -Encoding utf8"

:: Replace the classes.txt with the deduplicated version
move /y "%TEMP_FILE%" "%CLASSES_OUTPUT%"

:: Step 5: Create lists for each class and organize subclasses
echo Duplicate removal complete. Proceeding to create lists for each class...

:: Store classes in a variable and count them
set "classlist="
set "classcount=0"
for /f "usebackq delims=" %%c in ("%CLASSES_OUTPUT%") do (
    if not "%%c"=="" (
        set /a classcount+=1
        set "classlist=!classlist!%%c "
    )
)

:: Echo the list of classes and their count
echo Found !classcount! classes:
for %%c in (!classlist!) do (
    echo - %%c
)

:: Step 6: Use PowerShell to organize subclasses under their respective classes and check for duplicates
echo Organizing subclasses under their respective classes using PowerShell...
powershell -NoProfile -Command ^
    "& { " ^
    "    $classList = @{}; " ^
    "    $allNames = Get-Content -Path '%ALL_OUTPUT%'; " ^
    "    $classes = Get-Content -Path '%CLASSES_OUTPUT%'; " ^
    "    $currentClass = ''; " ^
    "    $allAddedNames = @(); " ^
    "    foreach ($line in $allNames) { " ^
    "        if ($classes -contains $line) { " ^
    "            $currentClass = $line; " ^
    "            if (-not $classList.ContainsKey($currentClass)) { $classList[$currentClass] = @(); } " ^
    "        } elseif ($currentClass -ne '' -and (-not $allAddedNames.Contains($line))) { " ^
    "            $classList[$currentClass] += $line; " ^
    "            $allAddedNames += $line; " ^
    "        } " ^
    "    } " ^
    "    foreach ($class in $classList.Keys) { " ^
    "        $classFile = Join-Path '%EXTRACT_DIR%' ($class + '.txt'); " ^
    "        Write-Host 'Creating file for class:' $classFile; " ^
    "        $class | Out-File $classFile -Encoding utf8; " ^
    "        $classList[$class] | Out-File $classFile -Append -Encoding utf8; " ^
    "    } " ^
    "}"

:: Step 7: Create a single file with all classes and their subclasses, with extra space for subclasses
set "COMBINED_OUTPUT=%EXTRACT_DIR%\combined_classes.txt"
echo Creating combined file with all classes and subclasses...
> "%COMBINED_OUTPUT%" echo.

:: Combine each class and its subclasses into the combined file
powershell -NoProfile -Command ^
    "& { " ^
    "    $classFiles = Get-ChildItem -Path '%EXTRACT_DIR%' -Filter '*.txt' | Where-Object { $_.Name -notin @('combined_classes.txt', 'all.txt', 'classes.txt') }; " ^
    "    foreach ($file in $classFiles) { " ^
    "        $className = Get-Content -Path $file.FullName | Select-Object -First 1; " ^
    "        $subclasses = Get-Content -Path $file.FullName | Select-Object -Skip 1 | ForEach-Object { '  ' + $_ }; " ^
    "        $className | Out-File '%COMBINED_OUTPUT%' -Append -Encoding utf8; " ^
    "        $subclasses | Out-File '%COMBINED_OUTPUT%' -Append -Encoding utf8; " ^
    "        '' | Out-File '%COMBINED_OUTPUT%' -Append -Encoding utf8; " ^
    "    } " ^
    "}"
echo Combined file created at %COMBINED_OUTPUT%.

start "" "%COMBINED_OUTPUT%"

pause
