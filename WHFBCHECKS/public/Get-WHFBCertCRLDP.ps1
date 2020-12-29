function Get-WHFBCertCRLDP {
    [cmdletbinding()]
    param (
        [parameter(Mandatory = $true)]
        [string]
        $CertPath
    )
    try {
        $cert = Get-ChildItem $CertPath
        $crlExt = $cert.Extensions | Where-Object { $_.Oid.FriendlyName -match 'CRL Distribution Points' }
        $decoded = (($crlExt.Format(1) -split "Full Name:")[-1]) -split 'URL=' | ForEach-Object { if ($_.Trim().Length -gt 1) { $_.Trim() } }
        $res = [PSCustomObject]@{
            DistributionPoints = $decoded 
        } 
        return $res
    }
    catch {
        Write-Warning $_.Exception.Message
    }
}