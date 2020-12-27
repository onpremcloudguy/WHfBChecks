function get-WHFBCA {
    $ConfigContext = ([ADSI]"LDAP://RootDSE").ConfigurationNamingContext
    $CA = ([ADSI]"LDAP://CN=CDP,CN=Public Key Services,CN=Services,$ConfigContext").children
    $res = @()
    if ($ca.Children.cn.count -gt 1) {
        foreach ($c in $ca) {
            $caa = New-Object -TypeName PSObject
            $caa | Add-Member -name "Name" -MemberType NoteProperty -value $c.cn
            $caa | add-member -name "SVRName" -membertype NoteProperty -value $c.children.cn[0]
            $res += $caa
        }
    }
    else {
        $caa = New-Object -TypeName PSObject
        $caa | Add-Member -name "Name" -MemberType NoteProperty -value $ca.cn
        $caa | add-member -name "SVRName" -membertype NoteProperty -value $ca.children.cn[0]
        $res += $caa
    }
    return $res
}