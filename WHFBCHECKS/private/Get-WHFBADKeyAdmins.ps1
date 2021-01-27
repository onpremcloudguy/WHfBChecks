<#
.SYNOPSIS

This will return the user accounts that are a member of the "Key Admins" group from the local domain.
#>
function Get-WHFBADKeyAdmins {
    $keyAdminGrp = Get-ADGroup -Identity "Key Admins" -ErrorAction SilentlyContinue
    $keyAdminGrpMembers = $null
    if($keyAdminGrp){
        $keyAdminGrpMembers = $keyAdminGrp | Get-ADGroupMember
    }
    return $keyAdminGrpMembers
}