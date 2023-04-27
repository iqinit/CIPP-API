param($tenant)

$ConfigTable = Get-CippTable -tablename 'standards'
$Setting = ((Get-AzDataTableEntity @ConfigTable -Filter "PartitionKey eq 'standards' and RowKey eq '$tenant'").JSON | ConvertFrom-Json).standards.caldefault
if (!$Setting) {
    $Setting = ((Get-AzDataTableEntity @ConfigTable -Filter "PartitionKey eq 'standards' and RowKey eq 'AllTenants'").JSON | ConvertFrom-Json).standards.caldefault
}


$Mailboxes = New-ExoRequest -tenantid $Tenant -cmdlet "get-mailbox"
foreach ($Mailbox in $Mailboxes) {
    try {
        New-ExoRequest -tenantid $Tenant -cmdlet "Get-MailboxFolderStatistics" -cmdParams @{identity = $Mailbox.UserPrincipalName; FolderScope = 'Calendar' } -Anchor $Mailbox.UserPrincipalName | ForEach-Object {
            New-ExoRequest -tenantid $Tenant  -cmdlet "Set-MailboxFolderPermission" -cmdparams @{Identity = ($_.identity).replace('\', ':\'); User = 'Default'; AccessRights = $setting.permissionlevel } -Anchor $Mailbox.UserPrincipalName 
        }
    }
    catch {
        Write-LogMessage -API "Standards" -tenant $tenant -message "Could not set spoofing warnings to $status. Error: $($_.exception.message)" -sev Error
    }

}
Write-LogMessage -API "Standards" -tenant $tenant -message "Spoofing warnings set to $status." -sev Info

