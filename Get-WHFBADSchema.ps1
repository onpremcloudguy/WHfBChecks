function get-WHFBADSchema {
    $schemaversion = (get-adobject (get-adrootdse).schemaNamingContext -Property objectVersion).objectVersion
    $SchemaOS = switch ($schemaversion){
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
    return $SchemaOS
}