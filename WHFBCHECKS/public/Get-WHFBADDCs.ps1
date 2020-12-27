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