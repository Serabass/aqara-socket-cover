# WSL 2 Installation Script - Run as Administrator!
# Right click -> Run as Administrator

Write-Host "=== Installing WSL 2 and Ubuntu ===" -ForegroundColor Cyan
Write-Host ""

# Check admin rights
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "ERROR: Administrator rights required!" -ForegroundColor Red
    Write-Host "Run PowerShell as Administrator and try again." -ForegroundColor Yellow
    exit 1
}

Write-Host "[1/4] Enabling WSL component..." -ForegroundColor Yellow
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart | Out-Null

Write-Host "[2/4] Enabling Virtual Machine Platform..." -ForegroundColor Yellow
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart | Out-Null

Write-Host "[3/4] Installing WSL 2 kernel update..." -ForegroundColor Yellow
$wslUpdateUrl = "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi"
$wslUpdatePath = "$env:TEMP\wsl_update_x64.msi"

try {
    if (-not (Test-Path $wslUpdatePath)) {
        Write-Host "  Downloading kernel update..." -ForegroundColor Gray
        Invoke-WebRequest -Uri $wslUpdateUrl -OutFile $wslUpdatePath -UseBasicParsing | Out-Null
    }
    
    Write-Host "  Installing kernel update..." -ForegroundColor Gray
    Start-Process msiexec.exe -ArgumentList "/i `"$wslUpdatePath`" /quiet /norestart" -Wait -NoNewWindow | Out-Null
} catch {
    Write-Host "  Error: $_" -ForegroundColor Red
    Write-Host "  Download manually: $wslUpdateUrl" -ForegroundColor Yellow
}

Write-Host "[4/4] Installing Ubuntu..." -ForegroundColor Yellow
Write-Host "  (Reboot may be required before this step)" -ForegroundColor Gray

try {
    wsl --install --distribution Ubuntu 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  Ubuntu installed!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Setting WSL 2 as default version..." -ForegroundColor Yellow
        wsl --set-default-version 2 2>&1 | Out-Null
        Write-Host ""
        Write-Host "=== Done! ===" -ForegroundColor Green
    } else {
        Write-Host "  Failed to install Ubuntu immediately." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "REBOOT YOUR COMPUTER and run:" -ForegroundColor Cyan
        Write-Host "  wsl --set-default-version 2" -ForegroundColor White
        Write-Host "  wsl --install --distribution Ubuntu" -ForegroundColor White
    }
} catch {
    Write-Host "  Error installing Ubuntu: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "REBOOT YOUR COMPUTER and run:" -ForegroundColor Cyan
    Write-Host "  wsl --set-default-version 2" -ForegroundColor White
    Write-Host "  wsl --install --distribution Ubuntu" -ForegroundColor White
}
