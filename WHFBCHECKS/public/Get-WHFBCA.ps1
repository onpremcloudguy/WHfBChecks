function get-WHFBCA {
    $ConfigContext = ([ADSI]"LDAP://RootDSE").ConfigurationNamingContext
    $CA = ([ADSI]"LDAP://CN=CDP,CN=Public Key Services,CN=Services,$ConfigContext").Children
    
    if ($ca.Children.cn.count -gt 1) {
        $res = [System.Collections.ArrayList]::new()
        foreach ($c in $ca) {
            $CASvr = get-adcomputer $c.cn -properties *
            $caa = [PSCustomObject]@{
                Name    = $c.cn
                CAName  = $c.children.cn[0]
                OSVer   = [decimal]$CASvr.OperatingSystemVersion.split(' ')[0]
            }
            $res.Add($caa) | out-null
        }
    }
    elseif ($ca.Children.cn.count -eq 1) {
        $CASvr = get-adcomputer $ca.cn -properties *
        $caa = [PSCustomObject]@{
            Name    = $ca.cn
            CAName  = $ca.children.cn[0]
            OSVer   = [decimal]$CASvr.OperatingSystemVersion.split(' ')[0]
        }
        $res = $caa
    }
    return $res
}