<#
.SYNOPSIS
    Get the Windows AutoPilot device information and upload it to Azure storage.
.DESCRIPTION
    This script connects with Azure storage and uses the NuGet script for collecting Windows AutoPilot device information.
    The collected information will be uploaded to Azure storage and the script will clean up anything that was saved locally.
    Before using this script make sure to set the values for <StorageAccountKey>, <StorageAccountName> and <ShareName>.
    This script is created for usage with Microsoft Intune, which doesn't support parameters yet.
.NOTES
    Author: Peter van der Woude
    Contact: pvanderwoude@hotmail.com
    Date published: 04-04-2018
    Current version: 1.0
.LINK
    http://www.petervanderwoude.nl
.EXAMPLE
    Upload-AutoPilotInformation.ps1
#>

#Set variables as input for the script
$fileName = "$env:COMPUTERNAME.csv"
$workingDirectory = Join-Path $env:WINDIR "Temp"
$storageAccountKey = ConvertTo-SecureString -String "<StorageAccountKey>" -AsPlainText -Force
$storageAccountName = "<StorageAccountName>"
$shareName = "<ShareName>"
$credential = New-Object System.Management.Automation.PSCredential -ArgumentList "Azure\$storageAccountName", $StorageAccountKey

#Try to create a drive with the storage account
Try {
    New-PSDrive -Name Z -PSProvider FileSystem -Root "\\$storageAccountName.file.core.windows.net\$shareName" -Credential $credential
}
#Catch any error and exit the script
Catch {
    Throw "Failed to connect to Azure storage"
    Exit
}

#Try to save the NuGet script
Try {
    Save-Script Get-WindowsAutopilotInfo -Path $workingDirectory
}
#Catch any error and exit the script
Catch {
    Throw "Failed to save the script"
    Exit
}

#Set the location to the path of the saved script
Set-Location -Path $workingDirectory

#Try to install the NuGet script
Try {
    Install-Script -Name Get-WindowsAutoPilotInfo -Force
}
#Catch any error and exit the script
Catch {
    Throw "Failed to install the script"
    Exit
}

#Try to run the script and save the output to the Azure storage
Try {
    Get-WindowsAutoPilotInfo.ps1 -OutputFile Z:\$fileName
}
#Catch any error and exit the script
Catch {
    Throw "Failed to get Windows AutoPilot information"
}

#Remove the downloaded script
Remove-Item -Path $workingDirectory\Get-WindowsAutoPilotInfo.ps1
#emove the created drive
Remove-PSDrive Z
