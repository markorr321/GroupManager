# GroupManager

A PowerShell terminal UI for managing Entra ID security group membership.

![PowerShell](https://img.shields.io/badge/PowerShell-7.0+-blue.svg)
![Platform](https://img.shields.io/badge/Platform-Windows-lightgrey.svg)

## Features

- Add users to groups by UPN (email)
- Remove users from groups by UPN
- List all current group members with quick removal
- Interactive menu-driven interface
- Configure multiple groups by Object ID
- Support for custom app registration authentication
- Auto-install Microsoft Graph modules if missing
- Self-install to PowerShell profile for easy access

## Quick Start

```powershell
# First run: Configure the groups you want to manage
.\GroupManager.ps1 -Setup

# Run the tool
.\GroupManager.ps1
```

## Installation

### Option 1: Run directly
```powershell
.\GroupManager.ps1
```

### Option 2: Install to PowerShell profile
```powershell
.\GroupManager.ps1 -Install
```
Then run `GroupManager` from any PowerShell window.

## Configuration

### Configure Groups (-Setup)

Before first use, configure the groups you want to manage:

```powershell
# Interactive menu
.\GroupManager.ps1 -Setup

# Add single group by Object ID
.\GroupManager.ps1 -Setup -ObjectId "07a94b39-cfee-41bd-a76f-187b3161696a"

# Add multiple groups
.\GroupManager.ps1 -Setup -ObjectId "guid1", "guid2", "guid3"
```

Groups are saved to `%LOCALAPPDATA%\GroupManager\config.json`.

### Configure Custom App Registration (-Configure)

Use your own app registration instead of the default Microsoft Graph auth:

```powershell
.\GroupManager.ps1 -Configure
```

This prompts for:
- **Client ID** - Your app registration's Application (client) ID
- **Tenant ID** - Your Azure AD tenant ID

Configuration is saved as user-level environment variables.

#### Required API Permissions (Delegated)

| Permission | Description |
|------------|-------------|
| User.Read | Sign in and read user profile |
| User.Read.All | Read all users' full profiles |
| GroupMember.ReadWrite.All | Read and write group memberships |

### Clear Configurations

```powershell
# Clear group configuration
.\GroupManager.ps1 -ClearConfig

# Clear app registration configuration
.\GroupManager.ps1 -ClearAuth
```

## Parameters

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
- Microsoft Graph PowerShell modules (auto-installed):
  - Microsoft.Graph.Authentication
  - Microsoft.Graph.Groups
  - Microsoft.Graph.Users

## Screenshots

```
[ E N T R A   I D   G R O U P   M A N A G E R ]  v1.3
                  Manage Group Membership

  Target Group: My-Security-Group

  SELECT AN OPTION

    [1] Add group member
    [2] Remove group member
    [3] List group members
    [4] Switch group
    [5] Exit

  Select option (1-5):
```

## License

MIT

## Author

Mark Orr
