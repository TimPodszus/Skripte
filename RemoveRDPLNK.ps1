<#
.SYNOPSIS
  Bereinigt den Downloads-Ordner von RDP-Dateien und sortiert den Rest in Unterordner.

.DESCRIPTION
  1. Löscht *.rdp und entsprechende *.lnk Dateien.
  2. Sortiert verbleibende Dateien nach Typ in Unterordner (Dokumente, Bilder, etc.).
  Unterstützt -WhatIf.

.PARAMETER Path
  Ordnerpfad (Standard: Downloads des Nutzers).
#>

[CmdletBinding(SupportsShouldProcess)]
param(
  [string]$Path = [System.IO.Path]::Combine($env:USERPROFILE, "Downloads"),
  [switch]$Recurse
)

if (-not (Test-Path -LiteralPath $Path)) {
  Write-Error "Pfad existiert nicht: $Path"
  return
}

# --- TEIL 1: RDP-REINIGUNG ---
Write-Host "--- Phase 1: RDP-Bereinigung ---" -ForegroundColor Cyan

$gciParams = @{ LiteralPath = $Path; File = $true; ErrorAction = "SilentlyContinue" }
if ($Recurse) { $gciParams.Recurse = $true }

$rdpFiles = Get-ChildItem @gciParams -Filter "*.rdp"
$lnkFiles = Get-ChildItem @gciParams -Filter "*.lnk"

$wsh = New-Object -ComObject WScript.Shell
$toDelete = @()

# LNK-Dateien prüfen
foreach ($lnk in $lnkFiles) {
    try {
        $sc = $wsh.CreateShortcut($lnk.FullName)
        $target = $sc.TargetPath
        $args   = $sc.Arguments
        if (($target -match '(?i)\\mstsc\.exe$') -or ($target -match '(?i)\.rdp$') -or ($args -match '(?i)\.rdp\b')) {
            $toDelete += [PSCustomObject]@{ Path = $lnk.FullName; Type = "LNK (RDP)" }
        }
    } catch {}
}
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($wsh) | Out-Null
$toDelete += $rdpFiles | Select-Object @{n="Path";e={$_.FullName}}, @{n="Type";e={"RDP File"}}

# Löschen
foreach ($item in $toDelete) {
    if ($PSCmdlet.ShouldProcess($item.Path, "Lösche RDP-bezogene Datei")) {
        Remove-Item -LiteralPath $item.Path -Force
    }
}

# --- TEIL 2: SORTIERUNG ---
Write-Host "`n--- Phase 2: Sortierung ---" -ForegroundColor Cyan

# Definition der Zielordner
$ExtensionMap = @{
    "Dokumente" = ".pdf", ".docx", ".doc", ".xlsx", ".pptx", ".txt", ".csv"
    "Bilder"    = ".jpg", ".jpeg", ".png", ".gif", ".svg", ".webp"
    "Programme" = ".exe", ".msi", ".appx"
    "Archive"   = ".zip", ".7z", ".rar", ".tar", ".gz"
    "Videos"    = ".mp4", ".mkv", ".mov", ".avi"
}

# Verbleibende Dateien im Hauptordner holen (ohne Unterordner zu verschieben)
$remainingFiles = Get-ChildItem -LiteralPath $Path -File

foreach ($file in $remainingFiles) {
    $ext = $file.Extension.ToLower()
    $targetFolder = "Sonstiges" # Standard, falls keine Endung matcht

    foreach ($folder in $ExtensionMap.Keys) {
        if ($ExtensionMap[$folder] -contains $ext) {
            $targetFolder = $folder
            break
        }
    }

    $destDir = Join-Path $Path $targetFolder
    
    # Ordner erstellen, falls nötig
    if (-not (Test-Path $destDir)) {
        if ($PSCmdlet.ShouldProcess($destDir, "Erstelle neuen Ordner")) {
            New-Item -Path $destDir -ItemType Directory | Out-Null
        }
    }

    # Datei verschieben
    $destPath = Join-Path $destDir $file.Name
    if ($PSCmdlet.ShouldProcess($file.FullName, "Verschiebe nach $targetFolder")) {
        Move-Item -LiteralPath $file.FullName -Destination $destPath -Force
    }
}

Write-Host "`nFertig!" -ForegroundColor Green