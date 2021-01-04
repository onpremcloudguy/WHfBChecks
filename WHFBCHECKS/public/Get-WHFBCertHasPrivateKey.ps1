function Get-WHFBCertHasPrivateKey {
    [cmdletbinding()]
    param (
        [parameter(Mandatory = $true)]
        [string]
        $CertPath,
        [Parameter()]
        [string]
        $Computername,
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
            $res = Invoke-Command -ComputerName $Computername -ScriptBlock {
                $cert = Get-ChildItem $CertPath
                $cert.HasPrivateKey
            } -Credential $cred
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