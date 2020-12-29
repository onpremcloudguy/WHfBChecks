function Get-RegistryValueData {
    [CmdletBinding(SupportsShouldProcess=$True,
        ConfirmImpact='Medium',
        HelpURI='http://vcloud-lab.com')]
    Param
    ( 
        [parameter(Position=0, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        [alias('C')]
        [String[]]$ComputerName,
        [Parameter(Position=1, Mandatory=$True, ValueFromPipelineByPropertyName=$True)] 
        [alias('Hive')]
        [ValidateSet('ClassesRoot', 'CurrentUser', 'LocalMachine', 'Users', 'CurrentConfig')]
        [String]$RegistryHive,
        [Parameter(Position=2, Mandatory=$True, ValueFromPipelineByPropertyName=$True)]
        [alias('KeyPath')]
        [String]$RegistryKeyPath,
        [parameter(Position=3, Mandatory=$True, ValueFromPipelineByPropertyName=$true)]
        [alias('Value')]
        [String]$ValueName
    )
    Begin {
        $RegistryRoot= "[{0}]::{1}" -f 'Microsoft.Win32.RegistryHive', $RegistryHive
        try {
            $RegistryHive = Invoke-Expression $RegistryRoot -ErrorAction Stop
        }
        catch {
            Write-Host "Incorrect Registry Hive mentioned, $RegistryHive does not exist" 
        }
    }
    Process {
        Foreach ($Computer in $ComputerName) {
            if (Test-Connection $computer -Count 2 -Quiet) {
                $reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($RegistryHive, $Computer)
                $key = $reg.OpenSubKey($RegistryKeyPath)
                $Data = $key.GetValue($ValueName)
                $Obj = New-Object psobject
                $Obj | Add-Member -Name Computer -MemberType NoteProperty -Value $Computer
                $Obj | Add-Member -Name RegistryValueName -MemberType NoteProperty -Value "$RegistryKeyPath\$ValueName"
                $Obj | Add-Member -Name RegistryValueData -MemberType NoteProperty -Value $Data
                $Obj
            }
            else {
                Write-Host "$Computer not reachable" -BackgroundColor DarkRed
            }
        }
    }
    End {
        #[Microsoft.Win32.RegistryHive]::ClassesRoot
        #[Microsoft.Win32.RegistryHive]::CurrentUser
        #[Microsoft.Win32.RegistryHive]::LocalMachine
        #[Microsoft.Win32.RegistryHive]::Users
        #[Microsoft.Win32.RegistryHive]::CurrentConfig
    }
}
#$Computername = ""
#$CAName = ""

Get-RegistryValueData -ComputerName $computername -RegistryHive localmachine -RegistryKeyPath "SYSTEM\CurrentControlSet\Services\CertSvc\Configuration\$caname" -value "ValidityPeriodUnits"
Get-RegistryValueData -ComputerName $computername -RegistryHive localmachine -RegistryKeyPath "SYSTEM\CurrentControlSet\Services\CertSvc\Configuration\$caname" -value "ValidityPeriod" #How long is it valid for
Get-RegistryValueData -ComputerName $computername -RegistryHive localmachine -RegistryKeyPath "SYSTEM\CurrentControlSet\Services\CertSvc\Configuration\$caname" -value "ParentCAMachine" #if exists needs to be flagged to check if it's online and find the CRL
Get-RegistryValueData -ComputerName $computername -RegistryHive localmachine -RegistryKeyPath "SYSTEM\CurrentControlSet\Services\CertSvc\Configuration\$caname" -value "ParentCAName" #if exists needs to be flagged to check if it's online and find the CRL
Get-RegistryValueData -ComputerName $computername -RegistryHive localmachine -RegistryKeyPath "SYSTEM\CurrentControlSet\Services\CertSvc\Configuration\$caname\EncryptionCSP" -value "KeySize" #Should be 2048
Get-RegistryValueData -ComputerName $computername -RegistryHive localmachine -RegistryKeyPath "SYSTEM\CurrentControlSet\Services\CertSvc\Configuration\$caname\CSP" -value "Provider" #should be "Microsoft Software Key Storage Provider"
Get-RegistryValueData -ComputerName $computername -RegistryHive localmachine -RegistryKeyPath "SYSTEM\CurrentControlSet\Services\CertSvc\Configuration\$caname\CSP" -value "CNGHashAlgorithm" #should be SHA256
Get-RegistryValueData -ComputerName $computername -RegistryHive localmachine -RegistryKeyPath "SOFTWARE\Microsoft\Windows NT\CurrentVersion" -value "CurrentBuild" #should be -ge 9200