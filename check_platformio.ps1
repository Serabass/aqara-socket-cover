# Check PlatformIO initialization status
Write-Host "=== PlatformIO Status Check ===" -ForegroundColor Cyan

# Check if .pio directory exists
if (Test-Path .pio) {
    Write-Host "[OK] .pio directory exists" -ForegroundColor Green
    $pioSize = (Get-ChildItem -Path .pio -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB
    Write-Host "    Size: $([math]::Round($pioSize, 2)) MB" -ForegroundColor Gray
} else {
    Write-Host "[WARN] .pio directory not found - PlatformIO not initialized yet" -ForegroundColor Yellow
}

# Check platformio.ini
if (Test-Path platformio.ini) {
    Write-Host "[OK] platformio.ini found" -ForegroundColor Green
    $iniContent = Get-Content platformio.ini -Raw
    if ($iniContent -match "framework\s*=\s*arduino") {
        Write-Host "    Framework: Arduino" -ForegroundColor Gray
    }
    if ($iniContent -match "board\s*=\s*(\w+)") {
        Write-Host "    Board: $($matches[1])" -ForegroundColor Gray
    }
} else {
    Write-Host "[ERROR] platformio.ini not found!" -ForegroundColor Red
}

# Check for conflicting CMakeLists.txt
if (Test-Path CMakeLists.txt) {
    Write-Host "[WARN] CMakeLists.txt found in root - may conflict with PlatformIO!" -ForegroundColor Yellow
    Write-Host "    Consider renaming it if using Arduino framework" -ForegroundColor Gray
} else {
    Write-Host "[OK] No CMakeLists.txt in root (conflict resolved)" -ForegroundColor Green
}

# Check VS Code PlatformIO extension
Write-Host "`n=== Next Steps ===" -ForegroundColor Cyan
Write-Host "1. Reload VS Code window (Ctrl+Shift+P -> 'Developer: Reload Window')" -ForegroundColor White
Write-Host "2. Or restart VS Code completely" -ForegroundColor White
Write-Host "3. Wait for PlatformIO to finish initialization" -ForegroundColor White
Write-Host "4. Check PlatformIO status bar at bottom of VS Code" -ForegroundColor White
