Author: Brett Gavin (Veeam Software)

Function: Add all Teams Private Channels to an exiting Veeam Backup for Office 365 job. Entries are updated, no duplicates are created. 

Description:
Collect all SPOsite URLs for Teams Private Channels from a tenant and add them to an existing VBO job. 
    Script based on original VBO forum post found here https://forums.veeam.com/veeam-backup-for-office-365-f47/ms-teams-and-private-channels-t71181.html
    
Use case for this script is to automate the centralization of data related to Teams into one job. Contrast this with having Teams Private Channel data available in a job dedicated to Sharepoint and needing to remember that the Teams Private Channel data is actually in the Sharepoint job. This allows for the Teams job to include only Teams Public and Private into one job. Private Channel data does not include Private Channel chats.


Requires: Veeam Backup for Microsoft Office 365 PowerShell module.
