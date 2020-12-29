function Get-WHFBCertCRLDP {
    [cmdletbinding()]
    param (
        [parameter(Mandatory = $true)]
        [string]
        $CertPath
    )
    try {
        $cert = Get-ChildItem $CertPath
        $crlExt = $cert.Extensions | Where-Object {$_.oid.friendlyName -match 'CRL Distribution Points' }
        $decoded = (($crlExt.Format(1) -split "Full Name:")[-1]) -split 'URL=' | ForEach-Object { if ($_.trim().length -gt 1) {$_.trim()} }
        $res = [PSCustomObject]@{
            DistributionPoints = $decoded 
        } 
        return $res
    }
    catch {
        Write-Warning $_.Exception.Message
    }
}