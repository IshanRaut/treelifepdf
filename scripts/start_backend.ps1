# Script to start the Stirling-PDF backend with updated PATH environment variables loaded.
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
$machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')

$qpdfPath = "C:\Program Files\qpdf 12.3.2\bin"

# Register QPDF permanently in User PATH if not already present
$paths = $userPath -split ";" | Where-Object { $_ -ne "" }
if (-not ($paths -contains $qpdfPath)) {
    Write-Host "Permanently registering QPDF in User PATH..." -ForegroundColor Green
    [Environment]::SetEnvironmentVariable("Path", ($userPath + ";" + $qpdfPath), "User")
    $userPath = "$userPath;$qpdfPath"
}

# Prepend all updated registry paths to the current session
$env:PATH = "$userPath;$machinePath;$env:PATH"

Write-Host "Starting backend with updated PATH..." -ForegroundColor Cyan
Write-Host "PATH contains Ghostscript: $(($env:PATH -split ';') -contains 'C:\Users\Lenovo\gs\gs10.07.1\bin')" -ForegroundColor Yellow
Write-Host "PATH contains QPDF: $(($env:PATH -split ';') -contains 'C:\Program Files\qpdf 12.3.2\bin')" -ForegroundColor Yellow

.\gradlew.bat bootRun
