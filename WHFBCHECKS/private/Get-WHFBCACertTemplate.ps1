<#
.SYNOPSIS

This function will connect to Active Directory and return the certificate template that includes the required settings.

#>
function Get-WHFBCACertTemplate {
    $ConfigContext = ([ADSI]"LDAP://RootDSE").ConfigurationNamingContext
    ([ADSI]"LDAP://CN=Certificate Templates,CN=Public Key Services,CN=Services,$ConfigContext").Children | Where-Object { $_.pKIExtendedKeyUsage -contains "1.3.6.1.5.2.3.5" -and $_.cn -notcontains "KerberosAuthentication" }
}