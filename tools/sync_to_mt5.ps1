<#
.SYNOPSIS
    Synchronizes or symlinks Berrytrade-EA strategies and shared libraries into a MetaTrader 5 Data Directory.

.PARAMETER MT5DataPath
    The absolute path to the MT5 terminal data directory (e.g. C:\Users\<User>\AppData\Roaming\MetaQuotes\Terminal\<INSTANCE_ID>)

.PARAMETER Symlink
    If specified, creates symbolic links instead of copying files. Requires elevated (Administrator) privileges or Developer Mode enabled on Windows.

.EXAMPLE
    .\tools\sync_to_mt5.ps1 -MT5DataPath "C:\Users\User\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, HelpMessage = "Path to MT5 Data Directory (contains MQL5 folder)")]
    [string]$MT5DataPath,

    [switch]$Symlink
)

$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$MQL5Dest = Join-Path -Path $MT5DataPath -ChildPath "MQL5"

if (-not (Test-Path $MQL5Dest)) {
    Write-Error "Could not find MQL5 directory inside '$MT5DataPath'. Please ensure the path points to a valid MT5 Terminal Data Directory."
    exit 1
}

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " Berrytrade-EA -> MetaTrader 5 Synchronization" -ForegroundColor Cyan
Write-Host " Repo Root: $RepoRoot" -ForegroundColor Gray
Write-Host " Target MQL5: $MQL5Dest" -ForegroundColor Gray
Write-Host " Mode: $(if ($Symlink) { 'Symbolic Link' } else { 'Copy Files' })" -ForegroundColor Gray
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Sync Shared/Include -> MQL5/Include/Berrytrade
$SharedIncludeSrc = Join-Path $RepoRoot "shared\Include\Berrytrade"
$MQL5IncludeDest = Join-Path $MQL5Dest "Include\Berrytrade"

if (Test-Path $SharedIncludeSrc) {
    if (-not (Test-Path $MQL5IncludeDest)) {
        New-Item -ItemType Directory -Path $MQL5IncludeDest -Force | Out-Null
    }
    Write-Host "[*] Syncing shared includes..." -ForegroundColor Yellow
    Copy-Item -Path "$SharedIncludeSrc\*" -Destination $MQL5IncludeDest -Recurse -Force
}

# 2. Sync Shared/Indicators -> MQL5/Indicators/Berrytrade
$SharedIndicatorsSrc = Join-Path $RepoRoot "shared\Indicators"
$MQL5IndicatorsDest = Join-Path $MQL5Dest "Indicators\Berrytrade"
if (Test-Path $SharedIndicatorsSrc) {
    if (-not (Test-Path $MQL5IndicatorsDest)) {
        New-Item -ItemType Directory -Path $MQL5IndicatorsDest -Force | Out-Null
    }
    Write-Host "[*] Syncing shared indicators..." -ForegroundColor Yellow
    Copy-Item -Path "$SharedIndicatorsSrc\*" -Destination $MQL5IndicatorsDest -Recurse -Force
}

# 3. Sync Strategies -> MQL5/Experts/Berrytrade
$ExpertsDest = Join-Path $MQL5Dest "Experts\Berrytrade"
if (-not (Test-Path $ExpertsDest)) {
    New-Item -ItemType Directory -Path $ExpertsDest -Force | Out-Null
}

$PresetsDest = Join-Path $MQL5Dest "Profiles\Tester"
if (-not (Test-Path $PresetsDest)) {
    New-Item -ItemType Directory -Path $PresetsDest -Force | Out-Null
}

$Tiers = @("verified", "experimental")
foreach ($tier in $Tiers) {
    $tierDir = Join-Path $RepoRoot "strategies\$tier"
    if (Test-Path $tierDir) {
        $strategies = Get-ChildItem -Path $tierDir -Directory
        foreach ($strat in $strategies) {
            $srcDir = Join-Path $strat.FullName "src"
            $presetDir = Join-Path $strat.FullName "presets"

            if (Test-Path $srcDir) {
                $targetEA = Join-Path $ExpertsDest "$($strat.Name)"
                if (-not (Test-Path $targetEA)) {
                    New-Item -ItemType Directory -Path $targetEA -Force | Out-Null
                }
                Write-Host "[+] Deploying EA: $($strat.Name) ($tier)" -ForegroundColor Green
                Copy-Item -Path "$srcDir\*" -Destination $targetEA -Recurse -Force
            }

            if (Test-Path $presetDir) {
                Copy-Item -Path "$presetDir\*.set" -Destination $PresetsDest -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

Write-Host "`n[+] Synchronization completed successfully!" -ForegroundColor Green
Write-Host "Restart or refresh MetaTrader 5 Navigator to see updated Expert Advisors under 'Experts/Berrytrade/'." -ForegroundColor Gray
