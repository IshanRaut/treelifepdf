# Script to start the Stirling-PDF frontend in the correct directory with all prepare steps.
Set-Location -Path "c:\treelifepdf\frontend"

Write-Host "Running frontend prepare tasks..." -ForegroundColor Cyan

Write-Host "1. Setting up environment variables..." -ForegroundColor Yellow
npx tsx editor/scripts/setup-env.mts

Write-Host "2. Generating icons..." -ForegroundColor Yellow
node editor/scripts/generate-icons.js

Write-Host "3. Generating OG metadata..." -ForegroundColor Yellow
node editor/scripts/generate-og-metadata.mjs

Write-Host "Starting Vite development server..." -ForegroundColor Cyan
npx vite editor --mode proprietary --port 5173
