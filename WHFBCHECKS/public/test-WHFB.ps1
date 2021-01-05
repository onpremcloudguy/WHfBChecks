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
    if (!(Get-Module -ListAvailable Invoke-CommandAs)) {
        Write-Host "Installing Invoke-CommandAs module to ensure PowerShell Remote works for AAD Connect" -ForegroundColor Green
        Install-Module Invoke-CommandAs -scope CurrentUser
    }
    #region AD
    $domainDetails = Get-WHFBADConfig
    Write-Host "Running check for Windows Hello for Business for the following Domain:`n`rFQDN: $($domaindetails.DNSRoot)`n`rNetBios: $($domaindetails.NetBIOSName)" -ForegroundColor Green
    $ADSchema = Get-WHFBADSchema
    if ($ADSchema.supported -eq "Supported") {
        Write-FormattedHost -Message "AD Schema $($ADSchema.OperatingSystem):" -ResultState Pass -ResultMessage "Supported"
    }
    else {
        Write-FormattedHost -Message "AD Schema $($ADSchema.OperatingSystem):" -ResultState Fail -ResultMessage "Not Supported - needs to be Server 2016 or higher" -AdditionalInfo "More information here: https://docs.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/hello-hybrid-cert-trust-prereqs#directories`n`rHow to Update: https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2008-r2-and-2008/dd464018(v=ws.10)"
    }
    $ADFunctionalLevel = Get-WHFBADFunctionalLevel
    if ($ADFunctionalLevel.Domain[1] -eq "Supported") {
        Write-FormattedHost -Message "AD Domain functional level $($ADFunctionalLevel.domain[0]):" -ResultState Pass -ResultMessage "Supported"
    }
    else {
        Write-FormattedHost -Message "AD Domain functional level $($ADFunctionalLevel.domain[0]):" -ResultState Fail -ResultMessage "Not Supported, needs to be Windows 2008 R2 or Higher" -AdditionalInfo "More information here: https://docs.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/hello-hybrid-cert-new-install#active-directory" #TODO: create a quick user guide to update domain functional level
    }
    if ($ADFunctionalLevel.Forest[1] -eq "Supported") {
        Write-FormattedHost -Message "AD Forest functional level $($ADFunctionalLevel.Forest[0]):" -ResultState Pass -ResultMessage "Supported"
    }
    else {
        Write-FormattedHost -Message "AD Forest functional level $($ADFunctionalLevel.Forest[0]):" -ResultState Fail -ResultMessage "Not Supported, needs to be Windows 2008 R2 or Higher" -AdditionalInfo "More information here: https://docs.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/hello-hybrid-cert-new-install#active-directory" #TODO: create a quick user guide to update forest functional level
    }
    $DCS = Get-WHFBADDCs
    $DCCerts = [System.Collections.ArrayList]::new()
    foreach ($DC in $DCS) {
        if ([decimal]$dc.OperatingSystemVersion.split(" ")[0] -eq 10.0) {
            Write-FormattedHost -Message "AD Domain Controller $($dc.hostname):" -ResultState Pass -ResultMessage "Supported"
        }
        else {
            Write-FormattedHost -Message "AD Domain Controller $($dc.hostname):" -ResultState Fail -ResultMessage "Not supported, ALL Domain Contollers must be 2016 or Higher" -AdditionalInfo "More information here: https://docs.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/hello-adequate-domain-controllers`n`rHowTo: https://docs.microsoft.com/en-us/windows-server/identity/ad-ds/deploy/upgrade-domain-controllers"
        }
        $DCCert = Get-WHFBADDCCerts -ComputerName $dc.hostname -Creds $cred
        if ($DCCert) {
            $DCCerts.add($DCCert)
        }
    }
    #$KeyAdmins = get-whfbadkeyadmins #need to then link this to AAD Connect
    #endregion
    #Region AADConnect
    $AADConnectReleases = Get-WHFBAACCurrentVersion
    $AADConnectSettings = Get-WHFBAADConnectSettings
    if ($null -eq $AADConnectSettings.AADConnectServerName) {
        Write-FormattedHost "AAD Connect configuration:" -ResultState Fail -ResultMessage "Not configured for $($AADConnectSettings.AADTenant)" -AdditionalInfo "More information here: https://docs.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/hello-hybrid-key-trust-dirsync"
    }
    else {
        if ($AADConnectSettings.LastDirSyncTime -lt (get-date).adddays(-1)) {
            Write-FormattedHost "AAD Connect last synchronized:" -ResultState Fail -ResultMessage "$($AADConnectSettings.LastDirSyncTime) which is more then 24 hours ago" -AdditionalInfo "More information start here: https://docs.microsoft.com/en-us/azure/active-directory/hybrid/tshoot-connect-connectivity"
        }
        else {
            $AADConnectLatestVer = $AADConnectReleases | Select-Object -First 1
            if ($AADConnectSettings.AADConnectVersion -notin $AADConnectReleases) {
                $AADConnectVerString = " from $($AADConnectSettings.AADConnectVersion)"
                if ($AADConnectSettings.AADConnectVersion -eq "") {
                    $AADConnectVerString = ""
                }
                Write-FormattedHost "AAD Connect connector version:" -ResultState Fail -ResultMessage "$aadconnectverstring - this needs to be upgraded" -AdditionalInfo "More information here: https://docs.microsoft.com/en-us/azure/active-directory/hybrid/how-to-upgrade-previous-version"
            }
            else {
                if ($AADConnectSettings.AADConnectVersion -ne $AADConnectLatestVer) {
                    Write-FormattedHost "AAD Connect connector version:" -ResultState Warning -ResultMessage "$($AADConnectSettings.AADConnectVersion) - recommended to upgrade" -AdditionalInfo "More information here: https://docs.microsoft.com/en-us/azure/active-directory/hybrid/how-to-upgrade-previous-version"
                }
                else {
                    Write-FormattedHost "AAD Connect connector version:" -ResultState Pass -ResultMessage "$($AADConnectSettings.AADConnectVersion) - is up to date"
                }
            }
            $ADSyncUser = Get-WHFBADSyncAccount -ComputerName $AADConnectSettings.AADConnectServerName -Creds $cred
            $ADSyncUserGrps = Get-WHFBADSyncAccountGroups -username $ADSyncUser.split('\')[1]
            if ($ADSyncUserGrps.Name -contains "Key Admins") {
                Write-FormattedHost "AAD Connect AD Sync Account $ADSyncUser is in the `"Key Admins`" group:" -ResultState Pass -ResultMessage "Yes"
            }
            else {
                Write-FormattedHost "AAD Connect AD Sync Account $ADSyncUser is in the `"Key Admins`" group:" -ResultState Fail -ResultMessage "No" -AdditionalInfo "More information here: https://docs.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/hello-hybrid-key-whfb-settings-dir-sync"
            }
            $ADSyncNGCProp = Get-WHFBADSyncNGCProp -ComputerName $AADConnectSettings.AADConnectServerName -Creds $cred
            if ($ADSyncNGCProp) {
                Write-FormattedHost -Message "AAD Connect Schema on server $($AADConnectSettings.AADConnectServerName):" -ResultState Pass -ResultMessage "Up to date"
            }
            else {
                Write-FormattedHost -Message "AAD Connect Schema on server $($AADConnectSettings.AADConnectServerName):" -ResultState Fail -ResultMessage "Not up to date" -AdditionalInfo "More information here: https://docs.microsoft.com/en-us/azure/active-directory/hybrid/how-to-connect-installation-wizard#refresh-directory-schema"
            }
            $ADSyncNGCSync = Get-WHFBADSyncNGCSync -ComputerName $AADConnectSettings.AADConnectServerName -creds $cred
            if ($ADSyncNGCSync) {
                Write-FormattedHost -Message "AAD Connect Schema on server $($AADConnectSettings.AADConnectServerName):" -ResultState Pass -ResultMessage "Up to date" ##todo: is this worded correctly? seems to be a duplicate of line 105
            }
            else {
                Write-FormattedHost -Message "msDS-KeyCredentialLink sync enabled on $($AADConnectSettings.AADConnectServerName):" -ResultState Fail -ResultMessage "Not enabled" -AdditionalInfo "More information here: https://docs.microsoft.com/en-us/azure/active-directory/hybrid/reference-connect-sync-attributes-synchronized"
            }
        }
    }
    #EndRegion

    #Region Certs
    $CA = get-WHFBCA
    if($ca.count -eq 0) {
        Write-host "CA No Certificate Authority found" -ForegroundColor Red
    } elseif ($ca.count -eq 1) {
        if ($ca.osver -lt 6.2) {
            Write-Host "CA $($ca.name) is on an unsupported version of Windows, it needs to be at Windows Server 2012 or higher`n`rMore information here: https://docs.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/hello-hybrid-key-trust-prereqs#public-key-infrastructure" -ForegroundColor Red
        }
        else {
            Write-Host "CA $($ca.name) is on a supported version of Windows Server" -ForegroundColor Green
        }    
    } elseif ($ca.count -gt 1) {
        foreach($c in $ca) {
            if ($c.osver -lt 6.2) {
                Write-Host "CA $($c.name) is on an unsupported version of Windows, it needs to be at Windows Server 2012 or higher`n`rMore information here: https://docs.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/hello-hybrid-key-trust-prereqs#public-key-infrastructure" -ForegroundColor Red
            }
            else {
                Write-Host "CA $($c.name) is on a supported version of Windows Server" -ForegroundColor Green
            }
        }
    }
    if ($dccerts.Count -eq 0) {
        Write-Host "CA no KDC certificates found on the Domain Controllers`n`rMore information here: https://docs.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/hello-hybrid-aadj-sso-base" -ForegroundColor Red
    }
    elseif ($DCCerts.count -eq 1) {
        $CertCRLDP = (Get-WHFBCertCRLDP -CertPath $DCCerts.PSPath -Computername $DCCerts.PSComputerName -Creds $cred).DistributionPoints | Where-Object { $_ -like '*http:*' }
        if (!($CertCRLDP)) {
            Write-Host "CA KDC cert on Domain Controller $($DCCerts.PSComputerName) does not include a HTTP CRL`n`rMore information here: https://docs.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/hello-hybrid-aadj-sso-base#configuring-a-crl-distribution-point-for-an-issuing-certificate-authority" -ForegroundColor Red
        }
        else {
            $CACRLValid = Get-WHFBCACRLValid -crl (Invoke-WebRequest -Uri $CertCRLDP -UseBasicParsing).content
            if ($CACRLValid.CAName -ne $ca.CAName) {
                Write-Host "CA KDC Cert CRL on Domain Controller $($DCCerts.PSComputerName) Does Not match the issuing Certificate Authority, confirm Certificate Authority issuing cert" -ForegroundColor Red
            }
            else {
                Write-Host "CA KDC Cert CRL on Domain Controller $($DCCerts.PSComputerName) matches the issuing Certificate Authority" -ForegroundColor Green
            }
            if (!($CACRLValid.isValid)) {
                Write-Host "CA KDC Cert CRL on Domain Controller $($DCCerts.PSComputerName) is not Valid, it expired on $($CACRLValid.NextUpdate)`n`rMore information here: https://docs.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/hello-hybrid-aadj-sso-base#publish-a-new-crl" -ForegroundColor Red
            }
            else {
                Write-Host "CA KDC Cert CRL on Domain Controller $($DCCerts.PSComputerName) is Valid" -ForegroundColor Green
            }
            $CACRLLocation = find-netroute -remoteipaddress (resolve-dnsname $certcrldp.split(":")[1].substring(2).split('/')[0] -Type A).address
            if ($CACRLLocation.protocol -ne "Local") {
                Write-Host "CA KDC Cert CRL on Domain Controller $($DCCerts.PSComputerName) is located Internally on IP $($CACRLLocation.IPAddress), should be external`n`rMore information here: https://docs.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/hello-hybrid-aadj-sso-base#crl-distribution-point-cdp" -ForegroundColor Red
            }
            else {
                Write-Host "CA KDC Cert CRL on Domain Controller $($DCCerts.PSComputerName) is located externally" -ForegroundColor Green
            }
        }
        $CertHasPrivatekey = Get-WHFBCertHasPrivateKey -CertPath $DCCerts.PSPath -Computername $DCCerts.PSComputerName -Creds $cred
        if ($CertHasPrivatekey) {
            Write-Host "CA KDC Cert on Domain Controller $($DCCerts.PSComputerName) has a Private Key" -ForegroundColor Green
        }
        else {
            Write-Host "CA KDC Cert on Domain Controller $($DCCerts.PSComputerName) does not have a Private Key`n`rMore information here: https://docs.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/hello-hybrid-aadj-sso-base" -ForegroundColor Red
        }
        $certKey = Get-WHFBCertKey -CertPath $DCCerts.PSPath -Computername $DCCerts.PSComputerName -Creds $cred
        if ($certkey.KeyPublisher -eq "RSA") {
            Write-Host "CA KDC Cert on Domain Controller $($DCCerts.PSComputerName) has a public key from RSA" -ForegroundColor Green
        }
        else {
            Write-Host "CA KDC Cert on Domain Controller $($DCCerts.PSComputerName) public key was issued by $($certkey.KeyPublisher) not by RSA`n`rMore information here: https://docs.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/hello-hybrid-aadj-sso-base" -ForegroundColor Red
        }
        if ($certKey.KeySize -eq 2048) {
            Write-Host "CA KDC Cert on Domain Controller $($DCCerts.PSComputerName) has a public key encryption of 2048" -ForegroundColor Green
        }
        else {
            Write-Host "CA KDC Cert on Domain Controller $($DCCerts.PSComputerName) public key has been encrypted as $($certkey.KeySize) not 2048 as required`n`rMore information here: https://docs.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/hello-hybrid-aadj-sso-base" -ForegroundColor Red
        }
        $certSAN = (Get-WHFBCertSAN -CertPath $DCCerts.PSPath -Computername $DCCerts.PSComputerName -Creds $cred).san
        if ($certSAN -contains $DCCerts.PSComputerName) {
            Write-Host "CA KDC Cert on Domain Controller $($DCCerts.PSComputerName) has $($DCCerts.PSComputerName) in the SAN list" -ForegroundColor Green
        }
        else {
            Write-Host "CA KDC Cert on Domain Controller $($DCCerts.PSComputerName) doesn't have $($DCCerts.PSComputerName) in the SAN list`n`rMore Information here: https://docs.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/hello-hybrid-aadj-sso-base" -ForegroundColor Red
        }
        if ($certsan -contains $domainDetails.NetBiosName) {
            Write-Host "CA KDC Cert on Domain Controller $($DCCerts.PSComputerName) has $($domainDetails.NetBiosName) in the SAN list" -ForegroundColor Green
        }
        else {
            Write-Host "CA KDC Cert on Domain Controller $($DCCerts.PSComputerName) doesn't have $($domainDetails.NetBiosName) in the SAN list`n`rMore Information here: https://docs.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/hello-hybrid-aadj-sso-base" -ForegroundColor Red
        }
        if ($certsan -contains $domainDetails.DNSRoot) {
            Write-Host "CA KDC Cert on Domain Controller $($DCCerts.PSComputerName) has $($domainDetails.DNSRoot) in the SAN list" -ForegroundColor Green
        }
        else {
            Write-Host "CA KDC Cert on Domain Controller $($DCCerts.PSComputerName) doesn't have $($domainDetails.DNSRoot) in the SAN list`n`rMore Information here: https://docs.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/hello-hybrid-aadj-sso-base" -ForegroundColor Red
        }
    }
    elseif ($DCCerts.count -gt 1) {
        foreach ($dcc in $DCCerts) {
            $CertCRLDP = (Get-WHFBCertCRLDP -CertPath $DCC.PSPath -Computername $DCC.PSComputerName -Creds $cred).DistributionPoints | Where-Object { $_ -like '*http:*' }
            if (!($CertCRLDP)) {
                Write-Host "CA KDC Cert on Domain Controller $($DCC.PSComputerName) does not include a HTTP CRL`n`rMore information here: https://docs.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/hello-hybrid-aadj-sso-base#configuring-a-crl-distribution-point-for-an-issuing-certificate-authority" -ForegroundColor Red
            }
            else {
                $CACRLValid = Get-WHFBCACRLValid -crl (Invoke-WebRequest -Uri $CertCRLDP -UseBasicParsing).content
                if ($CACRLValid.CAName -ne $ca.CAName) {
                    Write-Host "CA KDC Cert CRL on Domain Controller $($DCC.PSComputerName) Does Not match the issuing Certificate Authority, confirm Certificate Authority issuing cert" -ForegroundColor Red
                }
                else {
                    Write-Host "CA KDC Cert CRL on Domain Controller $($DCC.PSComputerName) matches the issuing Certificate Authority" -ForegroundColor Green
                }
                if (!($CACRLValid.isValid)) {
                    Write-Host "CA KDC Cert CRL on Domain Controller $($DCC.PSComputerName) is not Valid, it expired on $($CACRLValid.NextUpdate)`n`rMore Information here: https://docs.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/hello-hybrid-aadj-sso-base#publish-a-new-crl" -ForegroundColor Red
                }
                else {
                    Write-Host "CA KDC Cert CRL on Domain Controller $($DCC.PSComputerName) is Valid" -ForegroundColor Green
                }
                $CACRLLocation = find-netroute -remoteipaddress (resolve-dnsname $certcrldp.split(":")[1].substring(2).split('/')[0] -Type A).address
                if ($CACRLLocation.protocol -ne "Local") {
                    Write-Host "CA KDC Cert CRL on Domain Controller $($DCC.PSComputerName) is located Internally on IP $($CACRLLocation.IPAddress), should be external`n`rMore information here: https://docs.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/hello-hybrid-aadj-sso-base#crl-distribution-point-cdp" -ForegroundColor Red
                }
                else {
                    Write-Host "CA KDC Cert CRL on Domain Controller $($DCC.PSComputerName) is located externally" -ForegroundColor Green
                }
            }
            #check if there is a HTTP Address, and then download it.
            $CertHasPrivatekey = Get-WHFBCertHasPrivateKey -CertPath $DCC.PSPath -Computername $DCC.PSComputerName -Creds $cred
            if ($CertHasPrivatekey) {
                Write-Host "CA KDC Cert on Domain Controller $($DCC.PSComputerName) has a Private Key" -ForegroundColor Green
            }
            else {
                Write-Host "CA KDC Cert on Domain Controller $($DCC.PSComputerName) does not have a Private Key`n`rMore information here: https://docs.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/hello-hybrid-aadj-sso-base" -ForegroundColor Red
            }
            $certKey = Get-WHFBCertKey -CertPath $DCC.PSPath -Computername $DCC.PSComputerName -Creds $cred
            if ($certkey.KeyPublisher -eq "RSA") {
                Write-Host "CA KDC Cert on Domain Controller $($DCC.PSComputerName) has a public key from RSA" -ForegroundColor Green
            }
            else {
                Write-Host "CA KDC Cert on Domain Controller $($DCC.PSComputerName) public key was issued by $($certkey.KeyPublisher) not by RSA`n`rMore information here: https://docs.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/hello-hybrid-aadj-sso-base" -ForegroundColor Red
            }
            if ($certKey.KeySize -eq 2048) {
                Write-Host "CA KDC Cert on Domain Controller $($DCC.PSComputerName) has a public key encryption of 2048" -ForegroundColor Green
            }
            else {
                Write-Host "CA KDC Cert on Domain Controller $($DCC.PSComputerName) public key has been encrypted as $($certkey.KeySize) not 2048 as required`n`rMore information here: https://docs.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/hello-hybrid-aadj-sso-base" -ForegroundColor Red
            }
            $certSAN = (Get-WHFBCertSAN -CertPath $DCC.PSPath -Computername $DCC.PSComputerName -Creds $cred).san
            if ($certSAN -contains $DCC.PSComputerName) {
                Write-Host "CA KDC Cert on Domain Controller $($DCC.PSComputerName) has $($DCC.PSComputerName) in the SAN list" -ForegroundColor Green
            }
            else {
                Write-Host "CA KDC Cert on Domain Controller $($DCC.PSComputerName) doesn't have $($DCC.PSComputerName) in the SAN list`n`rMore Information here: https://docs.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/hello-hybrid-aadj-sso-base" -ForegroundColor Red
            }
            if ($certsan -contains $domainDetails.NetBiosName) {
                Write-Host "CA KDC Cert on Domain Controller $($DCC.PSComputerName) has $($domainDetails.NetBiosName) in the SAN list" -ForegroundColor Green
            }
            else {
                Write-Host "CA KDC Cert on Domain Controller $($DCC.PSComputerName) doesn't have $($domainDetails.NetBiosName) in the SAN list`n`rMore Information here: https://docs.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/hello-hybrid-aadj-sso-base" -ForegroundColor Red
            }
            if ($certsan -contains $domainDetails.DNSRoot) {
                Write-Host "CA KDC Cert on Domain Controller $($DCC.PSComputerName) has $($domainDetails.DNSRoot) in the SAN list" -ForegroundColor Green
            }
            else {
                Write-Host "CA KDC Cert on Domain Controller $($DCC.PSComputerName) doesn't have $($domainDetails.DNSRoot) in the SAN list`n`rMore Information here: https://docs.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/hello-hybrid-aadj-sso-base" -ForegroundColor Red
            }
        }
    }
    #EndRegion
}