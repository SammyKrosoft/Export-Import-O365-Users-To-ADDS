# Setup your environment variables/parameters such as domain name, etc...
## your domain name to replace to make the UPN
$YourDomain = "@yourdomain.com"
## export directory for the CSV file - DO NOT PUT BACKSLASH AT THE END
$ExportDirectory = "c:\temp"

#import office 365 session
$UserCredential = Get-Credential
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection
Import-PSSession $Session

#connect Azure AD
Connect-MsolService -Credential $UserCredential

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
$DataPath = "$ExportDirectory\o365UserData.csv"
$GroupDataPath = "$ExportDirectory\o365GroupData.csv"
$Results = @()

$MailboxUsers = get-mailbox -resultsize unlimited 

# Get all users
foreach($user in $mailboxusers)
{
    try 
    {
        $UPN = $user.userprincipalname
        $username = $user.name
        $MOL = Get-MsolUser -userprincipalname $UPN | Select-Object Department, DisplayName, FirstName, LastName, Office, PasswordNeverExpires, SignInName, Title
        $EmailAddress = Get-Mailbox -ResultSize Unlimited -identity $UserName |Select-Object DisplayName,PrimarySmtpAddress, @{Name="EmailAddresses";Expression={$_.EmailAddresses |Where-Object {$_.PrefixString -ceq "smtp"} | ForEach-Object {$_.SmtpAddress}}}

        $Properties = @{
        Name = $user.name
        Department = $MOL.Department
        Displayname = $MOL.DisplayName
        EmailAddress = $Emailaddress.PrimarySmtpAddress
        FirstName = $MOL.FirstNsame
        LastName = $MOL.LastName
        Office = $MOL.Office
        PasswordNeverExpires = $MOL.Passwordneverexpires
        SignInName = $MOL.SignInName
        Title = $MOL.Title
        UserPrincipalName = $UPN.ToLower()
        SAMAccountName = ($UPN.Replace($YourDomain,"")).ToLower()
        Password = random-password
        # Comment the Password line above, and uncomment below in case you want to generate your own temp password - 
        # $Password = "000000" 
        }

        $Results += New-Object psobject -Property $properties
    }
    catch 
    {
        Write-Host "Exception!" + $user.userprincipalname
    }
}
# Get all groups from Azure AD
$GroupResults = Get-MsolGroup -All

# Export users to csv
$Results | Select-Object Name, SAMAccountName, DisplayName, Emailaddress, UserPrincipalName, SignInName, Password, PasswordNeverExpires, FirstName, LastName, Department, Office, Title | Sort Department,SignInName | Export-Csv -Path $DataPath -Encoding UTF8

# Export groups to csv
$GroupResults | Select-Object ObjectId, DisplayName, EmailAddress, GroupType, IsSystem | sort DisplayName, GroupType | Export-Csv -Path $GroupDataPath -Encoding UTF8
