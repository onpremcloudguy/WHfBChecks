Function Get-WHFBCACRLValid {
    [CmdletBinding()]
    Param
    (
        [Parameter()]
        [Byte[]]
        $CRL
    )
    process {
        $OIDCommonName = " 06 03 55 04 03 "
        $UTCTime = " 17 0D "
        $CRLHexString = ($CRL | ForEach-Object { "{0:X2}" -f $_ }) -join " "
        $CNNameBytes = ($CRLHexString -split $OIDCommonName )[1] -split " " | ForEach-Object { [Convert]::ToByte("$_", 16) }
        $ThisUpdateBytes = ($CRLHexString -split $UTCTime )[1] -split " "  | ForEach-Object { [Convert]::ToByte("$_", 16) }
        $NextUpdateBytes = (($CRLHexString -split $UTCTime )[2] -split " ")[0..12] | ForEach-Object { [Convert]::ToByte("$_", 16) }
        $CAName = ($CNNameBytes[2..($CNNameBytes[1] + 1)] | ForEach-Object { [char]$_ }) -join ""
        $ThisUpdate = [Management.ManagementDateTimeConverter]::ToDateTime(("20" + $(($ThisUpdateBytes | ForEach-Object { [char]$_ }) -join "" -replace "z")) + ".000000+000")
        $NextUpdate = [Management.ManagementDateTimeConverter]::ToDateTime(("20" + $(($NextUpdateBytes | ForEach-Object { [char]$_ }) -join "" -replace "z")) + ".000000+000")
        $isvalid = ($nextUpdate -gt (get-date))
        [pscustomobject]@{
            CAName     = $CAName
            ThisUpdate = $ThisUpdate
            NextUpdate = $NextUpdate
            isValid    = $isvalid
        }
    }
}