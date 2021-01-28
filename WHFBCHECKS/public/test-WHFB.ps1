function Test-WHFB {
    [CmdletBinding()]
    param (
        # An admin account that has access to Domain Controllers, AAD Connect Server, and Certificate Authority
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
    if (!(get-module -ListAvailable MSOnline)) {
        Write-Host "Installing MSOnline module to Allow interigation of AADConnect Settings" -ForegroundColor Green
        install-module MSOnline
    }
    import-module MSOnline
    #region AD
    $domainDetails = Get-WHFBADConfig
    Write-Host "Please sign in with AAD Global Administrator account for the tenant connected to domain: $($domaindetails.DNSRoot)" -ForegroundColor Green
    $module = Get-Module MSOnline
    add-type -path "$($module.ModuleBase)\Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
    $AuthSessions = [Microsoft.IdentityModel.Clients.ActiveDirectory.TokenCache]::DefaultShared.ReadItems()
    $authed = $false
    foreach ($AuthSession in $AuthSessions) {
        if ($AuthSession.clientid -eq "1b730954-1685-4b74-9bfd-dac224a7b894") {
            if ($AuthSession.expireson -gt (Get-Date)) {
                $authed = $true
            }
        }
    }
    if (!$authed) {
        Connect-MsolService
    }
    Write-Host "Running check for Windows Hello for Business for the following Domain`n`rFQDN: $($domaindetails.DNSRoot)`n`rNetBios: $($domaindetails.NetBIOSName)" -ForegroundColor Green
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
        Write-FormattedHost -Message "AD Domain functional level $($ADFunctionalLevel.domain[0]):" -ResultState Fail -ResultMessage "Not Supported, needs to be Windows 2008 R2 or Higher" -AdditionalInfo "More information here: https://docs.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/hello-hybrid-cert-new-install#active-directory"
    }
    if ($ADFunctionalLevel.Forest[1] -eq "Supported") {
        Write-FormattedHost -Message "AD Forest functional level $($ADFunctionalLevel.Forest[0]):" -ResultState Pass -ResultMessage "Supported"
    }
    else {
        Write-FormattedHost -Message "AD Forest functional level $($ADFunctionalLevel.Forest[0]):" -ResultState Fail -ResultMessage "Not Supported, needs to be Windows 2008 R2 or Higher" -AdditionalInfo "More information here: https://docs.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/hello-hybrid-cert-new-install#active-directory"
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
                Write-FormattedHost -Message "AAD Connect Schema on server $($AADConnectSettings.AADConnectServerName):" -ResultState Pass -ResultMessage "Exists"
            }
            else {
                Write-FormattedHost -Message "AAD Connect Schema on server $($AADConnectSettings.AADConnectServerName):" -ResultState Fail -ResultMessage "Does not Exist" -AdditionalInfo "More information here: https://docs.microsoft.com/en-us/azure/active-directory/hybrid/how-to-connect-installation-wizard#refresh-directory-schema"
            }
            $ADSyncNGCSync = Get-WHFBADSyncNGCSync -ComputerName $AADConnectSettings.AADConnectServerName -creds $cred
            if ($ADSyncNGCSync) {
                Write-FormattedHost -Message "AAD msDS-KeyCredentialLink sync enabled on $($AADConnectSettings.AADConnectServerName):" -ResultState Pass -ResultMessage "Syncing"
            }
            else {
                Write-FormattedHost -Message "AAD msDS-KeyCredentialLink sync enabled on $($AADConnectSettings.AADConnectServerName):" -ResultState Fail -ResultMessage "Not enabled" -AdditionalInfo "More information here: https://docs.microsoft.com/en-us/azure/active-directory/hybrid/reference-connect-sync-attributes-synchronized"
            }
        }
    }
    #EndRegion

    #Region Certs
    $CA = get-WHFBCA
    if ($ca.count -eq 0) {
        Write-FormattedHost -Message "CA Certificate Authority:" -ResultState Fail -ResultMessage "Not Found" -AdditionalInfo "More information here: https://docs.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/hello-hybrid-key-trust-prereqs#public-key-infrastructure"
    }
    elseif ($ca.count -eq 1) {
        Write-FormattedHost -Message "CA Certificate Authority:" -ResultState Pass -ResultMessage "Found"
        if ($ca.osver -lt 6.2) {
            Write-FormattedHost -Message "CA $($ca.name)'s version of Windows is:" -ResultState Fail -ResultMessage "Unsupported" -AdditionalInfo "More information here: https://docs.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/hello-hybrid-key-trust-prereqs#public-key-infrastructure"
        }
        else {
            Write-FormattedHost -Message "CA $($ca.name)'s version of Windows is:" -ResultState Pass -ResultMessage "Supported"
        }
    }
    elseif ($ca.count -gt 1) {
        Write-FormattedHost -Message "CA Multiple Certificate Authority:" -ResultState Pass -ResultMessage "Found"
        foreach ($c in $ca) {
            if ($c.osver -lt 6.2) {
                Write-FormattedHost -Message "CA $($ca.name)'s version of Windows is:" -ResultState Fail -ResultMessage "Unsupported" -AdditionalInfo "More information here: https://docs.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/hello-hybrid-key-trust-prereqs#public-key-infrastructure"
            }
            else {
                Write-FormattedHost -Message "CA $($ca.name)'s version of Windows is:" -ResultState Pass -ResultMessage "Supported"
            }
        }
    }
    $CACertTemplate = Get-WHFBCACertTemplate
    if (!($CACertTemplate)) {
        Write-FormattedHost -Message "CA KDC Certificate Template:" -ResultState Fail -ResultMessage "Not Found" -AdditionalInfo "More information here: https://docs.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/hello-hybrid-key-trust-prereqs#public-key-infrastructure"
    }
    else {
        Write-FormattedHost -Message "CA KDC Certificate Template:" -ResultState Pass -ResultMessage "`"$($CACertTemplate.displayName)`" Found"
    }
    if ($dccerts.Count -eq 0) {
        Write-FormattedHost -Message "CA KDC Certificates on Domain Controllers:" -ResultState Fail -ResultMessage "Not Found" -AdditionalInfo "More information here: https://docs.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/hello-hybrid-aadj-sso-base"
    }
    elseif ($DCCerts.count -eq 1) {
        Write-FormattedHost -Message "CA KDC Certificates on Domain Controller $($DCCerts.PSComputerName):" -ResultState Pass -ResultMessage "Found"
        $CertCRLDP = (Get-WHFBCertCRLDP -CertPath $DCCerts.PSPath -Computername $DCCerts.PSComputerName -Creds $cred).DistributionPoints | Where-Object { $_ -like '*http:*' }
        if (!($CertCRLDP)) {
            Write-FormattedHost -Message "CA KDC cert on Domain Controller $($DCCerts.PSComputerName) HTTP CRL is:" -ResultState Fail -ResultMessage "Missing" -AdditionalInfo "More information here: https://docs.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/hello-hybrid-aadj-sso-base#configuring-a-crl-distribution-point-for-an-issuing-certificate-authority"
        }
        else {
            Write-FormattedHost -Message "CA KDC cert on Domain Controller $($DCCerts.PSComputerName) HTTP CRL is:" -ResultState Pass -ResultMessage "Exists"
            $CACRLValid = Get-WHFBCACRLValid -crl (Invoke-WebRequest -Uri $CertCRLDP -UseBasicParsing).content
            if ($CACRLValid.CAName -ne $ca.CAName) {
                Write-FormattedHost -Message "CA KDC Cert CRL on Domain Controller $($DCCerts.PSComputerName) issuing Certificate Authority:" -ResultState Fail -ResultMessage "Does not Match" -AdditionalInfo "More information here: https://docs.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/hello-hybrid-key-trust-prereqs#public-key-infrastructure"
            }
            else {
                Write-FormattedHost -Message "CA KDC Cert CRL on Domain Controller $($DCCerts.PSComputerName) issuing Certificate Authority:" -ResultState Pass -ResultMessage "Matches"
            }
            if (!($CACRLValid.isValid)) {
                Write-FormattedHost -Message "CA KDC Cert CRL on Domain Controller $($DCCerts.PSComputerName) is:" -ResultState Fail -ResultMessage "not Valid, it expired on $($CACRLValid.NextUpdate)" -AdditionalInfo "More information here: https://docs.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/hello-hybrid-aadj-sso-base#publish-a-new-crl"
            }
            else {
                Write-FormattedHost -Message "CA KDC Cert CRL on Domain Controller $($DCCerts.PSComputerName) is:" -ResultState Pass -ResultMessage "Valid"
            }
            $CACRLLocation = find-netroute -remoteipaddress (resolve-dnsname $certcrldp.split(":")[1].substring(2).split('/')[0] -Type A).address
            if ($CACRLLocation.protocol -ne "Local") {
                Write-FormattedHost -Message "CA KDC Cert CRL on Domain Controller $($DCCerts.PSComputerName) is located:" -ResultState Fail -ResultMessage "Internally on IP $($CACRLLocation.IPAddress), should be external" -AdditionalInfo "More information here: https://docs.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/hello-hybrid-aadj-sso-base#crl-distribution-point-cdp"
            }
            else {
                Write-FormattedHost -Message "CA KDC Cert CRL on Domain Controller $($DCCerts.PSComputerName) is located:" -ResultState Pass -ResultMessage "Externally"
            }
        }
        $CertHasPrivatekey = Get-WHFBCertHasPrivateKey -CertPath $DCCerts.PSPath -Computername $DCCerts.PSComputerName -Creds $cred
        if ($CertHasPrivatekey) {
            Write-FormattedHost -Message "CA KDC Cert on Domain Controller $($DCCerts.PSComputerName) Private Key:" -ResultState Pass -ResultMessage "Exists"
        }
        else {
            Write-FormattedHost -Message "CA KDC Cert on Domain Controller $($DCCerts.PSComputerName) Private Key:" -ResultState Fail -ResultMessage "Does Not Exists" -AdditionalInfo "More information here: https://docs.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/hello-hybrid-aadj-sso-base"
        }
        $certKey = Get-WHFBCertKey -CertPath $DCCerts.PSPath -Computername $DCCerts.PSComputerName -Creds $cred
        if ($certkey.KeyPublisher -eq "RSA") {
            Write-FormattedHost -Message "CA KDC Cert on Domain Controller $($DCCerts.PSComputerName) has a public key by:" -ResultState Pass -ResultMessage "RSA"
        }
        else {
            Write-FormattedHost -Message "CA KDC Cert on Domain Controller $($DCCerts.PSComputerName) has a public key by:" -ResultState Fail -ResultMessage "$($certkey.KeyPublisher) not by RSA" -AdditionalInfo "More information here: https://docs.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/hello-hybrid-aadj-sso-base"
        }
        if ($certKey.KeySize -eq 2048) {
            Write-FormattedHost "CA KDC Cert on Domain Controller $($DCCerts.PSComputerName) has a public key encryption of:" -ResultState Pass -ResultMessage $certkey.KeySize
        }
        else {
            Write-FormattedHost "CA KDC Cert on Domain Controller $($DCCerts.PSComputerName) has a public key encryption of:" -ResultState Fail -ResultMessage "$($certkey.KeySize) it is required to be 2048" -AdditionalInfo "More information here: https://docs.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/hello-hybrid-aadj-sso-base"
        }
        $certSAN = (Get-WHFBCertSAN -CertPath $DCCerts.PSPath -Computername $DCCerts.PSComputerName -Creds $cred).san
        if ($certSAN -contains $DCCerts.PSComputerName) {
            Write-FormattedHost -Message "CA KDC Cert on Domain Controller $($DCCerts.PSComputerName) SAN List:" -ResultState Pass -ResultMessage "Contains $($DCCerts.PSComputerName)"
        }
        else {
            Write-FormattedHost -Message "CA KDC Cert on Domain Controller $($DCCerts.PSComputerName) SAN List:" -ResultState Fail -ResultMessage "Does not Contain $($DCCerts.PSComputerName)" -AdditionalInfo "More Information here: https://docs.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/hello-hybrid-aadj-sso-base"
        }
        if ($certsan -contains $domainDetails.NetBiosName) {
            Write-FormattedHost -Message "CA KDC Cert on Domain Controller $($DCCerts.PSComputerName) SAN List:" -ResultState Pass -ResultMessage "Contains $($domainDetails.NetBiosName)"
        }
        else {
            Write-FormattedHost -Message "CA KDC Cert on Domain Controller $($DCCerts.PSComputerName) SAN List:" -ResultState Fail -ResultMessage "Does not Contain $($domainDetails.NetBiosName)" -AdditionalInfo "More Information here: https://docs.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/hello-hybrid-aadj-sso-base"
        }
        if ($certsan -contains $domainDetails.DNSRoot) {
            Write-FormattedHost -Message "CA KDC Cert on Domain Controller $($DCCerts.PSComputerName) SAN List:" -ResultState Pass -ResultMessage "Contains $($domainDetails.DNSRoot)"
        }
        else {
            Write-FormattedHost -Message "CA KDC Cert on Domain Controller $($DCCerts.PSComputerName) SAN List:" -ResultState Fail -ResultMessage "Does not Contain $($domainDetails.DNSRoot)" -AdditionalInfo "More Information here: https://docs.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/hello-hybrid-aadj-sso-base"
        }
    }
    elseif ($DCCerts.count -gt 1) {
        foreach ($dcc in $DCCerts) {
            Write-FormattedHost -Message "CA KDC Certificates on Domain Controller $($DCC.PSComputerName):" -ResultState Pass -ResultMessage "Found"
            $CertCRLDP = (Get-WHFBCertCRLDP -CertPath $DCC.PSPath -Computername $DCC.PSComputerName -Creds $cred).DistributionPoints | Where-Object { $_ -like '*http:*' }
            if (!($CertCRLDP)) {
                Write-FormattedHost -Message "CA KDC cert on Domain Controller $($DCC.PSComputerName) HTTP CRL is:" -ResultState Fail -ResultMessage "Missing" -AdditionalInfo "More information here: https://docs.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/hello-hybrid-aadj-sso-base#configuring-a-crl-distribution-point-for-an-issuing-certificate-authority"
            }
            else {
                Write-FormattedHost -Message "CA KDC cert on Domain Controller $($DCC.PSComputerName) HTTP CRL is:" -ResultState Pass -ResultMessage "Exists"
                $CACRLValid = Get-WHFBCACRLValid -crl (Invoke-WebRequest -Uri $CertCRLDP -UseBasicParsing).content
                if ($CACRLValid.CAName -ne $ca.CAName) {
                    Write-FormattedHost -Message "CA KDC Cert CRL on Domain Controller $($DCC.PSComputerName) issuing Certificate Authority:" -ResultState Fail -ResultMessage "Does not Match" -AdditionalInfo "More information here: https://docs.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/hello-hybrid-key-trust-prereqs#public-key-infrastructure"
                }
                else {
                    Write-FormattedHost -Message "CA KDC Cert CRL on Domain Controller $($DCC.PSComputerName) issuing Certificate Authority:" -ResultState Pass -ResultMessage "Matches"
                }
                if (!($CACRLValid.isValid)) {
                    Write-FormattedHost -Message "CA KDC Cert CRL on Domain Controller $($DCC.PSComputerName) is:" -ResultState Fail -ResultMessage "not Valid, it expired on $($CACRLValid.NextUpdate)" -AdditionalInfo "More information here: https://docs.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/hello-hybrid-aadj-sso-base#publish-a-new-crl"
                }
                else {
                    Write-FormattedHost -Message "CA KDC Cert CRL on Domain Controller $($DCC.PSComputerName) is:" -ResultState Pass -ResultMessage "Valid"
                }
                $CACRLLocation = find-netroute -remoteipaddress (resolve-dnsname $certcrldp.split(":")[1].substring(2).split('/')[0] -Type A).address
                if ($CACRLLocation.protocol -ne "Local") {
                    Write-FormattedHost -Message "CA KDC Cert CRL on Domain Controller $($DCC.PSComputerName) is located:" -ResultState Fail -ResultMessage "Internally on IP $($CACRLLocation.IPAddress), should be external" -AdditionalInfo "More information here: https://docs.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/hello-hybrid-aadj-sso-base#crl-distribution-point-cdp"
                }
                else {
                    Write-FormattedHost -Message "CA KDC Cert CRL on Domain Controller $($DCC.PSComputerName) is located:" -ResultState Pass -ResultMessage "Externally"
                }
            }
            $CertHasPrivatekey = Get-WHFBCertHasPrivateKey -CertPath $DCC.PSPath -Computername $DCC.PSComputerName -Creds $cred
            if ($CertHasPrivatekey) {
                Write-FormattedHost -Message "CA KDC Cert on Domain Controller $($DCC.PSComputerName) Private Key:" -ResultState Pass -ResultMessage "Exists"
            }
            else {
                Write-FormattedHost -Message "CA KDC Cert on Domain Controller $($DCC.PSComputerName) Private Key:" -ResultState Fail -ResultMessage "Does Not Exists" -AdditionalInfo "More information here: https://docs.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/hello-hybrid-aadj-sso-base"
            }
            $certKey = Get-WHFBCertKey -CertPath $DCC.PSPath -Computername $DCC.PSComputerName -Creds $cred
            if ($certkey.KeyPublisher -eq "RSA") {
                Write-FormattedHost -Message "CA KDC Cert on Domain Controller $($DCC.PSComputerName) has a public key by:" -ResultState Pass -ResultMessage "RSA"
            }
            else {
                Write-FormattedHost -Message "CA KDC Cert on Domain Controller $($DCC.PSComputerName) has a public key by:" -ResultState Fail -ResultMessage "$($certkey.KeyPublisher) not by RSA" -AdditionalInfo "More information here: https://docs.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/hello-hybrid-aadj-sso-base"
            }
            if ($certKey.KeySize -eq 2048) {
                Write-FormattedHost "CA KDC Cert on Domain Controller $($DCC.PSComputerName) has a public key encryption of:" -ResultState Pass -ResultMessage $certkey.KeySize
            }
            else {
                Write-FormattedHost "CA KDC Cert on Domain Controller $($DCC.PSComputerName) has a public key encryption of:" -ResultState Fail -ResultMessage "$($certkey.KeySize) it is required to be 2048" -AdditionalInfo "More information here: https://docs.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/hello-hybrid-aadj-sso-base"
            }
            $certSAN = (Get-WHFBCertSAN -CertPath $DCC.PSPath -Computername $DCC.PSComputerName -Creds $cred).san
            if ($certSAN -contains $DCC.PSComputerName) {
                Write-FormattedHost -Message "CA KDC Cert on Domain Controller $($DCC.PSComputerName) SAN List:" -ResultState Pass -ResultMessage "Contains $($DCC.PSComputerName)"
            }
            else {
                Write-FormattedHost -Message "CA KDC Cert on Domain Controller $($DCC.PSComputerName) SAN List:" -ResultState Fail -ResultMessage "Does not Contain $($DCC.PSComputerName)" -AdditionalInfo "More Information here: https://docs.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/hello-hybrid-aadj-sso-base"
            }
            if ($certsan -contains $domainDetails.NetBiosName) {
                Write-FormattedHost -Message "CA KDC Cert on Domain Controller $($DCC.PSComputerName) SAN List:" -ResultState Pass -ResultMessage "Contains $($domainDetails.NetBiosName)"
            }
            else {
                Write-FormattedHost -Message "CA KDC Cert on Domain Controller $($DCC.PSComputerName) SAN List:" -ResultState Fail -ResultMessage "Does not Contain $($domainDetails.NetBiosName)" -AdditionalInfo "More Information here: https://docs.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/hello-hybrid-aadj-sso-base"
            }
            if ($certsan -contains $domainDetails.DNSRoot) {
                Write-FormattedHost -Message "CA KDC Cert on Domain Controller $($DCC.PSComputerName) SAN List:" -ResultState Pass -ResultMessage "Contains $($domainDetails.DNSRoot)"
            }
            else {
                Write-FormattedHost -Message "CA KDC Cert on Domain Controller $($DCC.PSComputerName) SAN List:" -ResultState Fail -ResultMessage "Does not Contain $($domainDetails.DNSRoot)" -AdditionalInfo "More Information here: https://docs.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/hello-hybrid-aadj-sso-base"
            }
        }
    }
    #EndRegion
}