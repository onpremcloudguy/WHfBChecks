function Get-WHFBADDCs {
    Get-ADDomainController -Filter * | select-object hostname, ipv4address, OperatingSystem, OperatingSystemVersion, OperationMasterRoles, Enabled
}