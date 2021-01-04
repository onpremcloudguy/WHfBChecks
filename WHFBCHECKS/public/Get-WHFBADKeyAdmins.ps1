function Get-WHFBADKeyAdmins {
    $keyAdminGrp = Get-ADGroup -Identity "Key Admins" -ErrorAction SilentlyContinue
    $keyAdminGrpMembers = $null
    if($keyAdminGrp){
        $keyAdminGrpMembers = $keyAdminGrp | Get-ADGroupMember
    }
    return $keyAdminGrpMembers
}