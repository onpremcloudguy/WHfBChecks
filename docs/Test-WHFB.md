---
external help file: WHFBCHECKS-help.xml
Module Name: WHFBCHECKS
online version:
schema: 2.0.0
---

# Test-WHFB

## SYNOPSIS

This function allows for you to interrogate your identity platform to validate if it is ready to enable Windows Hello for Business (WHFB) - Hybrid Key-Trust method

## SYNTAX

```PowerShell
Test-WHFB [[-Creds] <PSCredential>] [<CommonParameters>]
```

## DESCRIPTION

This function will reach out to

- Active Directory, and obtain the following:  
  - Directory Schema version  
  - Domain and Forest functional level  
  - List of Domain Controllers, on each we check:  
    - Operating System Version  
    - Certificate  
      - Issuing Certificate Template  
      - CRLDP address  
      - SAN address  
      - Encryption provider  
  - Member of Key Admins group  
  - Registered Certificate Authorities  
  - All Certificate Templates that meet the requirements for WHFB

- Azure Active Directory, and obtain the following:  
  - AAD Connect Server Name  
  - AAD Connect Sync status  
  - AAD Connect last sync time

- Azure Active Directory Connect, and obtain the following:  
  - AAD Connect Version  
  - AAD Connect AD Sync Account  
  - AAD Connect Schema check for "msDS-KeyCredentialLink" and if it is Syncing

## EXAMPLES

### Example 1

```PowerShell
PS C:\> Test-WHFB -Creds (Get-Credential)
```

Will run the Test function using credentials captured from the Get-Credential cmdlet

## PARAMETERS

### -Creds

An admin account that has access to Domain Controllers, AAD Connect Server, and Certificate Authority

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
