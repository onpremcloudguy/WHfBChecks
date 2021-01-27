<#
.SYNOPSIS

This function will return a list of Domain Controllers from the current domain

.DESCRIPTION

The function will return a subset of the Get-ADDomainController function, with the supported property for WHFB Hybrid Key trust added.

.OUTPUTS

It will return an Array of Domain Controllers from the current domain
#>
function Get-WHFBADDCs {
    $dcs = Get-ADDomainController -Filter * | Select-Object hostname, ipv4address, OperatingSystem, OperatingSystemVersion, OperationMasterRoles, Enabled
    foreach ($dc in $dcs) {
        if ([int]$dc.OperatingSystemversion.split('(')[0].trimend() -gt 6.1) {
            $dc | Add-Member -MemberType NoteProperty -Name "Supported" -Value $true
        }
        else {
            $dc | Add-Member -MemberType NoteProperty -Name "Supported" -Value $false
        }
    }
    return $dcs
}