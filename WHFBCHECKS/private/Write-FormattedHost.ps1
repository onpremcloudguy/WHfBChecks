function Write-FormattedHost {
    [cmdletbinding()]
    param (
        [parameter(Mandatory = $true)]
        [string]$Message,

        [parameter(Mandatory = $false)]
        [ValidateSet('Pass','Fail','Warning')]
        [string]$ResultState = 'Pass',

        [parameter(Mandatory = $true)]
        [string]$ResultMessage,

        [parameter(Mandatory = $false)]
        [string]$AdditionalInfo
    )
    $fgColor = switch ($ResultState) {
        'Pass' { 'Green' }
        'Fail' { 'Red' }
        'Warning' { 'Magenta' }
        default { 'Green' }
    }
    Write-Host $Message -NoNewline -ForegroundColor Cyan
    Write-Host " $ResultMessage" -ForegroundColor $fgColor
    if ($AdditionalInfo) {
        Write-Host "`n$AdditionalInfo" -ForegroundColor Yellow
    }
}