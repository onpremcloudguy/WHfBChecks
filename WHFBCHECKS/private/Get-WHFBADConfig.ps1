<#
.SYNOPSIS

This will return the FQDN and NetBiosName from the local domain

.OUTPUTS

Returns a subsection of the Get-ADDomain object
#>
function Get-WHFBADConfig {
    Get-ADDomain | Select-Object DNSRoot, NetBiosName
}