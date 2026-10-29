<#
.SYNOPSIS
    Sets each user's Department attribute to the name of the OU they live in,
    then triggers an Entra Connect delta sync so the change reaches the cloud.

.NOTES
    Run on the domain controller (where Entra Connect is installed) as an administrator.
#>

Import-Module ActiveDirectory

# Get the domain's distinguished name (for example DC=lab,DC=local)
$domain = (Get-ADDomain).DistinguishedName
$baseOU = "OU=Corp_OUs,$domain"

# Find every department OU directly under Corp_OUs
$subOUs = Get-ADOrganizationalUnit -SearchBase $baseOU -Filter * -SearchScope OneLevel

foreach ($ou in $subOUs) {
    $deptName = $ou.Name

    # Get all users inside this department OU
    $users = Get-ADUser -SearchBase $ou.DistinguishedName -Filter *

    foreach ($u in $users) {
        Set-ADUser -Identity $u.SamAccountName -Department $deptName
        Write-Host "[+] Updated $($u.SamAccountName) -> Department: $deptName" -ForegroundColor Green
    }
}

# Push the changes to Microsoft Entra ID
Start-ADSyncSyncCycle -PolicyType Delta
