function Get-WHFBADFunctionalLevel {
    $DMode = (Get-ADDomain).DomainMode
    $DomainMode = switch ($dmode.value__) {
        1 { "Windows 2000 Domain", "NotSupported" }
        2 { "Windows 2003 Domain", "NotSupported" }
        3 { "Windows 2008 Domain", "NotSupported" }
        4 { "Windows 2008R2 Domain", "Supported" }
        5 { "Windows 2012 Domain", "Supported" }
        6 { "Windows 2012R2 Domain", "Supported" }
        7 { "Windows 2016 Domain", "Supported" }
    }
    $FMode = (Get-ADForest).ForestMode
    $ForestMode = switch ($fmode.value__) {
        1 { "Windows 2000 Forest", "NotSupported" }
        2 { "Windows 2003 Forest", "NotSupported" }
        3 { "Windows 2008 Forest", "NotSupported" }
        4 { "Windows 2008R2 Forest", "Supported" }
        5 { "Windows 2012 Forest", "Supported" }
        6 { "Windows 2012R2 Forest", "Supported" }
        7 { "Windows 2016 Forest", "Supported" }
    }
    return [PSCustomObject]@{
        Domain = $DomainMode
        Forest = $ForestMode        
    }
}