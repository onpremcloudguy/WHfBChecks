function Get-WHFBADDCCerts {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $Computername,
        [Parameter(Mandatory = $false)]
        [PSCredential]
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
    $certs = @()
    if ($PSBoundParameters.ContainsKey('Computername')) {
        $kdccert = Invoke-Command -ComputerName $Computername -ScriptBlock { Get-ChildItem -Path Cert:\LocalMachine\my | where-object { $_.EnhancedKeyUsageList.friendlyname -contains "KDC Authentication" -and $_.EnhancedKeyUsageList.friendlyname -contains "Client Authentication" -and $_.EnhancedKeyUsageList.friendlyname -contains "Server Authentication" } } -Credential $cred
        if ($kdccert) {
            $certs += $kdccert
        }
    }
    else {
        $kdccert = Get-ChildItem -Path Cert:\LocalMachine\my | where-object { $_.EnhancedKeyUsageList.friendlyname -contains "KDC Authentication" -and $_.EnhancedKeyUsageList.friendlyname -contains "Client Authentication" -and $_.EnhancedKeyUsageList.friendlyname -contains "Server Authentication" }
        if ($kdccert) {
            $certs += $kdccert
        }
    }
    return $certs
}