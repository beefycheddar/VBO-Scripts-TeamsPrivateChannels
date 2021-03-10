#Script based on VBO forum post found here https://forums.veeam.com/veeam-backup-for-office-365-f47/ms-teams-and-private-channels-t71181.html
$Job = Get-VBOJob -Name "My Existing VBO Job"
$Org = Get-VBOOrganization -Name "MyOffice365Tenant.onmicrosoft.com"
$username = "username@myoffice365tenant.onmicrosoft.com"
$passwordfilelocation = "E:\Scripts\Veeam\VBO\PlainTextPassword.txt"
#Verify password file exists
if (Test-Path -Path $passwordfilelocation) {
}
else {
    Write-Host "Password file not found! Place Password file at same location as passwordfilelocation variable."
    Break
}
$pwdTxt = Get-Content $passwordfilelocation
$securePwd = $pwdTxt | ConvertTo-SecureString -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential -ArgumentList $username, $securePwd
$session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $cred -Authentication Basic -AllowRedirection
Write-Host "Preparing to Update VBO Job: $job"
#Check for dependencies
if (Get-Module -ListAvailable -Name Microsoft.Online.SharePoint.PowerShell) {
    Write-Host "SharePointOnlinePowerShell Installed. Continuing..."
} 
else {
    Write-Host "SharePoint Online PowerShell module not installed. Install from here: https://www.powershellgallery.com/packages/Microsoft.Online.SharePoint.PowerShell/"
}
#Connect to ExchangeOnlineManagement
Import-PSSession $session
Write-Host "Connected to ExchangeOnline. Continuing..."
#Connect to SharePointOnline
connect-sposervice -credential $cred -url https://MySharePointAdminSite.sharepoint.com
Write-Host "Connected to SharePointOnline. Continuing..."
#Collect from O365
$Sites = Get-SPOSite -Template "TeamChannel#0"
ForEach ($Site in $Sites) {
$SPOSite = Get-SPOSite -Identity $Site.url -detail
$Group = Get-UnifiedGroup -Identity $SPOSite.RelatedGroupID.Guid
#Write-Host "Team" $Group.DisplayName "owns private channel site" $Site.URL      #Uncomment if you want to see the list of sites
}
Write-Host "Private Teams Channels Grabbed Successfully. Continuing..."
#Write to VBO
$Site | ForEach-Object{
$st = Get-VBOOrganizationSite -Organization $Org -Url $_.'URL' 
$newSite = New-VBOBackupItem -site  $st
Add-VBOBackupItem -Job $Job -BackupItem $newSite
}
Disconnect-SPOService
Remove-PSSession -ComputerName outlook.office365.com
Write-Host "ExchangeOnline and SharePointOnline successfully disconnected."
Write-host "VBO Job '$Job' Update Successful."
