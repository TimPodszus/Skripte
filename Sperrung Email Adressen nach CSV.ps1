$Path = Read-Host -Prompt "Path to CSV: "
$Comment = Read-Host -Prompt "Comment for the Blocklist: "
$emailAdressen = Import-Csv -Path $Path

# Initialisiere eine Liste für die E-Mail-Adressen
$emailListe = @()

foreach ($email in $emailAdressen) {
    $emailListe += $email.'Sender address'
    
    # Wenn die Liste 20 E-Mail-Adressen enthält, führe den Befehl aus
    if ($emailListe.Count -eq 20) {
        $emailAdressenGruppe = $emailListe -join ","
        New-TenantAllowBlockListItems -ListType Sender -Entries $emailAdressenGruppe -Block -NoExpiration -Notes $Comment
        
        # Leere die Liste für die nächsten 20 E-Mail-Adressen
        $emailListe.Clear()
    }
}

# Führe den Befehl für die verbleibenden E-Mail-Adressen aus, falls weniger als 20 übrig sind
if ($emailListe.Count -gt 0) {
    $emailAdressenGruppe = $emailListe -join ","
    New-TenantAllowBlockListItems -ListType Sender -Entries $emailAdressenGruppe -Block -NoExpiration -Notes $Comment
}