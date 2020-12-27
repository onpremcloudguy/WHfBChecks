function Get-WHFBADDCs {
    $dcs = Get-ADDomainController -Filter * | select-object hostname, ipv4address, OperatingSystem, OperatingSystemVersion, OperationMasterRoles, Enabled
    $i = 0
    foreach ($dc in $dcs) {
        if ([int]$dc.OperatingSystemversion.split('(')[0].trimend() -gt 6.1) {
            $dcs[$i] | add-member -membertype NoteProperty -name "Supported" -value $true
        }
        else {
            $dcs[$i] | add-member -membertype NoteProperty -name "Supported" -value $false
        }
        $i++
    }
    return $dcs
}