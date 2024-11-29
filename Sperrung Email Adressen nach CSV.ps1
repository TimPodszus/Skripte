$Path = Read-Host -Prompt "Path to CSV: "
$Comment = Read-Host -Prompt "Comment for the Blocklist: "
$emailAdressen = Import-Csv -Path $Path


foreach ($email in $emailAdressen) {
 $emailAdresse = $email.'Sender address'
        New-TenantAllowBlockListItems -ListType Sender -Entries $emailAdresse -Block -NoExpiration -Notes $Comment
    
}

