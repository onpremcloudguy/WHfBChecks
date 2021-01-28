---
Module Name: WHFBCHECKS
Module Guid: 41fbee28-3435-4b89-88f8-889a8d9cfc8c
Download Help Link: {{ Update Download Link }}
Help Version: {{ Please enter version of help manually (X.X.X.X) format }}
Locale: en-US
---

# WHFBCHECKS Module

## Description

This module allows for you to interrogate your identity platform to validate if it is ready to enable Windows Hello for Business (WHFB) - Hybrid Key-Trust method

## WHFBCHECKS Cmdlets

### [Test-WHFB](Test-WHFB.md)

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