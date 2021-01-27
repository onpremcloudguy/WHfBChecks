<#
.SYNOPSIS

This function will connect to the AAD Connect server, and return back the user account that is being used to sync with Active Directory

#>
function Get-WHFBADSyncAccount {
    [CmdletBinding()]
    param (
        # Hostname of the AAD Connect Server
        [Parameter(Mandatory = $false)]
        [string]
        $Computername,
        # Admin credentials for the AAD Connect Server
        [Parameter(Mandatory = $false)]
        [pscredential]
        $Creds
    )
    if ($PSBoundParameters.ContainsKey('Creds')) {
        $cred = $creds
    }
    else {
        if ($PSBoundParameters.ContainsKey('Computername')) {
            $cred = Get-Credential
        }
    }
    $ADSyncUser = $null
    if ($PSBoundParameters.ContainsKey('Computername')) {
        $ADSyncUser = Invoke-Command -ComputerName $Computername -ScriptBlock {
            $ADSyncConnector = Get-ADSyncConnector | Where-Object { $_.type -eq "AD" }
            $ADSyncUsr = ($ADSyncConnector.ConnectivityParameters | Where-Object { $_.name -eq "forest-login-user" }).value
            $ADSyncDomain = ($ADSyncConnector.ConnectivityParameters | Where-Object { $_.name -eq "forest-login-domain" }).value
            "$($ADSyncDomain)\$($ADSyncUsr)"
        } -Credential $cred
    }
    else {
        $ADSyncConnector = Get-ADSyncConnector | Where-Object { $_.type -eq "AD" }
        $ADSyncUsr = ($ADSyncConnector.ConnectivityParameters | Where-Object { $_.name -eq "forest-login-user" }).value
        $ADSyncDomain = ($ADSyncConnector.ConnectivityParameters | Where-Object { $_.name -eq "forest-login-domain" }).value
        $ADSyncUser = "$($ADSyncDomain)\$($ADSyncUsr)"
    }
    return $ADSyncUser
}