function Get-WHFBADSyncAccount {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]
        $Computername,
        [Parameter(Mandatory=$false)]
        [pscredential]
        $Creds
    )
    if ($PSBoundParameters.ContainsKey('Creds')){
        $cred = $creds 
    } else {
        $cred = Get-Credential
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