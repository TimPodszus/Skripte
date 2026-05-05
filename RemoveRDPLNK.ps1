<#
.SYNOPSIS
  Löscht Remote Desktop-Verknüpfungen im Downloads-Ordner.
  - Löscht *.rdp Dateien
  - Löscht *.lnk, die auf mstsc.exe oder eine .rdp-Datei zeigen

.DESCRIPTION
  Nutzt standardmäßig -WhatIf über CmdletBinding. 
  Um die Dateien wirklich zu löschen, muss das Skript mit -Confirm:$false oder (falls implementiert) ohne WhatIf-Präferenz aufgerufen werden.

.PARAMETER Path
  Ordnerpfad, der durchsucht werden soll (Standard: aktueller Benutzer Downloads).

.PARAMETER Recurse
  Wenn gesetzt, werden Unterordner ebenfalls durchsucht.
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

Write-Host "Durchsuche: $Path" -ForegroundColor Cyan

# 1) Parameter für Get-ChildItem vorbereiten
$gciParams = @{
  LiteralPath = $Path
  File        = $true
  ErrorAction = "SilentlyContinue"
}
if ($Recurse) { $gciParams.Recurse = $true }

# Dateien sammeln
$rdpFiles = Get-ChildItem @gciParams -Filter "*.rdp"
$lnkFiles = Get-ChildItem @gciParams -Filter "*.lnk"

# 2) .lnk Dateien prüfen
$wsh = New-Object -ComObject WScript.Shell
$rdpShortcuts = foreach ($lnk in $lnkFiles) {
  try {
    $sc = $wsh.CreateShortcut($lnk.FullName)
    $target = if ($sc.TargetPath) { $sc.TargetPath.ToString().Trim() } else { $null }
    $args   = if ($sc.Arguments) { $sc.Arguments.ToString().Trim() } else { $null }

    $isRdpRelated = ($target -match '(?i)\\mstsc\.exe$') -or 
                    ($target -match '(?i)\.rdp$') -or 
                    ($args -match '(?i)\.rdp\b')

    if ($isRdpRelated) {
      [PSCustomObject]@{
        Path = $lnk.FullName
        Type = "LNK (RDP Target)"
        Info = $target
      }
    }
  } catch {
    # Ignoriere Zugriffsprobleme oder defekte LNKs
  }
}

# COM-Objekt aufräumen
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($wsh) | Out-Null

# Liste zusammenführen
$toDelete = @()
$toDelete += $rdpFiles | Select-Object @{n="Path";e={$_.FullName}}, @{n="Type";e={"RDP File"}}, @{n="Info";e={$_.Name}}
$toDelete += $rdpShortcuts

if ($toDelete.Count -eq 0) {
  Write-Host "Keine Remote Desktop-Dateien gefunden." -ForegroundColor Green
  return
}

# 3) Löschvorgang mit WhatIf-Support
foreach ($item in $toDelete) {
  if ($PSCmdlet.ShouldProcess($item.Path, "Lösche $($item.Type)")) {
    Remove-Item -LiteralPath $item.Path -Force
    Write-Host "Gelöscht: $($item.Path)" -ForegroundColor Yellow
  }
}