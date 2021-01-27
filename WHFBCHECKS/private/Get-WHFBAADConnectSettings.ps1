<#
.SYNOPSIS

This function will connect to Azure Active Directory and return back information about the AADConnect settings.

.DESCRIPTION

This function will connect to AAD and return back the AAD Connect Servername, AppType, version, Account used, full tenant name, Last Sync, Directory Sync enabled, Directory Sync Status, and if Self Service password reset is enabled.

.OUTPUTS

Selected.Microsoft.Online.Administration.CompanyInformation. 
Get-WHFBAADConnectSettings returns a subset of the result from the Get-MsolCompanyInformation commandlet.
#>
function Get-WHFBAADConnectSettings {
    if (!(get-module -ListAvailable MSOnline)) {
        install-module MSOnline
    }
    import-module MSOnline
    $module = Get-Module MSOnline
    add-type -path "$($module.ModuleBase)\Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
    $AuthSessions = [Microsoft.IdentityModel.Clients.ActiveDirectory.TokenCache]::DefaultShared.ReadItems()
    $authed = $false
    foreach ($AuthSession in $AuthSessions) {
        if ($AuthSession.clientid -eq "1b730954-1685-4b74-9bfd-dac224a7b894") {
            if ($AuthSession.expireson -gt (Get-Date)) {
                $authed = $true
            }
        }
    }
    if (!$authed) {
        Connect-MsolService
    }
    Get-MsolCompanyInformation | Select-Object @{N = 'AADConnectServerName'; E = { $_.DirSyncClientMachineName } },
    @{N = 'AADConnectAppType'; E = { $_.DirSyncApplicationType } },
    @{N = 'AADConnectVersion'; E = { $_.DirSyncClientVersion } },
    @{N = 'AADConnectAADAccount'; E = { $_.DirSyncServiceAccount } },
    @{N = 'AADTenant'; E = { $_.InitialDomain } },
    LastDirSyncTime,
    DirectorySynchronizationEnabled,
    DirectorySynchronizationStatus,
    PasswordSynchronizationEnabled,
    SelfServePasswordResetEnabled
}