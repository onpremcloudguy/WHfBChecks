function Ge-WHFBAADUser {
    param (
        [string]
        $UPN,
        [string]
        $sAMAccountName,
        [string]
        $DomainNetBiosName
    )
    if (!(get-module -ListAvailable MSOnline)) {
        install-module MSOnline -scope CurrentUser
    }
    if (!(Get-Module -ListAvailable WHfBTools)) {
        install-module WHfBTools -Scope CurrentUser
    }
    import-module MSOnline
    $module = Get-Module MSOnline
    add-type -path "$($module.ModuleBase)\Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
    $AuthSessions = [Microsoft.IdentityModel.Clients.ActiveDirectory.TokenCache]::DefaultShared.ReadItems()
    $authed = $false
    foreach ($AuthSession in $AuthSessions) {
        if ($AuthSession.clientid -eq "1b730954-1685-4b74-9bfd-dac224a7b894") {
            if ($AuthSession.expireson -gt (Get-Date)) {
                $authed = $true
            }
        }
    }
    if (!$authed) {
        Connect-MsolService
        $AuthSessions = [Microsoft.IdentityModel.Clients.ActiveDirectory.TokenCache]::DefaultShared.ReadItems()
    }
    $auths = $AuthSessions | where-object { $_.ClientId -eq "1b730954-1685-4b74-9bfd-dac224a7b894" } | Select-Object -Last 1
    $authHeader = @{
        'Content-Type'  = 'application/json'
        'Authorization' = $($Auths.AccessToken)
        'ExpiresOn'     = $Auths.ExpiresOn
    }
    $gu = (Invoke-WebRequest -Method get -Uri "https://graph.microsoft.com/beta/users/$UPN" -Headers $authHeader -UseBasicParsing).content | ConvertFrom-Json
    $devices = [System.Collections.ArrayList]::new()
    if ((get-member -InputObject $gu).name -contains "devicekeys") {
        foreach ($d in $GU.devicekeys) {
            $device = Get-MsolDevice -DeviceId $d.deviceid
            if ($device) {
                $devices.add($device)
            }
        }
    }
    $aduser = Get-ADWHfBKeys -Domain $DomainNetBiosName -SamAccountName $sAMAccountName -skipcheckfororphanedkeys
    Write-Output "ADUser:$($aduser.KeyDeviceID)`n`rKey:$($aduser.KeyMaterial)"
    write-output "AADUser:$($GU.devicekeys.deviceid)`n`rKey:$($GU.devicekeys.keymaterial)"
}