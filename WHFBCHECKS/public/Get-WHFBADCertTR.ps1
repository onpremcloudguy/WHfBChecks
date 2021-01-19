function Get-WHFBADCertTR {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $Computername,
        [Parameter()]
        $cert,
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