# GroupManager

A PowerShell tool for managing Entra ID security group membership. Available as a standalone script or a PowerShell Gallery module.

![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue.svg)
![Platform](https://img.shields.io/badge/Platform-Windows-lightgrey.svg)
![Gallery](https://img.shields.io/powershellgallery/v/GroupManager.svg)

## Features

- Add users to groups by UPN (email)
- Remove users from groups by UPN
- List all current group members with quick removal
- Interactive menu-driven TUI
- Configure multiple groups by Object ID
- Support for custom app registration authentication
- Non-interactive cmdlets for scripting and automation
- Auto-install Microsoft Graph modules if missing

## Quick Start

### PowerShell Gallery (Recommended)

```powershell
Install-Module GroupManager -Scope CurrentUser
```

```powershell
Set-GroupManagerGroup
```

```powershell
Start-GroupManager
```

### Standalone Script

```powershell
.\GroupManager.ps1 -Setup
```

```powershell
.\GroupManager.ps1
```

## Installation

### Option 1: PowerShell Gallery

Current user:
```powershell
Install-Module GroupManager -Scope CurrentUser
```

All users (requires admin):
```powershell
Install-Module GroupManager -Scope AllUsers
```

### Option 2: Standalone script

Run `GroupManager.ps1` directly, or install it to your PowerShell profile:

```powershell
.\GroupManager.ps1 -Install
```

Then run `GroupManager` from any PowerShell window.

## Module Cmdlets

| Cmdlet | Description |
|--------|-------------|
| `Start-GroupManager` | Launch the interactive TUI |
| `Connect-GroupManager` | Connect to Microsoft Graph |
| `Set-GroupManagerGroup` | Configure groups (interactive or with -ObjectId) |
| `Set-GroupManagerAuth` | Configure custom app registration |
| `Get-GroupManagerConfig` | View current group configuration |
| `Get-GroupManagerMember` | List members of a group |
| `Add-GroupManagerMember` | Add a user to a group by UPN |
| `Remove-GroupManagerMember` | Remove a user from a group by UPN |
| `Clear-GroupManagerConfig` | Remove saved group configuration |
| `Clear-GroupManagerAuth` | Remove saved app registration configuration |

### Scripting Examples

```powershell
Connect-GroupManager
```

```powershell
Get-GroupManagerMember -GroupId "88626840-b24d-417e-aca5-18f224b081d7"
```

```powershell
Add-GroupManagerMember -GroupId "88626840-..." -UserPrincipalName "user@contoso.com"
```

```powershell
Remove-GroupManagerMember -GroupId "88626840-..." -UserPrincipalName "user@contoso.com"
```

```powershell
Get-GroupManagerMember -GroupId "88626840-..." | Format-Table
```

## Configuration

### Configure Groups

**Module:**
```powershell
Set-GroupManagerGroup
```

```powershell
Set-GroupManagerGroup -ObjectId "07a94b39-cfee-41bd-a76f-187b3161696a"
```

```powershell
Set-GroupManagerGroup -ObjectId "guid1", "guid2", "guid3"
```

**Standalone script:**
```powershell
.\GroupManager.ps1 -Setup
```

```powershell
.\GroupManager.ps1 -Setup -ObjectId "07a94b39-cfee-41bd-a76f-187b3161696a"
```

Groups are saved to `%LOCALAPPDATA%\GroupManager\config.json`.

### Configure Custom App Registration

**Module:**
```powershell
Set-GroupManagerAuth
```

**Standalone script:**
```powershell
.\GroupManager.ps1 -Configure
```

This prompts for:
- **Client ID** - Your app registration's Application (client) ID
- **Tenant ID** - Your Azure AD tenant ID

Configuration is saved as user-level environment variables.

#### Creating the App Registration

1. Go to the [Azure Portal](https://portal.azure.com) > **Microsoft Entra ID** > **App registrations**
2. Click **New registration**
3. Enter a name (e.g. `GroupManager`)
4. Set **Supported account types** to *Accounts in this organizational directory only (Single tenant)*
5. Leave **Redirect URI** blank for now and click **Register**
6. Copy the **Application (client) ID** and **Directory (tenant) ID** from the Overview page
7. Go to **Authentication** > **Add a platform** > **Mobile and desktop applications**
8. Add the following Redirect URI:
   ```
   ms-appx-web://Microsoft.AAD.BrokerPlugin/afc072ee-5353-4b0c-a487-de0ae2c0b500
   ```
9. Under **Advanced settings** on the Authentication page, set **Allow public client flows** to **Yes** and click **Save**
10. Go to **API permissions** > **Add a permission** > **Microsoft Graph** > **Delegated permissions**
11. Add the following permissions:
    - `User.Read`
    - `User.Read.All`
    - `GroupMember.ReadWrite.All`
12. Click **Grant admin consent** (requires admin privileges)

#### Required API Permissions (Delegated)

| Permission | Description |
|------------|-------------|
| User.Read | Sign in and read user profile |
| User.Read.All | Read all users' full profiles |
| GroupMember.ReadWrite.All | Read and write group memberships |

### Clear Configurations

**Module:**
```powershell
Clear-GroupManagerConfig
```

```powershell
Clear-GroupManagerAuth
```

**Standalone script:**
```powershell
.\GroupManager.ps1 -ClearConfig
```

```powershell
.\GroupManager.ps1 -ClearAuth
```

## Standalone Script Parameters

| Parameter | Description |
|-----------|-------------|
| `-Install` | Add GroupManager function to your PowerShell profile |
| `-Setup` | Configure groups to manage (interactive or with -ObjectId) |
| `-ObjectId` | Group Object ID(s) to add (use with -Setup) |
| `-Configure` | Configure custom app registration for authentication |
| `-ClearAuth` | Remove saved app registration configuration |
| `-ClearConfig` | Remove saved group configuration |

## Requirements

- PowerShell 5.1+ (PowerShell 7+ recommended)
- Microsoft Graph PowerShell modules (auto-installed if using the standalone script, auto-required if using the module):
  - Microsoft.Graph.Authentication
  - Microsoft.Graph.Groups
  - Microsoft.Graph.Users

## Screenshots

```
[ E N T R A   I D   G R O U P   M A N A G E R ]  v1.3

Manage Group Membership - Target: My-Security-Group

  SELECT AN OPTION

    [1] Add group member
    [2] Remove group member
    [3] List group members
    [4] Switch group
    [5] Manage configured groups
    [6] Exit

  Select option (1-6):
```

## License

MIT

## Author

Mark Orr
