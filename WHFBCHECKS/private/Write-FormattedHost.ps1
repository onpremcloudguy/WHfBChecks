<#
.SYNOPSIS

Will create a formatted string so when error it's not a wall of Red text.

.DESCRIPTION

This function will split the text into 3 parts, the "Message" in Cyan, the "ResultMessage" colour coded based upon the "ResultState" (Pass = Green, Fail = Red, Warning = Magenta)

.EXAMPLE

PS C:\>Write-FormattedHost -Message "This test was:" -ResultState Pass -ResultMessage "Successful"

PS C:\>Write-FormattedHost -Message "This test was:" -ResultState Fail -ResultMessage "Unsuccessful" -AdditionalInfo "Find more information here: https://docs.ms"
#>
function Write-FormattedHost {
    [cmdletbinding()]
    param (
        #Message is the first part of the string you want returned
        [parameter(Mandatory = $true)]
        [string]$Message,
        #ResultState has the possible entries of 'Pass', 'Fail', 'Warning' to control the colour of the ResultMessage text in the message string.
        [parameter(Mandatory = $false)]
        [ValidateSet('Pass', 'Fail', 'Warning')]
        [string]$ResultState = 'Pass',
        #ResultMessage is the descriptive section of the string, that highlights pass/fail/warning
        [parameter(Mandatory = $true)]
        [string]$ResultMessage,
        #AdditionalInfo is to allow the option for further reading like a website.
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