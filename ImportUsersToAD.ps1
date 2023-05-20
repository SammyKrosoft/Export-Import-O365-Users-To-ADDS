############################# PUT YOUR OWN VALUES HERE #####################################

# Setup your environment variables/parameters such as domain name, etc...
## your domain name to replace to make the UPN
$YourDomain = "@yourdomain.com"
## Distinguished name of the destination OU for your groups:
$DestOU = "OU=CANADADREY Users,DC=CANADADREY,DC=LOCAL"
## export directory for the CSV file - DO NOT PUT BACKSLASH AT THE END
$ExportDirectory = "c:\temp" # NO BACKSLASH AT THE END OF THE DIR. 
$CSVImportFile = "O365UserData.csv"

############################################################################################


# import Users
$UsersToImport = import-csv "$ExportDirectory\$CSVImportFile" -Encoding UTF8


Foreach ($user in $UsersToImport) {

#$HashTable = @{}


$HashTable = @{
    Path = "$DestOU"
    Enabled = $True
    ChangePasswordAtLogon = $True
    }


If (-not ([string]::IsNullOrEmpty($user.Name))) {$HashTable.Add('Name',$user.Name)}
If (-not ([string]::IsNullOrEmpty($user.SamAccountName))) {$HashTable.Add('SamAccountName',$user.SamAccountName)}
If (-not ([string]::IsNullOrEmpty($user.FirstName))) {$HashTable.Add('GivenName',$user.FirstName)}
If (-not ([string]::IsNullOrEmpty($user.LastName))) {$HashTable.Add('Surname',$user.LastName)}
If (-not ([string]::IsNullOrEmpty($user.Department))) {$HashTable.Add('Department',$user.Department)}
If (-not ([string]::IsNullOrEmpty($user.DisplayName))) {$HashTable.Add('DisplayName',$user.DisplayName)}
If (-not ([string]::IsNullOrEmpty($user.EmailAddress))) {$HashTable.Add('EmailAddress',$user.EmailAddress)}
If (-not ([string]::IsNullOrEmpty($user.Office))) {$HashTable.Add('Office',$user.Office)}
If (-not ([string]::IsNullOrEmpty($user.Title))) {$HashTable.Add('Title',$user.Title)}
If (-not ([string]::IsNullOrEmpty($user.UserPrincipalName))) {$HashTable.Add('UserPrincipalName',$user.UserPrincipalName)}
If (-not ([string]::IsNullOrEmpty($user.Password))) {$HashTable.Add('AccountPassword',$(ConvertTo-SecureString -string $user.Password -AsPlainText -force))}

$HashTable


    New-ADUser @HashTable -Verbose -Debug -Confirm:$false



     }
 
 
