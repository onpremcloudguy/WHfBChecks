function Get-WHFBADConfig {
    Get-ADDomain | Select-Object DNSRoot, NetBiosName
}