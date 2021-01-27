<#
.SYNOPSIS

This function will return the Subject Alternative Names (SAN) from the designated certificate on the Domain Controller

#>
function Get-WHFBCertSAN {
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