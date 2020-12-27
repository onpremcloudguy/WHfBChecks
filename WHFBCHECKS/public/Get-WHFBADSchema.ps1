function Get-WHFBADSchema {
    $schemaVersion = (Get-ADObject (Get-ADRootDSE).schemaNamingContext -Property objectVersion).ObjectVersion
    $schemaOS = switch ($schemaVersion){
        13 {"Windows Server 2000","Unsupported"}
        30 {"Windows Server 2003","Unsupported"}
        31 {"Windows Server 2003 R2","Unsupported"}
        44 {"Windows Server 2008","Unsupported"}
        47 {"Windows Server 2008 R2","Unsupported"}
        56 {"Windows Server 2012","Unsupported"}
        69 {"Windows Server 2012 R2","Unsupported"}
        87 {"Windows Server 2016","Supported"}
        88 {"Windows Server 2019","Supported"}
    }
    return [PSCustomObject]@{
        OperatingSystem = $schemaOS[0]
        Supported       = $schemaOS[-1]
    }
}