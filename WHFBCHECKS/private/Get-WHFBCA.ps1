<#
.SYNOPSIS

This function will connect to Active Directory and return the registered Certificate Authorities.

#>
function get-WHFBCA {
    $ConfigContext = ([ADSI]"LDAP://RootDSE").ConfigurationNamingContext
    $CA = ([ADSI]"LDAP://CN=CDP,CN=Public Key Services,CN=Services,$ConfigContext").Children
    
    if ($ca.Children.cn.count -gt 1) {
        $res = [System.Collections.ArrayList]::new()
        foreach ($c in $ca) {
            try {
                $CASvr = get-adcomputer $c.cn.ToString() -properties *
                $caa = [PSCustomObject]@{
                    Name    = $c.cn
                    CAName  = $c.children.cn[0]
                    OSVer   = [decimal]$CASvr.OperatingSystemVersion.split(' ')[0]
                }
                $res.Add($caa) | out-null
            }
            catch {
            }
        }
    }
    elseif ($ca.Children.cn.count -eq 1) {
        try {
            $CASvr = get-adcomputer $ca.cn -properties *
            $caa = [PSCustomObject]@{
                Name    = $ca.cn
                CAName  = $ca.children.cn[0]
                OSVer   = [decimal]$CASvr.OperatingSystemVersion.split(' ')[0]
            }
            $res = $caa
        }
        catch {
        }
    }
    return $res
}
