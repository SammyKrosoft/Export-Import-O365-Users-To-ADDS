# Setup your environment variables/parameters such as domain name, etc...
## your domain name to replace to make the UPN
$YourDomain = "@canadadrey.ca"
## export directory for the CSV file - DO NOT PUT BACKSLASH AT THE END
$ExportDirectory = "c:\temp"

#Connect to Exchange Online
try{
    Write-Host "Checking if already connected to Exchange Online ..." -ForegroundColor Green
    Get-Mailbox | Select -First 1 | Out-Null
    Write-Host "Already connected !" -ForegroundColor Yellow
    }
catch{
    Write-Host "Not connected to Exchange Online ... connecting..." -ForegroundColor Red
    Connect-ExchangeOnline

}

#connect Azure AD
try {
    Write-Host "Checking if already connected to MS Online ..." -ForegroundColor Green
    Get-MsolCompanyInformation | Out-Null
    Write-Host "Already connected !" -ForegroundColor Yellow
    }
catch{
     Write-Host "Not connected to MS Online ... connecting..." -ForegroundColor Red
    Connect-MsolService
    }

#Random password generator
Function random-password ($length = 8)
{
    $punc = 46..46
    $digits = 48..57
    $letters = 65..90 + 97..122

    # Thanks to
    # https://blogs.technet.com/b/heyscriptingguy/archive/2012/01/07/use-pow
    $password = get-random -count $length `
        -input ($punc + $digits + $letters) |
            % -begin { $aa = $null } `
            -process {$aa += [char]$_} `
            -end {$aa}

    return $password
}

#Export User data from o365
$DateString = Get-Date -F "yyyyMMddTHHmmss"
$DataPath = "$ExportDirectory\o365UserData_$DateString.csv"
$GroupDataPath = "$ExportDirectory\o365GroupData_$DateString.csv"
$Results = @()

$MailboxUsers = get-mailbox -resultsize unlimited -Filter {Name -notlike "DiscoverySearchMailbox*"}

# Get all users
foreach($user in $mailboxusers)
{
    try 
    {
        $UPN = $user.userprincipalname
        $UPN
        $username = $user.name
        $UserName
        $MOL = Get-MsolUser -userprincipalname $UPN | Select-Object Department, DisplayName, FirstName, LastName, Office, PasswordNeverExpires, SignInName, Title
        $MOL
        $EmailAddress = $User |Select-Object DisplayName,PrimarySmtpAddress, @{Name="EmailAddresses";Expression={$_.EmailAddresses |Where-Object {$_.StartsWith("smtp") -or $_.StartsWith("X500")}}}
        $EmailAddress

        $Properties = @{
        Name = $user.name
        Department = $MOL.Department
        Displayname = $MOL.DisplayName
        EmailAddress = $Emailaddress.PrimarySmtpAddress
        FirstName = $MOL.FirstName
        LastName = $MOL.LastName
        Office = $MOL.Office
        PasswordNeverExpires = $MOL.Passwordneverexpires
        SignInName = $MOL.SignInName
        Title = $MOL.Title
        UserPrincipalName = $UPN.ToLower()
        SAMAccountName = ($UPN.ToLower().Replace($YourDomain,"")).ToLower()
        #Password = random-password
        # Comment the Password line above, and uncomment below in case you want to generate your own temp password - 
        Password = "P@ssw0rd123" 
        }

        $Results += New-Object psobject -Property $properties
    }
    catch 
    {
        Write-Host "Exception!" + $user.userprincipalname
        $Error[0]
        $Error[1]
    }
}
# Get all groups from Azure AD
$GroupResults = Get-MsolGroup -All

# Export users to csv
$Results | Select-Object Name, SAMAccountName, DisplayName, Emailaddress, UserPrincipalName, SignInName, Password, PasswordNeverExpires, FirstName, LastName, Department, Office, Title | Sort Department,SignInName | Export-Csv -Path $DataPath -Encoding UTF8 -NoTypeInformation

notepad $DataPath

# Export groups to csv
$GroupResults | Select-Object ObjectId, DisplayName, EmailAddress, GroupType, IsSystem | sort DisplayName, GroupType | Export-Csv -Path $GroupDataPath -Encoding UTF8 -NoTypeInformation
