function Get-WHFBAACCurrentVersion {
    $regex = [regex] "\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b"
    $AADConnectRelWR = Invoke-RestMethod -Method Get -Uri "https://raw.githubusercontent.com/MicrosoftDocs/azure-docs/master/articles/active-directory/hybrid/reference-connect-version-history.md" -UseBasicParsing
    $AADConnectReleases = $regex.matches(($AADConnectRelWR.split("\n\r"))).value | Sort-Object -Descending -Unique
    return $AADConnectReleases
}