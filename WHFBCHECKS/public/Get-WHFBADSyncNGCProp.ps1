function Get-WHFBADSyncNGCProp {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $Computername
    )
    $MSKeyCredExists = $false
    if ($PSBoundParameters.ContainsKey('Computername')) {
        $MSKeyCredExists = Invoke-Command -ComputerName $Computername -ScriptBlock {
            $ADSyncConnector = Get-ADSyncConnector | Where-Object { $_.type -eq "AD" }
            $ADSyncConnector.AttributeInclusionList -contains "msDS-KeyCredentialLink"
        } -Credential (Get-Credential)
    } else
    {
        $ADSyncConnector = Get-ADSyncConnector | Where-Object { $_.type -eq "AD" }
        $MSKeyCredExists = $ADSyncConnector.AttributeInclusionList -contains "msDS-KeyCredentialLink"
    }
    return $MSKeyCredExists
}