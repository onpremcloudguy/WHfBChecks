function Get-WHFBCertSAN {
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
                $SANExt = $cert.Extensions | Where-Object { $_.Oid.FriendlyName -match 'Subject Alternative Name' }
                $decoded = ($sanExt.Format(1) -split "`n") | ForEach-Object { if ($_ -like "*=*") { $_.split('=')[1].trim() } }
                [PSCustomObject]@{
                    SAN = $decoded 
                }
            } -Credential $cred -ArgumentList $CertPath
        }
        else {
            $cert = Get-ChildItem $CertPath
            $SANExt = $cert.Extensions | Where-Object { $_.Oid.FriendlyName -match 'Subject Alternative Name' }
            $decoded = ($sanExt.Format(1) -split "`n") | ForEach-Object { if ($_ -like "*=*") { $_.split('=')[1].trim() } }
            [PSCustomObject]@{
                SAN = $decoded 
            }
        }
        return $res
    }
    catch {
        Write-Warning $_.Exception.Message
    }
}