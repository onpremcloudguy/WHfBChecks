function Test-WHFB {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [PSCredential]
        $Creds,
        [Parameter(Mandatory=$false)]
        [String]
        $AADConnectSvrName
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
        Write-host "AD Schema $($ADSchema.OperatingSystem) is Not Supported, needs to be Server 2016 or higher`n`rmore information here: https://docs.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/hello-hybrid-cert-trust-prereqs#directories`n`rHow to Update: https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2008-r2-and-2008/dd464018(v=ws.10)" -Foregroundcolor Red
    }
    $ADFunctionalLevel = Get-WHFBADFunctionalLevel
    if($ADFunctionalLevel.Domain[1] -eq "Supported"){
        Write-Host "AD Domain functional level $($ADFunctionalLevel.domain[0]) is fully Supported" -Foregroundcolor Green
    } else {
        Write-Host "AD Domain functional level $($ADFunctionalLevel.domain[0]) is NOT Supported, needs to be Windows 2008 R2 or Higher`n`rmore information here: https://docs.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/hello-hybrid-cert-new-install#active-directory" -Foregroundcolor Red #TODO: create a quick user guide to update domain functional level
    }
    if($ADFunctionalLevel.Forest[1] -eq "Supported"){
        Write-Host "AD Forest functional level $($ADFunctionalLevel.Forest[0]) is fully Supported" -Foregroundcolor Green
    } else {
        Write-Host "AD Forest functional level $($ADFunctionalLevel.Forest[0]) is NOT Supported, needs to be Windows 2008 R2 or Higher`n`rmore information here: https://docs.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/hello-hybrid-cert-new-install#active-directory" -Foregroundcolor Red #TODO: create a quick user guide to update forest functional level
    }
    $DCS = Get-WHFBADDCs
    $DCCerts = [System.Collections.ArrayList]::new()
    foreach ($DC in $DCS) {
        $dc.OperatingSystemVersion.split(" ")[0]
        if ([decimal]$dc.OperatingSystemVersion.split(" ")[0] -eq 10.0) {
            write-host "Domain Controller $($dc.hostname) is supported" -Foregroundcolor Green
        }
        else {
            write-host "Domain Controller $($dc.hostname) is not supported, ALL Domain Contollers must be 2016 or Higher`n`rmore information here: https://docs.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/hello-adequate-domain-controllers`n`rHowTo: https://docs.microsoft.com/en-us/windows-server/identity/ad-ds/deploy/upgrade-domain-controllers" -ForegroundColor Red
        }
        $DCCert = Get-WHFBADDCCerts -ComputerName $dc.hostname -Creds $creds
        $DCCerts.add($DCCert)
    }
    $KeyAdmins = get-whfbadkeyadmins #need to then link this to AAD Connect
    #API endpoint for AADConnect servername https://management.azure.com/providers/Microsoft.ADHybridHealthService/services/AadSyncService-whfb2k8.onmicrosoft.com/servicemembers?api-version=2014-01-01
    #return $ADSchema
    #endregion

    #Region AADConnect
    $AADConnectReleases = Get-WHFBAACCurrentVersion
    $AADConnectSettings = Get-WHFBAADConnectSettings
    if($null -eq $AADConnectSettings.AADConnectServerName) {
        Write-Host "AAD Connect isn't configured for $($AADConnectSettings.AADTenant)`n`rmore information here: https://docs.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/hello-hybrid-key-trust-dirsync" -ForegroundColor Red
    } else {
        if($AADConnectSettings.LastDirSyncTime -lt (get-date).adddays(-1)) {
            Write-Host "AAD Connect last synchronized: $($AADConnectSettings.LastDirSyncTime) which is more then 24 hours ago`n`rmore information start here: https://docs.microsoft.com/en-us/azure/active-directory/hybrid/tshoot-connect-connectivity" -ForegroundColor Red
        } else {
            #connect to AAD Connect Servers
            
        }
    }

    #EndRegion
}