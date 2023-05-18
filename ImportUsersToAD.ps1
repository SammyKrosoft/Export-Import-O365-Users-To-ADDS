# Setup your environment variables/parameters such as domain name, etc...
## your domain name to replace to make the UPN
$YourDomain = "@yourdomain.com"
## Distinguished name of the destination OU for your groups:
$GroupsDestOU = "OU=Groups,DC=Contoso,DC=com"
## export directory for the CSV file - DO NOT PUT BACKSLASH AT THE END
$ExportDirectory = "c:\temp"

# import Users
$UsersToImport = import-csv "$ExportDirectory\o365userdata.csv" -Encoding UTF8

Foreach ($user in $UsersToImport) {
     New-ADUser -Path ("OU="+$_.Department+","+$GroupDestOU) -Name $_.Name -SamAccountName $_.SAMAccountName -GivenName $_.FirstName -Surname $_.LastName -Department $_.Department -DisplayName $_.DisplayName -EmailAddress $_.EmailAddress -Office $_.Office -ChangePasswordAtLogon $True -Title $_.Title -UserPrincipalName $_.UserPrincipalName -Enable $True -AccountPassword (ConvertTo-SecureString -string $_.Password -AsPlainText -force)
     }
 
