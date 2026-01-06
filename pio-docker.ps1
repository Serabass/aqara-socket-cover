# PlatformIO через Docker - замена WSL для ленивых
param(
    [Parameter(Mandatory=$true)]
    [string]$Command,
    
    [string]$Environment = "esp32dev"
)

$Image = "platformio/platformio-core:latest"
$WorkDir = "/workspace"
$CurrentDir = (Get-Location).Path

# Маппинг текущей директории в контейнер
$DockerCmd = "docker run --rm -it -v `"${CurrentDir}:${WorkDir}`" -w ${WorkDir} ${Image}"

# Формируем команду PlatformIO
$PioCmd = "pio $Command"

if ($Command -match "run") {
    $PioCmd += " --environment $Environment"
}

# Запускаем через Docker
Invoke-Expression "$DockerCmd $PioCmd"
