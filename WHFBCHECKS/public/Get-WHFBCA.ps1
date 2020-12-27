function get-WHFBCA {
    $ConfigContext = ([ADSI]"LDAP://RootDSE").ConfigurationNamingContext
    $CA = ([ADSI]"LDAP://CN=CDP,CN=Public Key Services,CN=Services,$ConfigContext").Children
    $res = [System.Collections.ArrayList]::new()
    if ($ca.Children.cn.count -gt 1) {
        foreach ($c in $ca) {
            $caa = [PSCustomObject]@{
                Name    = $c.cn
                SVRName = $c.children.cn[0]
            }
            $res.Add($caa)
        }
    }
    else {
        $caa = [PSCustomObject]@{
            Name    = $ca.cn
            SVRName = $ca.children.cn[0]
        }
        $res.Add($caa)
    }
    return $res
}