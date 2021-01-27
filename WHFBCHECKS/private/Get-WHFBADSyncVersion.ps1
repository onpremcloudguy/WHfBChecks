<#
.SYNOPSIS

This function will return the current version of the AAD Connect Sync engine

#>
function get-WHFBADSyncVersion {
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
    $AADConnectVersion = $null
    if ($PSBoundParameters.ContainsKey('Computername')) {
        $AADConnectVersion = Invoke-Command -ComputerName $Computername -ScriptBlock { (Get-Item (Join-Path (Get-Module ADSync -ListAvailable).modulebase "Microsoft.IdentityManagement.PowerShell.Cmdlet.dll")).VersionInfo.productversion } -Credential $cred
    }
    else {
        $AADConnectVersion = (get-item (Join-Path (Get-Module ADSync -ListAvailable).modulebase "Microsoft.IdentityManagement.PowerShell.Cmdlet.dll")).VersionInfo.productversion
    }
    return $AADConnectVersion
}