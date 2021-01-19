function Get-WHFBCertCRLDP {
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
            $res = Invoke-Command -ComputerName $Computername -ScriptBlock { param($certpath)
                $cert = Get-ChildItem $CertPath
                $crlExt = $cert.Extensions | Where-Object { $_.Oid.FriendlyName -match 'CRL Distribution Points' }
                $decoded = (($crlExt.Format(1) -split "Full Name:")[-1]) -split 'URL=' | ForEach-Object { if ($_.Trim().Length -gt 1) { $_.Trim() } }
                [PSCustomObject]@{
                    DistributionPoints = $decoded
                } } -Credential $cred -ArgumentList $CertPath
        }
        else {
            $cert = Get-ChildItem $CertPath
            $crlExt = $cert.Extensions | Where-Object { $_.Oid.FriendlyName -match 'CRL Distribution Points' }
            $decoded = (($crlExt.Format(1) -split "Full Name:")[-1]) -split 'URL=' | ForEach-Object { if ($_.Trim().Length -gt 1) { $_.Trim() } }
            $res = [PSCustomObject]@{
                DistributionPoints = $decoded
            }
        }
        return $res
    }
    catch {
        Write-Warning $_.Exception.Message
    }
}