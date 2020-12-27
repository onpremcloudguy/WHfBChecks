function Get-WHFBADSyncNGCSync {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $Computername
    )
    $MSKeyCredSync = $false
    if ($PSBoundParameters.ContainsKey('Computername')) {
        $MSKeyCredSync = Invoke-Command -ComputerName $Computername -ScriptBlock {
            (Get-ADSyncRule | Where-Object {$_.AttributeFlowMappings.destination -eq "msDS-KeyCredentialLink" -and $_.disabled -eq $false}).count -gt 0
        } -Credential (Get-Credential)
    } else
    {
        $MSKeyCredSync = (Get-ADSyncRule | Where-Object {$_.AttributeFlowMappings.destination -eq "msDS-KeyCredentialLink" -and $_.disabled -eq $false}).count -gt 0
    }
    return $MSKeyCredSync
}