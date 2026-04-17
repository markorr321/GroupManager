# GroupManager

A PowerShell module for managing Entra ID security group membership.

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

## Installation

Current user:
```powershell
Install-Module GroupManager -Scope CurrentUser
```

All users (requires admin):
```powershell
Install-Module GroupManager -Scope AllUsers
```

## Cmdlets

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



## Configuration

### Configure Custom App Registration

```powershell
Set-GroupManagerAuth
```

This prompts for:
- **Client ID** - Your app registration's Application (client) ID
- **Tenant ID** - Your Azure AD tenant ID

Configuration is saved as user-level environment variables.

See [Custom App Registration](Custom%20App%20Registration/README.md) for setup instructions.

### Configure Groups

```powershell
Set-GroupManagerGroup
```

```powershell
Set-GroupManagerGroup -ObjectId "07a94b39-cfee-41bd-a76f-187b3161696a"
```

```powershell
Set-GroupManagerGroup -ObjectId "guid1", "guid2", "guid3"
```

Groups are saved to `%LOCALAPPDATA%\GroupManager\config.json`.

### Clear Configurations

```powershell
Clear-GroupManagerConfig
```

```powershell
Clear-GroupManagerAuth
```

## Requirements

- PowerShell 5.1+ (PowerShell 7+ recommended)
- Microsoft Graph PowerShell modules:
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
