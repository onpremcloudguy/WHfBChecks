function Get-WHFBADKeyAdminsmembers {
    $keyadmingrp = get-adgroup -Identity "Key Admins" -ErrorAction SilentlyContinue
    $keyadmingrpmembers = $null
    if($keyadmingrp){
        $keyadmingrpmembers = $keyadmingrp | Get-ADGroupMember
    }
    return $keyadmingrpmembers
}