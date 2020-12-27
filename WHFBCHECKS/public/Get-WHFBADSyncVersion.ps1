function get-WHFBADSyncVersion {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]
        $Computername
    )
    $AADConnectVersion = $null
    $res = ""
    if ($PSBoundParameters.ContainsKey('Computername')) {
        $AADConnectVersion = Invoke-Command -ComputerName $Computername -ScriptBlock {(Get-Item (Join-Path (Get-Module ADSync -ListAvailable).modulebase "Microsoft.IdentityManagement.PowerShell.Cmdlet.dll")).VersionInfo.productversion} -Credential (Get-Credential)
    }
    else {
        $AADConnectVersion = (get-item (Join-Path (Get-Module ADSync -ListAvailable).modulebase "Microsoft.IdentityManagement.PowerShell.Cmdlet.dll")).VersionInfo.productversion
    }
    $regex = [regex] "\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b"
    $AADConnectRelWR = Invoke-RestMethod -Method Get -Uri "https://raw.githubusercontent.com/MicrosoftDocs/azure-docs/master/articles/active-directory/hybrid/reference-connect-version-history.md" -UseBasicParsing
    $AADConnectReleases = $regex.matches(($AADConnectRelWR.split("\n\r"))).value | Sort-Object -Descending -Unique
    $AADConnectLatestVer = $AADConnectReleases | Select-Object -First 1
    if($AADConnectVersion -in $AADConnectReleases){
        if($AADConnectVersion -eq $AADConnectLatestVer){
            $res = "No work Required"
        }
        else {
            $res = "Please Update your AAD Connect Version from $AADConnectVersion to $AADConnectLatestVer"
        }
    }
         else {
            $res = "You have a really old version of AAD Connect, please upgrade from $AADConnectVersion"
        }

    return $res
}