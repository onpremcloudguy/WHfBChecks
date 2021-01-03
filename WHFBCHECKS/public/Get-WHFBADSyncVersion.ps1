function get-WHFBADSyncVersion {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]
        $Computername,
        [Parameter(Mandatory = $false)]
        [pscredential]
        $Creds
    )
    if ($PSBoundParameters.ContainsKey('Creds')) {
        $cred = $creds
    }
    else {
        $cred = Get-Credential
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