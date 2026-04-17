function Clear-GroupManagerAuth {
    <#
    .SYNOPSIS
        Removes the saved app registration configuration.
    .DESCRIPTION
        Clears the GROUPMANAGER_CLIENTID and GROUPMANAGER_TENANTID environment
        variables, reverting to the default Microsoft Graph authentication.
    .EXAMPLE
        Clear-GroupManagerAuth
    #>
    [CmdletBinding()]
    param()

    try {
        [System.Environment]::SetEnvironmentVariable('GROUPMANAGER_CLIENTID', $null, 'User')
        [System.Environment]::SetEnvironmentVariable('GROUPMANAGER_TENANTID', $null, 'User')

        $env:GROUPMANAGER_CLIENTID = $null
        $env:GROUPMANAGER_TENANTID = $null

        Write-Host ""
        Write-Host "  Configuration cleared successfully." -ForegroundColor Green
        Write-Host "  GroupManager will use the default Microsoft Graph authentication." -ForegroundColor Green
        Write-Host ""

        # macOS-specific handling - check if profile has the config
        $isRunningOnMac = if ($null -ne $IsMacOS) { $IsMacOS } else { $PSVersionTable.OS -match 'Darwin' }
        if ($isRunningOnMac) {
            $profilePath = $PROFILE.CurrentUserAllHosts
            if (Test-Path $profilePath) {
                $profileContent = Get-Content -Path $profilePath -Raw
                if ($profileContent -match 'GROUPMANAGER_CLIENTID' -or $profileContent -match 'GROUPMANAGER_TENANTID') {
                    Write-Host "  macOS Note:" -ForegroundColor Yellow
                    Write-Host "  Configuration found in PowerShell profile." -ForegroundColor Gray
                    Write-Host "  Would you like to remove it from your profile? (y/n)" -ForegroundColor Yellow
                    $choice = Read-Host

                    if ($choice -eq 'y' -or $choice -eq 'Y') {
                        # Remove GroupManager configuration section from profile
                        $newContent = $profileContent -replace '(?ms)# GroupManager Configuration.*?\$env:GROUPMANAGER_TENANTID = ".*?"', ''
                        Set-Content -Path $profilePath -Value $newContent.Trim()
                        Write-Host "  Removed from PowerShell profile: $profilePath" -ForegroundColor Green
                        Write-Host ""
                    } else {
                        Write-Host "  Profile not modified. You can manually edit: $profilePath" -ForegroundColor Gray
                        Write-Host ""
                    }
                }
            }
        }
    }
    catch {
        Write-Host "  Failed to clear configuration: $_" -ForegroundColor Red
    }
}
