# Stirling-PDF Dependencies Installation & Configuration Script for Windows
# Run this script in PowerShell to install and configure all external tools.

$ErrorActionPreference = "Continue"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Starting Stirling-PDF Dependency Installation" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# 1. Helper function to add a path to the User PATH environment variable
function Add-ToUserPath {
    param (
        [string]$PathToAdd
    )
    if (Test-Path $PathToAdd) {
        $PathToAdd = (Get-Item $PathToAdd).FullName
        $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
        $paths = $userPath -split ";" | Where-Object { $_ -ne "" }
        
        if ($paths -contains $PathToAdd) {
            Write-Host "Path already in User PATH: $PathToAdd" -ForegroundColor Gray
        } else {
            Write-Host "Adding to User PATH: $PathToAdd" -ForegroundColor Green
            $newUserPath = ($paths + $PathToAdd) -join ";"
            [Environment]::SetEnvironmentVariable("Path", $newUserPath, "User")
            # Also update current session's PATH so subsequent commands in this script can use it
            $env:PATH = "$env:PATH;$PathToAdd"
        }
    } else {
        Write-Host "Warning: Path does not exist, skipping PATH addition: $PathToAdd" -ForegroundColor Yellow
    }
}

# 2. Install Winget packages (Batch 1 - Critical and fast tools)
$wingetPackages = @(
    @{ Name = "QPDF"; Id = "QPDF.QPDF" },
    @{ Name = "ImageMagick"; Id = "ImageMagick.ImageMagick" },
    @{ Name = "LibreOffice"; Id = "TheDocumentFoundation.LibreOffice" },
    @{ Name = "Tesseract OCR"; Id = "tesseract-ocr.tesseract" },
    @{ Name = "Poppler"; Id = "oschwartz10612.Poppler" }
)

Write-Host "`n--- Installing Winget Packages ---" -ForegroundColor Cyan
foreach ($pkg in $wingetPackages) {
    Write-Host "Installing $($pkg.Name) ($($pkg.Id))...." -ForegroundColor Yellow
    winget install --id $pkg.Id --silent --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Successfully installed/updated $($pkg.Name)" -ForegroundColor Green
    } else {
        Write-Host "Winget install for $($pkg.Name) returned exit code $LASTEXITCODE. It may already be installed or requires manual intervention." -ForegroundColor Yellow
    }
}

# 3. Download and Install Ghostscript (Critical for compression!)
Write-Host "`n--- Installing Ghostscript ---" -ForegroundColor Cyan
$gsVersion = "10.03.1"
$gsInstallerUrl = "https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/download/gs10031/gs10031w64.exe"
$tempDir = "$env:TEMP\gs_install"
if (-not (Test-Path $tempDir)) {
    New-Item -Path $tempDir -ItemType Directory | Out-Null
}
$installerPath = "$tempDir\gs10031w64.exe"

Write-Host "Downloading Ghostscript $gsVersion from GitHub..." -ForegroundColor Yellow
try {
    Invoke-WebRequest -Uri $gsInstallerUrl -OutFile $installerPath -ErrorAction Stop
    Write-Host "Ghostscript installer downloaded to $installerPath" -ForegroundColor Green
    
    Write-Host "Running Ghostscript installer (requires elevation prompt)..." -ForegroundColor Yellow
    # Trigger elevation prompt so user can approve the installation
    $process = Start-Process -FilePath $installerPath -ArgumentList "/S" -Wait -PassThru -Verb RunAs
    if ($process.ExitCode -eq 0) {
        Write-Host "Ghostscript installed successfully" -ForegroundColor Green
    } else {
        Write-Host "Ghostscript installer returned exit code $($process.ExitCode)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Failed to download/install Ghostscript: $_" -ForegroundColor Red
}

# 4. Patch Ghostscript executable (gs.exe)
Write-Host "`n--- Patching Ghostscript Executable ---" -ForegroundColor Cyan
$gsProgramFiles = "C:\Program Files\gs"
if (Test-Path $gsProgramFiles) {
    $gsDirs = Get-ChildItem -Path $gsProgramFiles -Directory | Sort-Object Name -Descending
    if ($gsDirs.Count -gt 0) {
        $latestGsDir = $gsDirs[0].FullName
        $gsBinPath = Join-Path $latestGsDir "bin"
        Write-Host "Found Ghostscript installation at: $latestGsDir" -ForegroundColor Green
        
        $gswin64c = Join-Path $gsBinPath "gswin64c.exe"
        $gsExe = Join-Path $gsBinPath "gs.exe"
        
        if (Test-Path $gswin64c) {
            if (-not (Test-Path $gsExe)) {
                Copy-Item -Path $gswin64c -Destination $gsExe -Force
                Write-Host "Successfully copied and renamed gswin64c.exe to gs.exe in $gsBinPath" -ForegroundColor Green
            } else {
                Write-Host "gs.exe already exists in $gsBinPath" -ForegroundColor Gray
            }
            # Add gs bin to user PATH
            Add-ToUserPath -PathToAdd $gsBinPath
        } else {
            Write-Host "Error: gswin64c.exe not found in $gsBinPath" -ForegroundColor Red
        }
    } else {
        Write-Host "No Ghostscript directories found in $gsProgramFiles" -ForegroundColor Red
    }
} else {
    Write-Host "Ghostscript directory $gsProgramFiles not found" -ForegroundColor Red
}

# 5. Configure PATH variables for other tools
Write-Host "`n--- Configuring Tool Paths in PATH ---" -ForegroundColor Cyan

# LibreOffice
$libreOfficeProgram = "C:\Program Files\LibreOffice\program"
if (Test-Path $libreOfficeProgram) {
    Write-Host "Found LibreOffice program folder" -ForegroundColor Green
    Add-ToUserPath -PathToAdd $libreOfficeProgram
}

# Tesseract OCR
$tesseractPath = "C:\Program Files\Tesseract-OCR"
if (Test-Path $tesseractPath) {
    Write-Host "Found Tesseract OCR folder" -ForegroundColor Green
    Add-ToUserPath -PathToAdd $tesseractPath
}

# Poppler (dynamic search under winget packages)
Write-Host "Searching for Poppler installation..." -ForegroundColor Yellow
$wingetPackagesDir = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages"
if (Test-Path $wingetPackagesDir) {
    $pdftohtmlFile = Get-ChildItem -Path $wingetPackagesDir -Filter "pdftohtml.exe" -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($pdftohtmlFile) {
        $popplerBin = $pdftohtmlFile.DirectoryName
        Write-Host "Found Poppler bin folder at: $popplerBin" -ForegroundColor Green
        Add-ToUserPath -PathToAdd $popplerBin
    } else {
        Write-Host "Poppler pdftohtml.exe not found in Winget packages. It might be in system PATH already if installed globally." -ForegroundColor Yellow
    }
}

# 6. Install Python packages globally
Write-Host "`n--- Installing Python Libraries ---" -ForegroundColor Cyan
$globalPython = "C:\Users\Lenovo\AppData\Local\Programs\Python\Python311\python.exe"
if (Test-Path $globalPython) {
    Write-Host "Installing Python packages to global Python environment..." -ForegroundColor Yellow
    & $globalPython -m pip install --upgrade pip
    & $globalPython -m pip install ocrmypdf unoserver opencv-python weasyprint --upgrade
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Successfully installed Python packages globally" -ForegroundColor Green
    } else {
        Write-Host "Python package installation returned exit code $LASTEXITCODE" -ForegroundColor Yellow
    }
} else {
    Write-Host "Global Python not found at $globalPython. Attempting fallback pip installation..." -ForegroundColor Yellow
    pip install ocrmypdf unoserver opencv-python weasyprint --upgrade
}

# 7. Finally, try to install Calibre (at the very end, so if it hangs, all other tools are already configured!)
Write-Host "`n--- Installing Calibre (Optional/Ebook Converter) ---" -ForegroundColor Cyan
Write-Host "Installing Calibre (calibre.calibre)..." -ForegroundColor Yellow
winget install --id calibre.calibre --silent --accept-source-agreements --accept-package-agreements
if ($LASTEXITCODE -eq 0) {
    Write-Host "Successfully installed/updated Calibre" -ForegroundColor Green
    $calibrePath = "C:\Program Files\Calibre2"
    if (Test-Path $calibrePath) {
        Add-ToUserPath -PathToAdd $calibrePath
    }
} else {
    Write-Host "Winget install for Calibre returned exit code $LASTEXITCODE. It may already be installed or was skipped." -ForegroundColor Yellow
}

Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host "Installation and Configuration Complete!" -ForegroundColor Green
Write-Host "Please close this terminal and open a new one (or restart Stirling-PDF)" -ForegroundColor Green
Write-Host "to ensure all updated environment variables are loaded." -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Cyan
