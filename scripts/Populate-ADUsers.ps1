<#
.SYNOPSIS
    Builds a sample company structure in Active Directory for the lab.

.DESCRIPTION
    Creates a parent OU (Corp_OUs), seven department OUs, and 32 fictional users.
    Safe to run more than once: anything that already exists is skipped.
    The initial password is typed in at run time and is never stored in this file.

.NOTES
    Run on the domain controller in an elevated PowerShell session.
#>

Import-Module ActiveDirectory

# Get the domain's distinguished name (for example DC=lab,DC=local)
$domain = (Get-ADDomain).DistinguishedName
$dnsRoot = (Get-ADDomain).DNSRoot

# Ask for the initial password instead of hard-coding it
$defaultPassword = Read-Host -Prompt "Enter the initial password for new lab users" -AsSecureString

# Create the parent OU if it does not exist yet
$parentOU = "Corp_OUs"
$existingParent = Get-ADOrganizationalUnit -Filter "Name -eq '$parentOU'" -ErrorAction SilentlyContinue
if (-not $existingParent) {
    New-ADOrganizationalUnit -Name $parentOU -Path $domain -ProtectedFromAccidentalDeletion $false
    Write-Host "[+] Created parent OU: $parentOU" -ForegroundColor Green
}
$basePath = "OU=$parentOU,$domain"

# Create one OU per department
$departments = @("Legal", "Creative_PR", "Marketing", "Media", "HR", "Engineering", "Executive")
foreach ($dept in $departments) {
    $existingDept = Get-ADOrganizationalUnit -Filter "Name -eq '$dept'" -SearchBase $basePath -ErrorAction SilentlyContinue
    if (-not $existingDept) {
        New-ADOrganizationalUnit -Name $dept -Path $basePath -ProtectedFromAccidentalDeletion $false
        Write-Host "[+] Created department OU: $dept" -ForegroundColor Green
    }
}

# Fictional lab users
$users = @(
    # Legal
    @{ First = "Avery";   Last = "Collins";  User = "acollins";  Dept = "Legal";       Title = "Managing Partner" },
    @{ First = "Blake";   Last = "Morgan";   User = "bmorgan";   Dept = "Legal";       Title = "Junior Partner" },
    @{ First = "Casey";   Last = "Reed";     User = "creed";     Dept = "Legal";       Title = "Founding Partner" },
    @{ First = "Drew";    Last = "Hayes";    User = "dhayes";    Dept = "Legal";       Title = "Senior Partner" },
    @{ First = "Emerson"; Last = "Price";    User = "eprice";    Dept = "Legal";       Title = "Chief Operating Officer" },

    # Creative & PR
    @{ First = "Finley";  Last = "Brooks";   User = "fbrooks";   Dept = "Creative_PR"; Title = "Creative Director" },
    @{ First = "Gray";    Last = "Sutton";   User = "gsutton";   Dept = "Creative_PR"; Title = "PR Manager" },
    @{ First = "Harper";  Last = "Lane";     User = "hlane";     Dept = "Creative_PR"; Title = "Brand Strategist" },
    @{ First = "Indigo";  Last = "Park";     User = "ipark";     Dept = "Creative_PR"; Title = "Visual Designer" },
    @{ First = "Jordan";  Last = "Ellis";    User = "jellis";    Dept = "Creative_PR"; Title = "Content Producer" },

    # Marketing
    @{ First = "Kai";     Last = "Bennett";  User = "kbennett";  Dept = "Marketing";   Title = "Head of Marketing" },
    @{ First = "Logan";   Last = "Foster";   User = "lfoster";   Dept = "Marketing";   Title = "Digital Marketing Lead" },
    @{ First = "Morgan";  Last = "Wells";    User = "mwells";    Dept = "Marketing";   Title = "Campaign Director" },
    @{ First = "Noel";    Last = "Carter";   User = "ncarter";   Dept = "Marketing";   Title = "Social Media Specialist" },

    # Media & Production
    @{ First = "Oakley";  Last = "Grant";    User = "ogrant";    Dept = "Media";       Title = "Media Director" },
    @{ First = "Parker";  Last = "Quinn";    User = "pquinn";    Dept = "Media";       Title = "Audio Engineer" },
    @{ First = "Quincy";  Last = "Ross";     User = "qross";     Dept = "Media";       Title = "Video Producer" },
    @{ First = "Riley";   Last = "Stone";    User = "rstone";    Dept = "Media";       Title = "Broadcast Specialist" },
    @{ First = "Sage";    Last = "Turner";   User = "sturner";   Dept = "Media";       Title = "Production Manager" },

    # Human Resources
    @{ First = "Taylor";  Last = "Vaughn";   User = "tvaughn";   Dept = "HR";          Title = "HR Director" },
    @{ First = "Uma";     Last = "Walsh";    User = "uwalsh";    Dept = "HR";          Title = "Talent Acquisition Lead" },
    @{ First = "Val";     Last = "Young";    User = "vyoung";    Dept = "HR";          Title = "Employee Relations Manager" },
    @{ First = "Wren";    Last = "Adams";    User = "wadams";    Dept = "HR";          Title = "People Operations Lead" },

    # Engineering & Security
    @{ First = "Xander";  Last = "Blake";    User = "xblake";    Dept = "Engineering"; Title = "Operations Director" },
    @{ First = "Yael";    Last = "Cruz";     User = "ycruz";     Dept = "Engineering"; Title = "Infrastructure Architect" },
    @{ First = "Zion";    Last = "Diaz";     User = "zdiaz";     Dept = "Engineering"; Title = "Red Team Security Tester" },
    @{ First = "Ari";     Last = "Evans";    User = "aevans";    Dept = "Engineering"; Title = "Software Engineer" },
    @{ First = "Bailey";  Last = "Fox";      User = "bfox";      Dept = "Engineering"; Title = "Lead Data Scientist" },

    # Executive
    @{ First = "Cameron"; Last = "Gray";     User = "cgray";     Dept = "Executive";   Title = "President of Operations" },
    @{ First = "Dakota";  Last = "Hill";     User = "dhill";     Dept = "Executive";   Title = "Chief Strategy Officer" },
    @{ First = "Eden";    Last = "Irwin";    User = "eirwin";    Dept = "Executive";   Title = "Brand Director" },
    @{ First = "Frankie"; Last = "James";    User = "fjames";    Dept = "Executive";   Title = "Regional Director" }
)

# Create each user in its department OU
foreach ($u in $users) {
    $ouPath = "OU=$($u.Dept),$basePath"
    $existingUser = Get-ADUser -Filter "SamAccountName -eq '$($u.User)'" -ErrorAction SilentlyContinue
    if (-not $existingUser) {
        New-ADUser -Name "$($u.First) $($u.Last)" `
                   -GivenName $u.First `
                   -Surname $u.Last `
                   -SamAccountName $u.User `
                   -UserPrincipalName "$($u.User)@$dnsRoot" `
                   -Path $ouPath `
                   -Department $u.Dept `
                   -Title $u.Title `
                   -AccountPassword $defaultPassword `
                   -ChangePasswordAtLogon $true `
                   -Enabled $true
        Write-Host "[+] Created user: $($u.User) ($($u.Title)) in $($u.Dept)" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "[SUCCESS] Active Directory populated with $($departments.Count) OUs and $($users.Count) users." -ForegroundColor Green
