# Install WSL 2 - запускать от имени администратора, блять!
# Правой кнопкой -> "Запустить от имени администратора"

Write-Host "Устанавливаю WSL 2, терпи..." -ForegroundColor Yellow

# Включаем компонент WSL
Write-Host "`n[1/3] Включаю компонент WSL..." -ForegroundColor Cyan
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart

# Включаем компонент Virtual Machine Platform (нужен для WSL 2)
Write-Host "`n[2/3] Включаю Virtual Machine Platform..." -ForegroundColor Cyan
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

Write-Host "`n[3/3] Устанавливаю ядро обновления WSL 2..." -ForegroundColor Cyan
# Скачиваем и устанавливаем ядро обновления WSL 2
$wslUpdateUrl = "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi"
$wslUpdatePath = "$env:TEMP\wsl_update_x64.msi"

try {
    Write-Host "Скачиваю ядро обновления..." -ForegroundColor Gray
    Invoke-WebRequest -Uri $wslUpdateUrl -OutFile $wslUpdatePath -UseBasicParsing | Out-Null
    
    Write-Host "Устанавливаю ядро обновления..." -ForegroundColor Gray
    Start-Process msiexec.exe -ArgumentList "/i `"$wslUpdatePath`" /quiet /norestart" -Wait -NoNewWindow
    
    Write-Host "`nУстанавливаю Ubuntu..." -ForegroundColor Cyan
    # Пробуем установить Ubuntu сразу (может не сработать без перезагрузки)
    try {
        wsl --install --distribution Ubuntu 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Ubuntu установлен успешно!" -ForegroundColor Green
            Write-Host "Устанавливаю WSL 2 как версию по умолчанию..." -ForegroundColor Cyan
            wsl --set-default-version 2 2>&1 | Out-Null
        } else {
            Write-Host "Не удалось установить Ubuntu сразу. Нужна перезагрузка." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Не удалось установить Ubuntu: $_" -ForegroundColor Yellow
    }
    
    Write-Host "`nУстановка завершена!" -ForegroundColor Green
    Write-Host "Если Ubuntu не установился, перезагрузи комп и выполни:" -ForegroundColor Yellow
    Write-Host "  wsl --set-default-version 2" -ForegroundColor Gray
    Write-Host "  wsl --install --distribution Ubuntu" -ForegroundColor Gray
} catch {
    Write-Host "`nОшибка при установке: $_" -ForegroundColor Red
    Write-Host "Можешь скачать вручную: $wslUpdateUrl" -ForegroundColor Yellow
}
