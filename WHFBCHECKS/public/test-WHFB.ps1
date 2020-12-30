function Test-WHFB {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [PSCredential]
        $Creds
    )
    if ($PSBoundParameters.ContainsKey('Creds')) {
        [PSCredential]$cred = $creds
    }
    else {
        $cred = Get-Credential
    }
    #region AD
    $ADSchema = Get-WHFBADSchema
    if ($ADSchema.supported -eq "Supported") {
        Write-host "AD Schema $($ADSchema.OperatingSystem) is supported" -Foregroundcolor Green
    }
    else {
        Write-host "AD Schema $($ADSchema.OperatingSystem) is Not Supported, needs to be Server 2016 or higher, more information here: https://docs.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/hello-hybrid-cert-trust-prereqs#directories" -Foregroundcolor Red
    }
    $ADFunctionalLevel = Get-WHFBADFunctionalLevel
    if($ADFunctionalLevel.Domain[1] -eq "Supported"){
        Write-Host "AD Domain functional level $($ADFunctionalLevel.domain[0]) is fully Supported" -Foregroundcolor Green
    } else {
        Write-Host "AD Domain functional level $($ADFunctionalLevel.domain[0]) is NOT Supported, needs to be Windows 2008 R2 or Higher, more information here: https://docs.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/hello-hybrid-cert-new-install#active-directory" -Foregroundcolor Red
    }
    if($ADFunctionalLevel.Forest[1] -eq "Supported"){
        Write-Host "AD Forest functional level $($ADFunctionalLevel.Forest[0]) is fully Supported" -Foregroundcolor Green
    } else {
        Write-Host "AD Forest functional level $($ADFunctionalLevel.Forest[0]) is NOT Supported, needs to be Windows 2008 R2 or Higher, more information here: https://docs.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/hello-hybrid-cert-new-install#active-directory" -Foregroundcolor Red
    }
    $DCS = Get-WHFBADDCs
    $DCCerts = [System.Collections.ArrayList]::new()
    foreach ($DC in $DCS) {
        if ([decimal]$dcs.OperatingSystemVersion.split(" ")[0] -eq 10.0) {
            write-host "Domain Controller $($dc.hostname) is supported" -Foregroundcolor Green
        }
        else {
            write-host "Domain Controller $($dc.hostname) is not supported, ALL Domain Contollers must be 2016 or Higher, more information here: https://docs.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/hello-adequate-domain-controllers"
        }
        $DCCert = Get-WHFBADDCCerts -ComputerName $dc.hostname -Creds $creds
        $DCCerts.add($DCCert)
    }

    return $ADSchema
    #endregion
}