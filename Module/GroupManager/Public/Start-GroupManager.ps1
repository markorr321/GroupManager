function Start-GroupManager {
    <#
    .SYNOPSIS
        Launches the interactive GroupManager TUI.
    .DESCRIPTION
        Connects to Microsoft Graph and presents an interactive menu for
        managing Entra ID security group membership. Add, remove, and list
        group members through a terminal user interface.
    .EXAMPLE
        Start-GroupManager
    #>
    [CmdletBinding()]
    param()

    # Connect to Graph
    Connect-GroupManager

    # Load configured groups
    $AvailableGroups = Get-GroupManagerConfig
    if (-not $AvailableGroups -or $AvailableGroups.Count -eq 0) {
        Write-Host ""
        Write-Host "  No groups configured." -ForegroundColor Yellow
        Write-Host "  Run Set-GroupManagerGroup to configure the groups you want to manage." -ForegroundColor Cyan
        Write-Host ""
        return
    }

    # Select target group
    if ($AvailableGroups.Count -gt 1) {
        Select-TargetGroup -AvailableGroups $AvailableGroups
    }
    else {
        $script:GroupId = $AvailableGroups[0].Id
        $script:GroupName = $AvailableGroups[0].Name
    }

    # Main loop
    $ContinueRunning = $true

    while ($ContinueRunning) {
        Show-Header

        $MenuOptions = @(
            "Add group member",
            "Remove group member",
            "List group members",
            "Switch group",
            "Manage configured groups",
            "Exit"
        )

        $Selection = Show-Menu -Title "SELECT AN OPTION" -Options $MenuOptions

        switch ($Selection) {
            1 { Invoke-AddUserToGroup }
            2 { Invoke-RemoveUserFromGroup }
            3 { Invoke-GetGroupMemberList }
            4 {
                $AvailableGroups = Get-GroupManagerConfig
                if ($AvailableGroups -and $AvailableGroups.Count -gt 0) {
                    Select-TargetGroup -AvailableGroups $AvailableGroups
                }
            }
            5 {
                Show-GroupSetupMenu
                $AvailableGroups = Get-GroupManagerConfig
                if (-not $AvailableGroups -or $AvailableGroups.Count -eq 0) {
                    Write-Host "  No groups configured. Exiting." -ForegroundColor Yellow
                    $ContinueRunning = $false
                }
                elseif ($AvailableGroups.Count -eq 1) {
                    $script:GroupId = $AvailableGroups[0].Id
                    $script:GroupName = $AvailableGroups[0].Name
                }
                else {
                    Select-TargetGroup -AvailableGroups $AvailableGroups
                }
            }
            6 {
                Write-Host ""
                Write-Host "  Disconnecting from Microsoft Graph..." -ForegroundColor Cyan
                Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
                Write-Host "  Disconnected." -ForegroundColor Green
                Write-Host ""
                $ContinueRunning = $false
            }
        }
    }
}
