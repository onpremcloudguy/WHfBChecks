function Get-WHFBADSyncNGCSync {
    [CmdletBinding()]
    param (
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
    $MSKeyCredSync = $false
    if ($PSBoundParameters.ContainsKey('Computername')) {
        $MSKeyCredSync = Invoke-CommandAs -ComputerName $Computername -ScriptBlock {
            (Get-ADSyncRule | Where-Object { $_.AttributeFlowMappings.destination -eq "msDS-KeyCredentialLink" -and $_.disabled -eq $false }).count -gt 0
        } -Credential $cred -AsSystem
    }
    else {
        $MSKeyCredSync = (Get-ADSyncRule | Where-Object { $_.AttributeFlowMappings.destination -eq "msDS-KeyCredentialLink" -and $_.disabled -eq $false }).count -gt 0
    }
    return $MSKeyCredSync
}