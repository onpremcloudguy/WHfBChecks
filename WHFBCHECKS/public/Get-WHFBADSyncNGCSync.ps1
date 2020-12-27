function Get-WHFBADSyncNGCSync {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $Computername
    )
    $MSKeyCredSync = $false
    if ($PSBoundParameters.ContainsKey('Computername')) {
        $MSKeyCredSync = invoke-command -computername $Computername -scriptblock {
            (get-adsyncrule | where-object {$_.AttributeFlowMappings.destination -eq "msDS-KeyCredentialLink" -and $_.disabled -eq $false}).count -gt 0
        } -Credential (Get-Credential)
    } else
    {
        $MSKeyCredSync = (get-adsyncrule | where-object {$_.AttributeFlowMappings.destination -eq "msDS-KeyCredentialLink" -and $_.disabled -eq $false}).count -gt 0
    }
    return $MSKeyCredSync
}