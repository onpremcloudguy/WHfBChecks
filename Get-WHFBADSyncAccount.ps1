function Get-WHFBADSyncAccount {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]
        $Computername
    )
    $ADSyncUser = $null
    if ($PSBoundParameters.ContainsKey('Computername')) {
        $ADSyncUser = invoke-command -computername $Computername -scriptblock {
            $ADSyncConnector = get-adsyncconnector | where-object { $_.type -eq "AD" }
            $ADSyncUsr = ($ADSyncConnector.ConnectivityParameters | where-object { $_.name -eq "forest-login-user" }).value
            $ADSyncDomain = ($ADSyncConnector.ConnectivityParameters | where-object { $_.name -eq "forest-login-domain" }).value
            "$($adsyncdomain)\$($adsyncusr)"
        } -Credential (Get-Credential)
    }
    else {
        $ADSyncConnector = get-adsyncconnector | where-object { $_.type -eq "AD" }
        $ADSyncUsr = ($ADSyncConnector.ConnectivityParameters | where-object { $_.name -eq "forest-login-user" }).value
        $ADSyncDomain = ($ADSyncConnector.ConnectivityParameters | where-object { $_.name -eq "forest-login-domain" }).value
        $ADSyncUser = "$($adsyncdomain)\$($adsyncusr)"
    }
    return $ADSyncUser
}