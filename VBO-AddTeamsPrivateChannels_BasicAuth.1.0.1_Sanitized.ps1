<#
.SYNOPSIS
    Add Teams Private Channels via SharePoint to an existing VBO job. Data only, not chats.
.DESCRIPTION
    Collect all SPOsite URLs for Teams Private Channels from a tenant and add them to an existing VBO job. 
    Script based on original VBO forum post found here https://forums.veeam.com/veeam-backup-for-office-365-f47/ms-teams-and-private-channels-t71181.html
.EXAMPLE
    Configure variables below: $Job; $Org; $username; $passwordfilelocation; $SPOAdminURL
    PS C:\>VBO-AddTeamsPrivateChannels_BasicAuth.ps1
.INPUTS
    NONE
.OUTPUTS
    Continuing Status Updates.
    Uncomment: "Write-Host "Team" $Group.DisplayName "owns private channel site" $Site.URL" in #Collect From Office 365
.NOTES
    Written by Brett Gavin <brett.gavin@veeam.com>
    v1.0.1  03.11.2021    Initial version for local VBO management server
    Can be run as a Scheduled Task. Items are updated into job. If item exists in "Job A", same item will not be added to "Job B".
    As currently written, intended to be run on VBO server.
    Requires -modules Veeam.Archiver.Powershell; ExchangeOnlineManagement; Microsoft.Online.SharePoint.PowerShell

#>

#Begin check for dependencies
if (Get-Module -ListAvailable -Name Veeam.Archiver.PowerShell) {
    Write-Host "Veeam.Archiver.Powershell Installed. Continuing..."
    Import-Module "C:\Program Files\Veeam\Backup365\Veeam.Archiver.PowerShell\Veeam.Archiver.PowerShell.psd1"
} 
else {
    Write-Host "Veeam.Archiver.Powershell Module not installed. Please, run this script on the Veeam Backup for Office 365 Server."
    Break
}

#Variables
$Job = Get-VBOJob -Name "My Existing VBO Job"
$Org = Get-VBOOrganization -Name "MyOffice365Tenant.onmicrosoft.com"
$username = "username@myoffice365tenant.onmicrosoft.com"
$passwordfilelocation = "E:\Scripts\Veeam\VBO\PlainTextPassword.txt"
$SPOAdminURL = "https://MySharePointAdminSite.sharepoint.com"

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
    Break
}

#Connect to ExchangeOnlineManagement
Import-PSSession $session
Write-Host "Connected to ExchangeOnline. Continuing..."

#Connect to SharePointOnline
connect-sposervice -credential $cred -url $SPOAdminURL
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

# Cleaning up variables used in this session.
Remove-Variable -Name * -ErrorAction SilentlyContinue