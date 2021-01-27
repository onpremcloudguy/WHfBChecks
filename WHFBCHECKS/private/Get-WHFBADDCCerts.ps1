<#
.SYNOPSIS

This function will return the KDC Certificates from domain controllers in your environment.

.DESCRIPTION

This function returns all of the KDC Certificates from the targeted domain controllers

.OUTPUTS

Array of System.Security.Cryptography.X509Certificates.X509Certificate2 object/s depending upon number of certificates on domain controller
#>
function Get-WHFBADDCCerts {
    [CmdletBinding()]
    param (
        #Computer name of the Domain Controller you want to target
        [Parameter()]
        [string]
        $Computername,
        #Domain Admin Credentials (at minimum needs to have read access to certificates on the domain Controller.)
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