function Get-WHFBADSyncNGCProp {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $Computername,
        [Parameter(Mandatory=$false)]
        [pscredential]
        $Creds
    )
    if ($PSBoundParameters.ContainsKey('Creds')){
        $cred = $creds 
    } else {
        $cred = Get-Credential
    }
    $MSKeyCredExists = $false
    if ($PSBoundParameters.ContainsKey('Computername')) {
        $MSKeyCredExists = Invoke-Command -ComputerName $Computername -ScriptBlock {
            $ADSyncConnector = Get-ADSyncConnector | Where-Object { $_.type -eq "AD" }
            $ADSyncConnector.AttributeInclusionList -contains "msDS-KeyCredentialLink"
        } -Credential $cred
    } else
    {
        $ADSyncConnector = Get-ADSyncConnector | Where-Object { $_.type -eq "AD" }
        $MSKeyCredExists = $ADSyncConnector.AttributeInclusionList -contains "msDS-KeyCredentialLink"
    }
    return $MSKeyCredExists
}