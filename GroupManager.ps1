<#
.SYNOPSIS
    Entra ID Group Manager - Add and remove users from Entra ID security groups.

.DESCRIPTION
    This script provides a terminal user interface for managing membership of 
    Entra ID security groups. Users can be added or removed by entering
    their User Principal Name (UPN).
    
    Before first use, run with -Setup to configure the groups you want to manage.
    
    Features:
    - Add users to the group by UPN
    - Remove users from the group by UPN
    - List all current group members
    - Interactive menu-driven interface
    - Automatic module installation if not present
    - Self-install to PowerShell profile
    - Setup custom groups by Object ID
    - Configure custom app registration for authentication

.PARAMETER Install
    Adds a 'GroupManager' function to your PowerShell profile so you can run 
    the script from any PowerShell window by typing 'GroupManager'.

.PARAMETER Setup
    Opens an interactive setup menu to add, remove, or replace the groups
    you want to manage. Groups are stored by Object ID in a local config file.
    Required before first use. Can be combined with -ObjectId for direct setup.

.PARAMETER Configure
    Configure a custom app registration for authentication. Prompts for
    ClientId and TenantId and saves them as user-level environment variables.
    Similar to Configure-EntraPIM.

.PARAMETER ClearAuth
    Removes the saved app registration configuration and reverts to the
    default Microsoft Graph authentication flow.
    Similar to Clear-EntraPIMConfig.

.PARAMETER ClearConfig
    Removes the saved group configuration.

.PARAMETER ObjectId
    One or more Group Object IDs (GUIDs) to add to the configuration.
    Use with -Setup to quickly add groups by ID.

.EXAMPLE
    .\GroupManager.ps1 -Setup

    First-time setup: opens interactive menu to configure groups.

.EXAMPLE
    .\GroupManager.ps1 -Setup -ObjectId "07a94b39-cfee-41bd-a76f-187b3161696a"

    Add a single group by Object ID. Prompts for a friendly name.

.EXAMPLE
    .\GroupManager.ps1 -Setup -ObjectId "guid1", "guid2", "guid3"

    Add multiple groups at once by Object ID.

.EXAMPLE
    .\GroupManager.ps1 -Configure

    Configure a custom app registration for authentication.

.EXAMPLE
    .\GroupManager.ps1

    Runs the script and presents menu options for managing group membership.

.EXAMPLE
    .\GroupManager.ps1 -Install

    Adds GroupManager to your PowerShell profile for easy access.

.EXAMPLE
    .\GroupManager.ps1 -ClearConfig

    Clears the saved group configuration.

.EXAMPLE
    .\GroupManager.ps1 -ClearAuth

    Clears the saved app registration configuration.

.NOTES
    File Name      : GroupManager.ps1
    Config File    : %LOCALAPPDATA%\GroupManager\config.json
    Prerequisite   : Microsoft Graph PowerShell modules (auto-installed if missing)
    Version        : 1.3

.LINK
    https://learn.microsoft.com/en-us/powershell/microsoftgraph/
#>

[CmdletBinding()]
param(
    [switch]$Install,
    [switch]$Setup,
    [switch]$Configure,
    [switch]$ClearAuth,
    [switch]$ClearConfig,
    [string[]]$ObjectId
)

#region Self-Install

if ($Install) {
    $ScriptPath = $MyInvocation.MyCommand.Path
    $FunctionDefinition = "`nfunction GroupManager { & '$ScriptPath' }"
    
    # Create profile if it doesn't exist
    if (!(Test-Path $PROFILE)) {
        New-Item -Path $PROFILE -ItemType File -Force | Out-Null
        Write-Host "Created PowerShell profile at: $PROFILE" -ForegroundColor Green
    }
    
    # Check if already installed
    $ProfileContent = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue
    if ($ProfileContent -match 'function GroupManager') {
        Write-Host "GroupManager is already installed in your profile." -ForegroundColor Yellow
    }
    else {
        Add-Content $PROFILE $FunctionDefinition
        Write-Host "GroupManager has been added to your PowerShell profile." -ForegroundColor Green
        Write-Host "Restart PowerShell or run: . `$PROFILE" -ForegroundColor Cyan
    }
    return
}

#endregion

#region App Registration Configuration

if ($Configure) {
    Write-Host ""
    Write-Host "GroupManager Configuration" -ForegroundColor Cyan
    Write-Host "==========================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Configure a custom app registration for GroupManager."
    Write-Host "Settings will be saved as user-level environment variables."
    Write-Host ""
    
    # Show current config if exists
    if ($env:GROUPMANAGER_CLIENTID -or [System.Environment]::GetEnvironmentVariable('GROUPMANAGER_CLIENTID', 'User')) {
        $currentClientId = if ($env:GROUPMANAGER_CLIENTID) { $env:GROUPMANAGER_CLIENTID } else { [System.Environment]::GetEnvironmentVariable('GROUPMANAGER_CLIENTID', 'User') }
        $currentTenantId = if ($env:GROUPMANAGER_TENANTID) { $env:GROUPMANAGER_TENANTID } else { [System.Environment]::GetEnvironmentVariable('GROUPMANAGER_TENANTID', 'User') }
        Write-Host "Current configuration:" -ForegroundColor Yellow
        Write-Host "  Client ID: $currentClientId" -ForegroundColor Gray
        Write-Host "  Tenant ID: $currentTenantId" -ForegroundColor Gray
        Write-Host ""
    }
    
    # Prompt for ClientId
    $clientId = Read-Host "Enter your App Registration Client ID"
    if ([string]::IsNullOrWhiteSpace($clientId)) {
        Write-Host "Client ID cannot be empty. Configuration cancelled." -ForegroundColor Yellow
        return
    }
    
    # Validate GUID format
    try {
        $null = [System.Guid]::Parse($clientId)
    }
    catch {
        Write-Host "Invalid Client ID format (must be a GUID). Configuration cancelled." -ForegroundColor Red
        return
    }
    
    # Prompt for TenantId
    $tenantId = Read-Host "Enter your Tenant ID"
    if ([string]::IsNullOrWhiteSpace($tenantId)) {
        Write-Host "Tenant ID cannot be empty. Configuration cancelled." -ForegroundColor Yellow
        return
    }
    
    # Validate GUID format
    try {
        $null = [System.Guid]::Parse($tenantId)
    }
    catch {
        Write-Host "Invalid Tenant ID format (must be a GUID). Configuration cancelled." -ForegroundColor Red
        return
    }
    
    # Save as user-level environment variables
    try {
        [System.Environment]::SetEnvironmentVariable('GROUPMANAGER_CLIENTID', $clientId, 'User')
        [System.Environment]::SetEnvironmentVariable('GROUPMANAGER_TENANTID', $tenantId, 'User')
        
        # Also set for current session
        $env:GROUPMANAGER_CLIENTID = $clientId
        $env:GROUPMANAGER_TENANTID = $tenantId
        
        Write-Host ""
        Write-Host "Configuration saved successfully!" -ForegroundColor Green
        Write-Host "GroupManager will now use your custom app registration." -ForegroundColor Green
        Write-Host ""
        Write-Host "Required API Permissions (delegated):" -ForegroundColor Yellow
        Write-Host "  - User.Read" -ForegroundColor Gray
        Write-Host "  - User.Read.All" -ForegroundColor Gray
        Write-Host "  - GroupMember.ReadWrite.All" -ForegroundColor Gray
        Write-Host ""
    }
    catch {
        Write-Host ""
        Write-Host "Failed to save configuration: $_" -ForegroundColor Red
    }
    return
}

if ($ClearAuth) {
    try {
        [System.Environment]::SetEnvironmentVariable('GROUPMANAGER_CLIENTID', $null, 'User')
        [System.Environment]::SetEnvironmentVariable('GROUPMANAGER_TENANTID', $null, 'User')
        
        # Also clear from current session
        $env:GROUPMANAGER_CLIENTID = $null
        $env:GROUPMANAGER_TENANTID = $null
        
        Write-Host ""
        Write-Host "Configuration cleared successfully." -ForegroundColor Green
        Write-Host "GroupManager will use the default Microsoft Graph authentication." -ForegroundColor Green
        Write-Host ""
    }
    catch {
        Write-Host "Failed to clear configuration: $_" -ForegroundColor Red
    }
    return
}

#endregion

#region Module Setup and Graph Connection

# Display header
Write-Host ""
Write-Host "[ E N T R A   I D   G R O U P   M A N A G E R ]  " -ForegroundColor DarkCyan -NoNewline
Write-Host "v1.3" -ForegroundColor White
Write-Host "                  Manage Group Membership" -ForegroundColor DarkGray
Write-Host ""

# Required modules
$RequiredModules = @(
    'Microsoft.Graph.Authentication',
    'Microsoft.Graph.Groups',
    'Microsoft.Graph.Users'
)

# Check which modules need to be installed
$ModulesToInstall = @()
foreach ($Module in $RequiredModules) {
    if (-not (Get-Module -ListAvailable -Name $Module)) {
        $ModulesToInstall += $Module
    }
}

# Install missing modules or confirm all prerequisites met
if ($ModulesToInstall.Count -eq 0) {
    Write-Host "  All prerequisites met." -ForegroundColor Green
}
else {
    Write-Host "  Installing required modules..." -ForegroundColor Yellow
    foreach ($Module in $ModulesToInstall) {
        Write-Host "    Installing $Module..." -ForegroundColor Yellow -NoNewline
        try {
            Install-Module -Name $Module -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
            Write-Host " Done" -ForegroundColor Green
        }
        catch {
            Write-Host " Failed" -ForegroundColor Red
            Write-Host "  ERROR: Failed to install module '$Module' - $_" -ForegroundColor Red
            exit 1
        }
    }
    Write-Host "  All modules installed successfully." -ForegroundColor Green
}

# Import the modules silently
foreach ($Module in $RequiredModules) {
    if (-not (Get-Module -Name $Module)) {
        try {
            Import-Module $Module -ErrorAction Stop
        }
        catch {
            # Module will be loaded by Connect-MgGraph
        }
    }
}

# Connect to Microsoft Graph
$env:AZURE_CLIENT_DISABLE_WAM = "true"

# Check for custom app registration configuration
$customClientId = if ($env:GROUPMANAGER_CLIENTID) { $env:GROUPMANAGER_CLIENTID } else { [System.Environment]::GetEnvironmentVariable('GROUPMANAGER_CLIENTID', 'User') }
$customTenantId = if ($env:GROUPMANAGER_TENANTID) { $env:GROUPMANAGER_TENANTID } else { [System.Environment]::GetEnvironmentVariable('GROUPMANAGER_TENANTID', 'User') }

$GraphContext = Get-MgContext
if (-not $GraphContext) {
    Write-Host ""
    Write-Host "  Connecting to Microsoft Graph..." -ForegroundColor Cyan
    
    if ($customClientId -and $customTenantId) {
        Write-Host "  Using custom app registration" -ForegroundColor DarkGray
        Connect-MgGraph -ClientId $customClientId -TenantId $customTenantId -Scopes "GroupMember.ReadWrite.All", "User.Read.All" -NoWelcome -WarningAction SilentlyContinue
    }
    else {
        Connect-MgGraph -Scopes "GroupMember.ReadWrite.All", "User.Read.All" -NoWelcome -WarningAction SilentlyContinue
    }
}
else {
    Write-Host "  Already connected as $($GraphContext.Account)" -ForegroundColor Green
}

#endregion

#region Configuration File Handling

# Configuration file path
$ConfigPath = Join-Path $env:LOCALAPPDATA "GroupManager\config.json"

function Get-GroupManagerConfig {
    if (Test-Path $ConfigPath) {
        try {
            $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
            return $config.Groups
        }
        catch {
            return $null
        }
    }
    return $null
}

function Save-GroupManagerConfig {
    param([array]$Groups)
    
    $configDir = Split-Path $ConfigPath -Parent
    if (-not (Test-Path $configDir)) {
        New-Item -Path $configDir -ItemType Directory -Force | Out-Null
    }
    
    $config = @{ Groups = $Groups }
    $config | ConvertTo-Json -Depth 10 | Set-Content $ConfigPath -Force
}

if ($Setup) {
    # If ObjectIds provided directly, add them without interactive menu
    if ($ObjectId -and $ObjectId.Count -gt 0) {
        Write-Host ""
        Write-Host "Adding groups by Object ID..." -ForegroundColor Cyan
        Write-Host ""
        
        $newGroups = @()
        $existingGroups = Get-GroupManagerConfig
        if ($existingGroups) {
            $newGroups = @($existingGroups)
        }
        
        foreach ($id in $ObjectId) {
            # Validate GUID format
            try {
                $null = [System.Guid]::Parse($id)
            }
            catch {
                Write-Host "  Invalid GUID format: $id - Skipping" -ForegroundColor Red
                continue
            }
            
            # Check if already exists
            if ($newGroups | Where-Object { $_.Id -eq $id }) {
                Write-Host "  Group $id already configured - Skipping" -ForegroundColor Yellow
                continue
            }
            
            # Prompt for friendly name
            $groupName = Read-Host "  Enter friendly name for $id"
            if ([string]::IsNullOrWhiteSpace($groupName)) {
                $groupName = "Group-$id"
            }
            
            $newGroups += @{ Name = $groupName; Id = $id }
            Write-Host "  Added: $groupName" -ForegroundColor Green
        }
        
        Save-GroupManagerConfig -Groups $newGroups
        Write-Host ""
        Write-Host "Configuration saved. Total groups: $($newGroups.Count)" -ForegroundColor Green
        Write-Host ""
        return
    }
    
    # Interactive configuration menu
    Write-Host ""
    Write-Host "GroupManager Configuration" -ForegroundColor Cyan
    Write-Host "==========================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Configure the Entra ID groups you want to manage."
    Write-Host "Groups will be saved to: $ConfigPath"
    Write-Host ""
    
    # Load existing groups
    $existingGroups = Get-GroupManagerConfig
    if ($existingGroups) {
        Write-Host "Current configured groups:" -ForegroundColor Yellow
        foreach ($g in $existingGroups) {
            Write-Host "  - $($g.Name) ($($g.Id))" -ForegroundColor Gray
        }
        Write-Host ""
    }
    
    Write-Host "Options:" -ForegroundColor Yellow
    Write-Host "  [1] Add a new group"
    Write-Host "  [2] Remove a group"
    Write-Host "  [3] Replace all groups"
    Write-Host "  [4] Cancel"
    Write-Host ""
    
    $choice = Read-Host "Select option (1-4)"
    
    switch ($choice) {
        "1" {
            # Add new group
            Write-Host ""
            $groupId = Read-Host "Enter the Group Object ID (GUID)"
            if ([string]::IsNullOrWhiteSpace($groupId)) {
                Write-Host "Group ID cannot be empty. Configuration cancelled." -ForegroundColor Yellow
                return
            }
            
            # Validate GUID format
            try {
                $null = [System.Guid]::Parse($groupId)
            }
            catch {
                Write-Host "Invalid GUID format. Configuration cancelled." -ForegroundColor Red
                return
            }
            
            $groupName = Read-Host "Enter a friendly name for the group"
            if ([string]::IsNullOrWhiteSpace($groupName)) {
                Write-Host "Group name cannot be empty. Configuration cancelled." -ForegroundColor Yellow
                return
            }
            
            $newGroup = @{ Name = $groupName; Id = $groupId }
            
            if ($existingGroups) {
                $allGroups = @($existingGroups) + $newGroup
            }
            else {
                $allGroups = @($newGroup)
            }
            
            Save-GroupManagerConfig -Groups $allGroups
            Write-Host ""
            Write-Host "Group '$groupName' added successfully!" -ForegroundColor Green
        }
        "2" {
            # Remove a group
            if (-not $existingGroups -or $existingGroups.Count -eq 0) {
                Write-Host "No groups configured to remove." -ForegroundColor Yellow
                return
            }
            
            Write-Host ""
            Write-Host "Select group to remove:" -ForegroundColor Yellow
            for ($i = 0; $i -lt $existingGroups.Count; $i++) {
                Write-Host "  [$($i + 1)] $($existingGroups[$i].Name)"
            }
            Write-Host ""
            
            $removeChoice = Read-Host "Enter number (1-$($existingGroups.Count))"
            if ($removeChoice -match '^\d+$' -and [int]$removeChoice -ge 1 -and [int]$removeChoice -le $existingGroups.Count) {
                $removedGroup = $existingGroups[[int]$removeChoice - 1]
                $remainingGroups = @($existingGroups | Where-Object { $_.Id -ne $removedGroup.Id })
                Save-GroupManagerConfig -Groups $remainingGroups
                Write-Host ""
                Write-Host "Group '$($removedGroup.Name)' removed." -ForegroundColor Green
            }
            else {
                Write-Host "Invalid selection." -ForegroundColor Yellow
            }
        }
        "3" {
            # Replace all groups
            Write-Host ""
            Write-Host "Enter groups one at a time. Enter blank Group ID when done." -ForegroundColor Yellow
            Write-Host ""
            
            $newGroups = @()
            $groupNum = 1
            
            while ($true) {
                Write-Host "Group $groupNum" -ForegroundColor Cyan
                $groupId = Read-Host "  Group Object ID (or Enter to finish)"
                
                if ([string]::IsNullOrWhiteSpace($groupId)) {
                    break
                }
                
                # Validate GUID format
                try {
                    $null = [System.Guid]::Parse($groupId)
                }
                catch {
                    Write-Host "  Invalid GUID format. Skipping." -ForegroundColor Red
                    continue
                }
                
                $groupName = Read-Host "  Friendly name"
                if ([string]::IsNullOrWhiteSpace($groupName)) {
                    Write-Host "  Name cannot be empty. Skipping." -ForegroundColor Yellow
                    continue
                }
                
                $newGroups += @{ Name = $groupName; Id = $groupId }
                $groupNum++
                Write-Host ""
            }
            
            if ($newGroups.Count -gt 0) {
                Save-GroupManagerConfig -Groups $newGroups
                Write-Host ""
                Write-Host "Saved $($newGroups.Count) group(s) to configuration!" -ForegroundColor Green
            }
            else {
                Write-Host "No groups entered. Configuration unchanged." -ForegroundColor Yellow
            }
        }
        default {
            Write-Host "Configuration cancelled." -ForegroundColor Yellow
        }
    }
    return
}

if ($ClearConfig) {
    if (Test-Path $ConfigPath) {
        Remove-Item $ConfigPath -Force
        Write-Host ""
        Write-Host "GroupManager configuration cleared." -ForegroundColor Green
        Write-Host "Run with -Setup to configure groups." -ForegroundColor Gray
        Write-Host ""
    }
    else {
        Write-Host ""
        Write-Host "No configuration file found." -ForegroundColor Yellow
        Write-Host ""
    }
    return
}

#endregion

#region Configuration

# Load configured groups
$AvailableGroups = Get-GroupManagerConfig
if (-not $AvailableGroups -or $AvailableGroups.Count -eq 0) {
    Write-Host ""
    Write-Host "No groups configured." -ForegroundColor Yellow
    Write-Host "Run with -Setup to configure the groups you want to manage." -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Example: .\GroupManager.ps1 -Setup" -ForegroundColor Gray
    Write-Host ""
    return
}

# Active group (set during group selection)
$script:GroupId = $null
$script:GroupName = $null

#endregion

#region Helper Functions

function Show-Menu {
    param(
        [string]$Title,
        [string[]]$Options
    )
    
    Write-Host ""
    Write-Host "  $Title" -ForegroundColor DarkCyan
    Write-Host ""
    
    for ($i = 0; $i -lt $Options.Count; $i++) {
        Write-Host "    [$($i + 1)] " -ForegroundColor DarkGray -NoNewline
        Write-Host "$($Options[$i])" -ForegroundColor White
    }
    
    Write-Host ""
    
    do {
        $Selection = Read-Host "  Select option (1-$($Options.Count))"
    } while ($Selection -notmatch '^\d+$' -or [int]$Selection -lt 1 -or [int]$Selection -gt $Options.Count)
    
    return [int]$Selection
}

function Show-Header {
    Clear-Host
    Write-Host ""
    Write-Host "[ E N T R A   I D   G R O U P   M A N A G E R ]  " -ForegroundColor DarkCyan -NoNewline
    Write-Host "v1.3" -ForegroundColor White
    Write-Host "                  Manage Group Membership" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Target Group: " -ForegroundColor DarkGray -NoNewline
    Write-Host "$script:GroupName" -ForegroundColor Cyan
    Write-Host ""
}

function Select-TargetGroup {
    Clear-Host
    Write-Host ""
    Write-Host "[ E N T R A   I D   G R O U P   M A N A G E R ]  " -ForegroundColor DarkCyan -NoNewline
    Write-Host "v1.3" -ForegroundColor White
    Write-Host "                  Manage Group Membership" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  SELECT TARGET GROUP" -ForegroundColor DarkCyan
    Write-Host ""
    
    for ($i = 0; $i -lt $AvailableGroups.Count; $i++) {
        Write-Host "    [$($i + 1)] " -ForegroundColor DarkGray -NoNewline
        Write-Host "$($AvailableGroups[$i].Name)" -ForegroundColor White
    }
    
    Write-Host ""
    
    do {
        $Selection = Read-Host "  Select group (1-$($AvailableGroups.Count))"
    } while ($Selection -notmatch '^\d+$' -or [int]$Selection -lt 1 -or [int]$Selection -gt $AvailableGroups.Count)
    
    $SelectedGroup = $AvailableGroups[[int]$Selection - 1]
    $script:GroupId = $SelectedGroup.Id
    $script:GroupName = $SelectedGroup.Name
    
    Write-Host ""
    Write-Host "  Selected: " -ForegroundColor Green -NoNewline
    Write-Host "$script:GroupName" -ForegroundColor Cyan
    Start-Sleep -Seconds 1
}

function Wait-ForKeyPress {
    Write-Host ""
    Write-Host "  Press any key to continue..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Add-UserToGroup {
    Show-Header
    Write-Host "  ADD USER TO GROUP" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "  Enter the user's UPN (email address): " -ForegroundColor Yellow -NoNewline
    $upn = Read-Host
    
    if ([string]::IsNullOrWhiteSpace($upn)) {
        Write-Host ""
        Write-Host "  No UPN entered. Operation cancelled." -ForegroundColor Yellow
        Wait-ForKeyPress
        return
    }
    
    Write-Host ""
    Write-Host "  Looking up user..." -ForegroundColor Cyan
    
    try {
        $user = Get-MgUser -UserId $upn -ErrorAction Stop
        Write-Host "  Found user: $($user.DisplayName)" -ForegroundColor Green
        
        Write-Host "  Adding user to group..." -ForegroundColor Cyan
        New-MgGroupMember -GroupId $script:GroupId -DirectoryObjectId $user.Id -ErrorAction Stop
        
        Write-Host ""
        Write-Host "  SUCCESS: " -ForegroundColor Green -NoNewline
        Write-Host "User '$($user.DisplayName)' added to group" -ForegroundColor White
    }
    catch {
        if ($_.Exception.Message -like "*already exist*") {
            Write-Host ""
            Write-Host "  User '$upn' is already a member of this group." -ForegroundColor Yellow
        }
        else {
            Write-Host ""
            Write-Host "  ERROR: " -ForegroundColor Red -NoNewline
            Write-Host "Failed to add user - $_" -ForegroundColor White
        }
    }
    
    Wait-ForKeyPress
}

function Remove-UserFromGroup {
    Show-Header
    Write-Host "  REMOVE USER FROM GROUP" -ForegroundColor Red
    Write-Host ""
    
    Write-Host "  Enter the user's UPN (email address): " -ForegroundColor Yellow -NoNewline
    $upn = Read-Host
    
    if ([string]::IsNullOrWhiteSpace($upn)) {
        Write-Host ""
        Write-Host "  No UPN entered. Operation cancelled." -ForegroundColor Yellow
        Wait-ForKeyPress
        return
    }
    
    Write-Host ""
    Write-Host "  Looking up user..." -ForegroundColor Cyan
    
    try {
        $user = Get-MgUser -UserId $upn -ErrorAction Stop
        Write-Host "  Found user: $($user.DisplayName)" -ForegroundColor Green
        
        Write-Host "  Removing user from group..." -ForegroundColor Cyan
        Remove-MgGroupMemberByRef -GroupId $script:GroupId -DirectoryObjectId $user.Id -ErrorAction Stop
        
        Write-Host ""
        Write-Host "  SUCCESS: " -ForegroundColor Green -NoNewline
        Write-Host "User '$($user.DisplayName)' removed from group" -ForegroundColor White
    }
    catch {
        if ($_.Exception.Message -like "*does not exist*" -or $_.Exception.Message -like "*Resource*not found*") {
            Write-Host ""
            Write-Host "  User '$upn' is not a member of this group." -ForegroundColor Yellow
        }
        else {
            Write-Host ""
            Write-Host "  ERROR: " -ForegroundColor Red -NoNewline
            Write-Host "Failed to remove user - $_" -ForegroundColor White
        }
    }
    
    Wait-ForKeyPress
}

function Get-GroupMemberList {
    Show-Header
    Write-Host "  CURRENT GROUP MEMBERS" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "  Fetching group members..." -ForegroundColor Cyan
    
    try {
        $members = Get-MgGroupMember -GroupId $script:GroupId -All | ForEach-Object {
            Get-MgUser -UserId $_.Id -ErrorAction SilentlyContinue
        } | Where-Object { $_ -ne $null } | Sort-Object DisplayName
        
        if ($members.Count -eq 0) {
            Write-Host ""
            Write-Host "  No members found in this group." -ForegroundColor Yellow
            Wait-ForKeyPress
            return
        }
        
        Write-Host ""
        Write-Host "  Total Members: " -ForegroundColor DarkGray -NoNewline
        Write-Host "$($members.Count)" -ForegroundColor White
        Write-Host ""
        
        # Display numbered list
        $memberArray = @($members)
        for ($i = 0; $i -lt $memberArray.Count; $i++) {
            Write-Host "    [$($i + 1)] " -ForegroundColor DarkGray -NoNewline
            Write-Host "$($memberArray[$i].DisplayName) " -ForegroundColor White -NoNewline
            Write-Host "($($memberArray[$i].UserPrincipalName))" -ForegroundColor DarkGray
        }
        
        Write-Host ""
        Write-Host "  Enter a number to remove that member, or press Enter to go back" -ForegroundColor Yellow
        Write-Host ""
        $selection = Read-Host "  Select member to remove (1-$($memberArray.Count)) or Enter to cancel"
        
        if ([string]::IsNullOrWhiteSpace($selection)) {
            return
        }
        
        if ($selection -match '^\d+$' -and [int]$selection -ge 1 -and [int]$selection -le $memberArray.Count) {
            $selectedUser = $memberArray[[int]$selection - 1]
            
            Write-Host ""
            Write-Host "  Removing $($selectedUser.DisplayName)..." -ForegroundColor Cyan
            
            try {
                Remove-MgGroupMemberByRef -GroupId $script:GroupId -DirectoryObjectId $selectedUser.Id -ErrorAction Stop
                Write-Host ""
                Write-Host "  SUCCESS: " -ForegroundColor Green -NoNewline
                Write-Host "User '$($selectedUser.DisplayName)' removed from group" -ForegroundColor White
            }
            catch {
                Write-Host ""
                Write-Host "  ERROR: " -ForegroundColor Red -NoNewline
                Write-Host "Failed to remove user - $_" -ForegroundColor White
            }
            
            Wait-ForKeyPress
        }
        else {
            Write-Host ""
            Write-Host "  Invalid selection. Returning to menu." -ForegroundColor Yellow
            Start-Sleep -Seconds 1
        }
    }
    catch {
        Write-Host ""
        Write-Host "  ERROR: " -ForegroundColor Red -NoNewline
        Write-Host "Failed to retrieve group members - $_" -ForegroundColor White
        Wait-ForKeyPress
    }
}

#endregion

#region Main Loop

# Select target group before main menu
Select-TargetGroup

$ContinueRunning = $true

while ($ContinueRunning) {
    Show-Header
    
    $MenuOptions = @(
        "Add group member",
        "Remove group member",
        "List group members",
        "Switch group",
        "Exit"
    )
    
    $Selection = Show-Menu -Title "SELECT AN OPTION" -Options $MenuOptions
    
    switch ($Selection) {
        1 { Add-UserToGroup }
        2 { Remove-UserFromGroup }
        3 { Get-GroupMemberList }
        4 { Select-TargetGroup }
        5 { 
            Write-Host ""
            Write-Host "  Disconnecting from Microsoft Graph..." -ForegroundColor Cyan
            Disconnect-MgGraph | Out-Null
            Write-Host "  Disconnected." -ForegroundColor Green
            Write-Host ""
            $ContinueRunning = $false
        }
    }
}

#endregion
