function Get-WHFBADDCCerts {
    [CmdletBinding()]
    param (
        [Parameter()]
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
    $certs = @()
    if ($PSBoundParameters.ContainsKey('Computername')) {
        $kdccert = Invoke-Command -ComputerName $Computername -ScriptBlock { Get-ChildItem -Path Cert:\LocalMachine\my | where-object { $_.EnhancedKeyUsageList.friendlyname -contains "KDC Authentication" -and $_.EnhancedKeyUsageList.friendlyname -contains "Client Authentication" -and $_.EnhancedKeyUsageList.friendlyname -contains "Server Authentication"} } -Credential $cred
        if ($kdccert) {
            $certs += $kdccert
            $TrustedCA = Invoke-Command -ComputerName $Computername -ScriptBlock { param($kdc) get-childitem -path Cert:\LocalMachine\CA\ | where-object { $_.subject -eq $kdc.issuer } } -ArgumentList $kdccert -Credential (Get-Credential)
            $certs += $TrustedCA
        }
    }
    else {
        $kdccert = Get-ChildItem -Path Cert:\LocalMachine\my | where-object { $_.EnhancedKeyUsageList.friendlyname -contains "KDC Authentication" -and $_.EnhancedKeyUsageList.friendlyname -contains "Client Authentication" -and $_.EnhancedKeyUsageList.friendlyname -contains "Server Authentication"}
        if ($kdccert) {
            $certs += $kdccert
            $TrustedCA = get-childitem -path Cert:\LocalMachine\CA\ | where-object { $_.subject -eq $kdccert.issuer }
            $certs += $TrustedCA
        }
    }
    return $certs
}