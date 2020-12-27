# WHfBChecks
A group of PowerShell scripts to check that your environment is ready for Windows Hello for Business - Hybrid Key Trust

Needs to have the RSAT Active Directory tools enabled.

- Get-WHFBADSyncVersion:        This will return the version of AAD Connect that you have installed
- Get-WHFBADSyncAccount:        This will return the user account AAD Connect uses to sync to Active Directory
- Get-WHFBADSyncAccountGroups:  This will return the Group Membership for the AAD Connect AD Sync account (should be a member of Key Admins group)
- Get-WHFBADSchema:             This will return the Active Directory Schema
- Get-WHFBADKeyAdmins:          This will check if the Key Admins group exists in AD (gets created when the FSMO roles land on a 2016 domain controller)
- Get-WHFBADSyncNGCSync:        This will check to see if the NGC object is syncing to the MS-KeyCredentialLink property
- Get-WHFBADSyncNGCProp:        This will check to see if the AAD Connect Schema supports syncing NGC to MS-KeyCredentialLink
- Get-WHFBADDCs:                This will return all Domain Controllers in the domain, limited to include only name, IP, OS version, FSMO, enabled, and if the DC is supported.