function Get-WHFBADSyncAccount {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]
        $Computername
    )
    $ADSyncUser = $null
    if ($PSBoundParameters.ContainsKey('Computername')) {
        $ADSyncUser = Invoke-Command -ComputerName $Computername -ScriptBlock {
            $ADSyncConnector = Get-ADSyncConnector | Where-Object { $_.type -eq "AD" }
            $ADSyncUsr = ($ADSyncConnector.ConnectivityParameters | Where-Object { $_.name -eq "forest-login-user" }).value
            $ADSyncDomain = ($ADSyncConnector.ConnectivityParameters | Where-Object { $_.name -eq "forest-login-domain" }).value
            "$($ADSyncDomain)\$($ADSyncUsr)"
        } -Credential (Get-Credential)
    }
    else {
        $ADSyncConnector = Get-ADSyncConnector | Where-Object { $_.type -eq "AD" }
        $ADSyncUsr = ($ADSyncConnector.ConnectivityParameters | Where-Object { $_.name -eq "forest-login-user" }).value
        $ADSyncDomain = ($ADSyncConnector.ConnectivityParameters | Where-Object { $_.name -eq "forest-login-domain" }).value
        $ADSyncUser = "$($ADSyncDomain)\$($ADSyncUsr)"
    }
    return $ADSyncUser
}