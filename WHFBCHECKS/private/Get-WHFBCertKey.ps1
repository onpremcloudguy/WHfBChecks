<#
.SYNOPSIS

This function will return the Certificate Key Publisher from the designated certificate and Domain Controller

#>
function Get-WHFBCertKey {
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
                $cert.PublicKey.Key | Select-Object Keysize, @{N = 'KeyPublisher'; E = { ($_.KeyExchangeAlgorithm -split '-')[0] } }
            } -Credential $cred -ArgumentList $CertPath
        }
        else {
            $cert = Get-ChildItem $CertPath
            $res = $cert.PublicKey.Key | Select-Object Keysize, @{N = 'KeyPublisher'; E = { ($_.KeyExchangeAlgorithm -split '-')[0] } }
        }
        return $res
    }
    catch {
        Write-Warning $_.Exception.Message
    }
}