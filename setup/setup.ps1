
$ErrorActionPreference = 'Stop'

function main
{
    # Get the target location
    $csConfigDir = ""
    $configPath = "$PSScriptRoot\config.xml"
    if (Test-Path $configPath -PathType "leaf") {
        Write-Output "Config file exists, using settings from it."
        $csConfigDir = Read-Config $configPath
    } else {
        Write-Output "Config file not found."
        $csConfigDir = Get-ConfigPath
        Write-Config -Path $configPath -Value $csConfigDir
    }

    # Move existing config to backup dir
    $time = Get-Date -UFormat "+%Y-%m-%dT%H.%M.%S"
    $backupDir = "$PSScriptRoot\..\backup\$time"
    New-Item -ItemType "Directory" -Force -Path "$PSScriptRoot\..\backup" | Out-Null
    New-Item -ItemType "Directory" -Force -Path "$backupDir" | Out-Null

    if (Test-Path "$csConfigDir\auto") {
        Move-Item "$csConfigDir\auto" "$backupDir\auto"
    }
    if (Test-Path "$csConfigDir\autoexec.cfg") {
        Move-Item "$csConfigDir\autoexec.cfg" "$backupDir\autoexec.cfg"
    }
    if (Test-Path "$csConfigDir\config.cfg") {
        Set-ItemProperty -Path "$csConfigDir\config.cfg" -Name IsReadOnly -Value $false
        Move-Item "$csConfigDir\config.cfg"   "$backupDir\config.cfg"
    }

    # Copy new config into target location
    Copy-Item -Recurse "$PSScriptRoot\..\auto" "$csConfigDir\auto"
    Copy-Item "$PSScriptRoot\..\autoexec.cfg" "$csConfigDir\autoexec.cfg"
    Copy-Item "$PSScriptRoot\..\config.cfg" "$csConfigDir\config.cfg"

    # Make config.cfg read only
    Set-ItemProperty -Path "$csConfigDir\config.cfg" -Name IsReadOnly -Value $true

    # Print the launcht options
    $launchOpts = Get-Content "$PSScriptRoot\..\launch.txt"
    Write-Output "Don't forget to set the launch options:"
    Write-Host -BackgroundColor "green" -ForegroundColor "black" "$launchOpts"
}

function Get-ConfigPath
{
    $input = Read-Host "Enter path to 'Counter-Strike Global Offensive' directory"
    $input = "$input\csgo\cfg"

    if (-Not (Test-Path $input -PathType "Container")) {
        throw "Path is not a directory: '$input'"
    }
    return $input
}

function Read-Config
{
    [CmdletBinding()]
    param (
        [Parameter()]
        [String]
        $Path
    )

    [xml]$Configuration = Get-Content -Path $Path
    return $Configuration.P
}

function Write-Config
{
    [CmdletBinding()]
    param (
        [Parameter()]
        [String]
        $Path,
        [Parameter()]
        [String]
        $Value
    )

    Write-Output "Writing config"
    Set-Content -Path $Path -Value "<?xml version=`"1.0`"?><P>$Value</P>"
}

main
