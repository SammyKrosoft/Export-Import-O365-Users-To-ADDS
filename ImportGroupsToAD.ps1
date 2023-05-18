# Setup your environment variables/parameters such as domain name, etc...
## your domain name to replace to make the UPN
$YourDomain = "@yourdomain.com"
## Distinguished name of the destination OU for your groups:
$GroupsDestOU = "OU=Groups,DC=Contoso,DC=com"
## export directory for the CSV file - DO NOT PUT BACKSLASH AT THE END
$ExportDirectory = "c:\temp"

# import csv
$csv = Import-csv "$ExportDirectory\o365GroupData.csv" -Encoding UTF8

#connect Azure AD
$UserCredential = Get-Credential
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection
Import-PSSession $Session
Connect-MsolService -Credential $UserCredential

foreach ($item in $csv) 
{
    try 
    {
        # Check if group exists
        $exists = Get-ADGroup $item.DisplayName
        Write-Host "Group $($item.DisplayName) already exists. Skipped!"
    }
    catch 
    {
        # Create AD Groups
        $create = New-ADGroup -Name $item.DisplayName -GroupScope "Global" -DisplayName $item.DisplayName -Path $GroupsDestOU -PassThru

        Write-Host "Group $($item.DisplayName) created."

        # Get group members from Azure Ad
        $members = Get-MsolGroupMember -GroupObjectId $item.ObjectId | Where {$_.GroupMemberType -eq "User"}

        # Add member to group
        foreach($member in $members)
        {
            # get user from Azure AD
            $u = Get-MsolUser -userprincipalname $member.EmailAddress
            
            # get user SAMAccount property
            $sam = $u.userprincipalname.Replace($YourDomain,"").ToLower()

            # Add to group
            Add-ADGroupMember $item.DisplayName $sam

            Write-Host "User "+ $sam + "add to group " + $item.DisplayName 
        }
    }
}
