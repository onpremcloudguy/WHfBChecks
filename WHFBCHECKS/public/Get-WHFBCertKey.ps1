function Get-WHFBCertKey {
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
                $cert.PublicKey.Key | Select-Object Keysize, @{N='KeyPublisher'; E = {($_.KeyExchangeAlgorithm -split '-')[0]}}
            } -Credential $cred
        }
        else {
            $cert = Get-ChildItem $CertPath
            $res = $cert.PublicKey.Key | Select-Object Keysize, @{N='KeyPublisher'; E = {($_.KeyExchangeAlgorithm -split '-')[0]}}
        }
        return $res
    }
    catch {
        Write-Warning $_.Exception.Message
    }
}