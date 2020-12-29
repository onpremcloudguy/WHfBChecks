function Get-WHFBCertCRLDP {
    [cmdletbinding()]
    param (
        [parameter(Mandatory = $true)]
        [string]
        $certPath
    )
    try {
        $cert = Get-ChildItem $certPath
        $crlExt = $cert.Extensions | Where-Object {$_.oid.friendlyName -match 'CRL Distribution Points' }
        $decoded = (($crlExt.Format(1) -split "Full Name:")[-1]) -split 'URL=' | % { if ($_.trim().length -gt 1) {$_.trim()} }
        $res = [PSCustomObject]@{
            DistributionPoints = $decoded 
        } 
        return $res
    }
    catch {
        Write-Warning $_.Exception.Message
    }
}