<#
.SYNOPSIS

This function will return if the AAD Connect Schema inclues the "msDS-KeyCredentialLink" object

#>
function Get-WHFBADSyncNGCProp {
    [CmdletBinding()]
    param (
        # Hostname of the AAD Connect Server
        [Parameter(Mandatory = $false)]
        [string]
        $Computername,
        # Admin credentials for the AAD Connect Server
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
    $MSKeyCredExists = $false
    if ($PSBoundParameters.ContainsKey('Computername')) {
        $MSKeyCredExists = Invoke-Command -ComputerName $Computername -ScriptBlock {
            $ADSyncConnector = Get-ADSyncConnector | Where-Object { $_.type -eq "AD" }
            $ADSyncConnector.AttributeInclusionList -contains "msDS-KeyCredentialLink"
        } -Credential $cred
    }
    else {
        $ADSyncConnector = Get-ADSyncConnector | Where-Object { $_.type -eq "AD" }
        $MSKeyCredExists = $ADSyncConnector.AttributeInclusionList -contains "msDS-KeyCredentialLink"
    }
    return $MSKeyCredExists
}