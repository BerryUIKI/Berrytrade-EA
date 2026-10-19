<#
.SYNOPSIS
    Publishes the local 'wiki/' directory to the repository's GitHub Wiki.

.DESCRIPTION
    Clones the GitHub Wiki git repository, mirrors the contents of the 'wiki/' directory,
    and commits/pushes the changes.

.PARAMETER WikiRemoteUrl
    The Git URL for the repository's wiki (default: derived from repository origin).

.EXAMPLE
    .\tools\publish_wiki.ps1
#>

[CmdletBinding()]
param(
    [string]$WikiRemoteUrl = "https://github.com/BerryUIKI/Berrytrade-EA.wiki.git"
)

$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$WikiSrc = Join-Path $RepoRoot "wiki"

if (-not (Test-Path $WikiSrc)) {
    Write-Error "Source directory '$WikiSrc' does not exist."
    exit 1
}

$TempWikiDir = Join-Path $env:TEMP "berrytrade-wiki-$(Get-Random)"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " Publishing Berrytrade User Documentation to GitHub Wiki" -ForegroundColor Cyan
Write-Host " Source: $WikiSrc" -ForegroundColor Gray
Write-Host " Remote: $WikiRemoteUrl" -ForegroundColor Gray
Write-Host " Temp Workspace: $TempWikiDir" -ForegroundColor Gray
Write-Host "==========================================================" -ForegroundColor Cyan

try {
    Write-Host "[*] Cloning GitHub Wiki..." -ForegroundColor Yellow
    git clone $WikiRemoteUrl $TempWikiDir

    Write-Host "[*] Syncing wiki pages..." -ForegroundColor Yellow
    Copy-Item -Path "$WikiSrc\*" -Destination $TempWikiDir -Recurse -Force

    Push-Location $TempWikiDir
    git add .
    $status = git status --porcelain
    if ($status) {
        Write-Host "[*] Changes detected, committing..." -ForegroundColor Yellow
        git commit -m "docs(wiki): update user documentation and multi-language wiki pages"
        Write-Host "[*] Pushing to GitHub Wiki remote..." -ForegroundColor Yellow
        git push origin master
        Write-Host "[+] Successfully published to GitHub Wiki!" -ForegroundColor Green
    } else {
        Write-Host "[+] Wiki is already up-to-date. No changes to push." -ForegroundColor Green
    }
}
catch {
    Write-Error "Failed to publish wiki: $_"
}
finally {
    Pop-Location -ErrorAction SilentlyContinue
    if (Test-Path $TempWikiDir) {
        Remove-Item -Path $TempWikiDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
