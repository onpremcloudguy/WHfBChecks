<#
.SYNOPSIS

This function will return the Certificate template that was used to issue the designated certificate on the Domain Controller designated

#>
function Get-WHFBCertTemplate {
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
                $templateExt = $cert.Extensions | Where-Object { $_.Oid.FriendlyName -match 'Certificate Template Information' }
                $decoded = ($templateExt.Format(1) -split "`n") | Where-Object { $_ -like '*=*' }
                $temp = New-Object psobject
                foreach ($d in $decoded) {
                    $TemplateSplit = $d -split '='
                    $temp | Add-Member -Name $TemplateSplit[0] -MemberType NoteProperty -Value $TemplateSplit[1]
                }
                $temp } -Credential $cred -ArgumentList $CertPath
        }
        else {
            $cert = Get-ChildItem $CertPath
            $templateExt = $cert.Extensions | Where-Object { $_.Oid.FriendlyName -match 'Certificate Template Information' }
            $decoded = ($templateExt.Format(1) -split "`n") | Where-Object { $_ -like '*=*' }
            $res = New-Object psobject
            foreach ($d in $decoded) {
                $TemplateSplit = $d -split '='
                $res | Add-Member -Name $TemplateSplit[0] -MemberType NoteProperty -Value $TemplateSplit[1]
            }
        }
        return $res
    }
    catch {
        Write-Warning $_.Exception.Message
    }
}