<#
.SYNOPSIS

This will query the Docs page for the latest version of AAD Connect

.DESCRIPTION

This function will query this address: https://raw.githubusercontent.com/MicrosoftDocs/entra-docs/main/docs/identity/hybrid/connect/reference-connect-version-history.md and perform a regex to return the list of all supported versions of AAD Connect.
#>
function Get-WHFBAACCurrentVersion {
    $regex = [regex] "## ((?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)"
    $AADConnectRelWR = Invoke-RestMethod -Method Get -Uri "https://raw.githubusercontent.com/MicrosoftDocs/entra-docs/main/docs/identity/hybrid/connect/reference-connect-version-history.md" -UseBasicParsing
    [version[]]$AADConnectReleases = $regex.matches(($AADConnectRelWR.split("\n\r"))).value | ForEach-Object {$_.trim("## ")}
    [version[]]$AADConnectReleases = $AADConnectReleases | Sort-Object -Descending -Unique
    return [string[]]$AADConnectReleases
}
