<#
.SYNOPSIS

This function will return the trusted root certificates for a specified certificate

.DESCRIPTION

This function will return all certificates in a trusted root chain for a specified certificate.

.EXAMPLE

PS C:\>Get-WHFBADCertTR -Computername computer1.domain.local -Cert $certificate -Creds (get-credential)

.INPUTS

Cert = System.Security.Cryptography.X509Certificates.X509Certificate2 object, which is the output from get-childitem on cert:\localmachine\my path.
Creds = PSCredential which is a local admin account

.OUTPUTS

Array of System.Security.Cryptography.X509Certificates.X509Certificate2 object/s depending upon depth of Chain.
#>
function Get-WHFBADCertTR {
    [CmdletBinding()]
    param (
        #Remote Computer name to run the test on
        [Parameter()]
        [string]
        $Computername,
        #Certificate object to check
        [Parameter()]
        $cert,
        #Admin Credentials for system to check include domain/username process.
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
        $TrustedCA = Invoke-Command -ComputerName $Computername -ScriptBlock { param($kdc) get-childitem -path Cert:\LocalMachine\CA\ | where-object { $_.subject -eq $kdc.issuer } | select-object -unique } -ArgumentList $cert -Credential $cred
        $certs += $TrustedCA
    }
    else {
        $TrustedCA = get-childitem -path Cert:\LocalMachine\CA\ | where-object { $_.subject -eq $cert.issuer } | select-object -unique
        $certs += $TrustedCA
    }
    return $certs
}