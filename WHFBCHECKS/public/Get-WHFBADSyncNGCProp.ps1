function Get-WHFBADSyncNGCProp {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $Computername
    )
    $MSKeyCredExists = $false
    if ($PSBoundParameters.ContainsKey('Computername')) {
        $MSKeyCredExists = invoke-command -computername $Computername -scriptblock {
            $ADSyncConnector = get-adsyncconnector | where-object { $_.type -eq "AD" }
            $ADSyncConnector.AttributeInclusionList -contains "msDS-KeyCredentialLink"
        } -Credential (Get-Credential)
    } else
    {
        $ADSyncConnector = get-adsyncconnector | where-object { $_.type -eq "AD" }
        $MSKeyCredExists = $ADSyncConnector.AttributeInclusionList -contains "msDS-KeyCredentialLink"
    }
    return $MSKeyCredExists
}