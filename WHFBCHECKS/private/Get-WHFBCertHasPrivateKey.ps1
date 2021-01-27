<#
.SYNOPSIS

This function will return if the certificate on the Domain Controller has the Private key

#>
function Get-WHFBCertHasPrivateKey {
    [cmdletbinding()]
    param (
        # Path to the Certificate on the Domain Controller
        [parameter(Mandatory = $true)]
        [string]
        $CertPath,
        # Hostname of the Domain Controller
        [Parameter(Mandatory = $false)]
        [string]
        $Computername,
        # Admin credentials for the Domain Controller
        [Parameter(Mandatory = $false)]
        [pscredential]
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
    try {
        $res = $null
        if ($PSBoundParameters.ContainsKey('Computername')) {
            $res = Invoke-Command -ComputerName $Computername -ScriptBlock { param($certpath)
                $cert = Get-ChildItem $CertPath
                $cert.HasPrivateKey
            } -Credential $cred -ArgumentList $CertPath
        }
        else {
            $cert = Get-ChildItem $CertPath
            $res = $cert.HasPrivateKey
        }
        return $res
    }
    catch {
        Write-Warning $_.Exception.Message
    }
}