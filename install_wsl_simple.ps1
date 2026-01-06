# Простая установка WSL и Ubuntu - запускать от имени администратора!
# Правой кнопкой -> "Запустить от имени администратора"

Write-Host "=== Установка WSL 2 и Ubuntu ===" -ForegroundColor Cyan
Write-Host ""

# Проверяем права администратора
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "ОШИБКА: Нужны права администратора, блять!" -ForegroundColor Red
    Write-Host "Запусти PowerShell от имени администратора и попробуй снова." -ForegroundColor Yellow
    exit 1
}

Write-Host "[1/4] Включаю компонент WSL..." -ForegroundColor Yellow
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart | Out-Null

Write-Host "[2/4] Включаю Virtual Machine Platform..." -ForegroundColor Yellow
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart | Out-Null

Write-Host "[3/4] Устанавливаю ядро обновления WSL 2..." -ForegroundColor Yellow
$wslUpdateUrl = "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi"
$wslUpdatePath = "$env:TEMP\wsl_update_x64.msi"

try {
    if (-not (Test-Path $wslUpdatePath)) {
        Write-Host "  Скачиваю ядро обновления..." -ForegroundColor Gray
        Invoke-WebRequest -Uri $wslUpdateUrl -OutFile $wslUpdatePath -UseBasicParsing | Out-Null
    }
    
    Write-Host "  Устанавливаю ядро обновления..." -ForegroundColor Gray
    Start-Process msiexec.exe -ArgumentList "/i `"$wslUpdatePath`" /quiet /norestart" -Wait -NoNewWindow | Out-Null
} catch {
    Write-Host "  Ошибка: $_" -ForegroundColor Red
    Write-Host "  Скачай вручную: $wslUpdateUrl" -ForegroundColor Yellow
}

Write-Host "[4/4] Устанавливаю Ubuntu..." -ForegroundColor Yellow
Write-Host "  (Может потребоваться перезагрузка перед этим шагом)" -ForegroundColor Gray

try {
    wsl --install --distribution Ubuntu 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  Ubuntu установлен!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Устанавливаю WSL 2 как версию по умолчанию..." -ForegroundColor Yellow
        wsl --set-default-version 2 2>&1 | Out-Null
        Write-Host ""
        Write-Host "=== Готово! ===" -ForegroundColor Green
    } else {
        Write-Host "  Не удалось установить Ubuntu сразу." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "ПЕРЕЗАГРУЗИ КОМПЬЮТЕР и выполни:" -ForegroundColor Cyan
        Write-Host "  wsl --set-default-version 2" -ForegroundColor White
        Write-Host "  wsl --install --distribution Ubuntu" -ForegroundColor White
    }
} catch {
    Write-Host "  Ошибка при установке Ubuntu: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "ПЕРЕЗАГРУЗИ КОМПЬЮТЕР и выполни:" -ForegroundColor Cyan
    Write-Host "  wsl --set-default-version 2" -ForegroundColor White
    Write-Host "  wsl --install --distribution Ubuntu" -ForegroundColor White
}
