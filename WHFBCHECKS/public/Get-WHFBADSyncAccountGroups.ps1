function Get-WHFBADSyncAccountGroups {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $username
    )
    Get-ADPrincipalGroupMembership $username | Select-Object Name
}