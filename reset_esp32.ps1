# Reset ESP32 into download mode
# This script resets ESP32 via RTS/DTR pins to enter download mode

param(
    [string]$Port = "COM3"
)

Write-Host "=== ESP32 Reset Script ===" -ForegroundColor Cyan
Write-Host "Port: $Port" -ForegroundColor Yellow

# Check if port exists
$ports = [System.IO.Ports.SerialPort]::GetPortNames()
if ($ports -notcontains $Port) {
    Write-Host "ERROR: Port $Port not found!" -ForegroundColor Red
    Write-Host "Available ports: $($ports -join ', ')" -ForegroundColor Yellow
    exit 1
}

try {
    Write-Host "`nOpening serial port $Port..." -ForegroundColor Cyan
    $serial = New-Object System.IO.Ports.SerialPort($Port, 115200, None, 8, One)
    $serial.Open()
    
    Write-Host "Resetting ESP32 via DTR (pull down)..." -ForegroundColor Yellow
    $serial.DtrEnable = $true
    Start-Sleep -Milliseconds 100
    
    Write-Host "Setting RTS (pull down BOOT)..." -ForegroundColor Yellow
    $serial.RtsEnable = $true
    Start-Sleep -Milliseconds 100
    
    Write-Host "Releasing DTR (reset)..." -ForegroundColor Yellow
    $serial.DtrEnable = $false
    Start-Sleep -Milliseconds 50
    
    Write-Host "Releasing RTS (release BOOT)..." -ForegroundColor Yellow
    $serial.RtsEnable = $false
    Start-Sleep -Milliseconds 100
    
    $serial.Close()
    
    Write-Host "`nESP32 reset complete! Now in download mode." -ForegroundColor Green
    Write-Host "You can now upload firmware." -ForegroundColor Cyan
    
} catch {
    Write-Host "ERROR: Failed to reset ESP32" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
