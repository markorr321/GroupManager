function Set-GroupManagerAuth {
    <#
    .SYNOPSIS
        Configures a custom app registration for GroupManager authentication.
    .DESCRIPTION
        Prompts for or accepts ClientId and TenantId, validates them as GUIDs,
        and saves them as user-level environment variables.
    .PARAMETER ClientId
        The Application (client) ID of your app registration.
    .PARAMETER TenantId
        Your Azure AD tenant ID.
    .EXAMPLE
        Set-GroupManagerAuth
    .EXAMPLE
        Set-GroupManagerAuth -ClientId "00000000-0000-0000-0000-000000000000" -TenantId "00000000-0000-0000-0000-000000000000"
    #>
    [CmdletBinding()]
    param(
        [string]$ClientId,
        [string]$TenantId
    )

    Show-Header -Subtitle "App Registration Configuration"
    Write-Host ""

    # Show current config if exists
    $currentClientId = if ($env:GROUPMANAGER_CLIENTID) { $env:GROUPMANAGER_CLIENTID } else { [System.Environment]::GetEnvironmentVariable('GROUPMANAGER_CLIENTID', 'User') }
    $currentTenantId = if ($env:GROUPMANAGER_TENANTID) { $env:GROUPMANAGER_TENANTID } else { [System.Environment]::GetEnvironmentVariable('GROUPMANAGER_TENANTID', 'User') }

    if ($currentClientId) {
        Write-Host "  Current configuration:" -ForegroundColor Yellow
        Write-Host "    Client ID: $currentClientId" -ForegroundColor Gray
        Write-Host "    Tenant ID: $currentTenantId" -ForegroundColor Gray
        Write-Host ""
    }

    # Prompt if not provided
    if ([string]::IsNullOrWhiteSpace($ClientId)) {
        $ClientId = Read-Host "  Enter your App Registration Client ID"
    }
    if ([string]::IsNullOrWhiteSpace($ClientId)) {
        Write-Host "  Client ID cannot be empty. Configuration cancelled." -ForegroundColor Yellow
        return
    }

    try { $null = [System.Guid]::Parse($ClientId) }
    catch {
        Write-Host "  Invalid Client ID format (must be a GUID). Configuration cancelled." -ForegroundColor Red
        return
    }

    if ([string]::IsNullOrWhiteSpace($TenantId)) {
        $TenantId = Read-Host "  Enter your Tenant ID"
    }
    if ([string]::IsNullOrWhiteSpace($TenantId)) {
        Write-Host "  Tenant ID cannot be empty. Configuration cancelled." -ForegroundColor Yellow
        return
    }

    try { $null = [System.Guid]::Parse($TenantId) }
    catch {
        Write-Host "  Invalid Tenant ID format (must be a GUID). Configuration cancelled." -ForegroundColor Red
        return
    }

    try {
        [System.Environment]::SetEnvironmentVariable('GROUPMANAGER_CLIENTID', $ClientId, 'User')
        [System.Environment]::SetEnvironmentVariable('GROUPMANAGER_TENANTID', $TenantId, 'User')

        $env:GROUPMANAGER_CLIENTID = $ClientId
        $env:GROUPMANAGER_TENANTID = $TenantId

        Write-Host ""
        Write-Host "  Configuration saved successfully!" -ForegroundColor Green
        Write-Host "  GroupManager will now use your custom app registration." -ForegroundColor Green
        Write-Host ""
        Write-Host "  Required API Permissions (delegated):" -ForegroundColor Yellow
        Write-Host "    - User.Read" -ForegroundColor Gray
        Write-Host "    - User.Read.All" -ForegroundColor Gray
        Write-Host "    - GroupMember.ReadWrite.All" -ForegroundColor Gray
        Write-Host ""

        # macOS-specific handling
        $isRunningOnMac = if ($null -ne $IsMacOS) { $IsMacOS } else { $PSVersionTable.OS -match 'Darwin' }
        if ($isRunningOnMac) {
            Write-Host "  macOS Note:" -ForegroundColor Yellow
            Write-Host "  Environment variables may not persist across terminal sessions on macOS." -ForegroundColor Gray
            Write-Host "  To ensure persistence, add the following to your PowerShell profile:" -ForegroundColor Gray
            Write-Host ""
            Write-Host "  `$env:GROUPMANAGER_CLIENTID = `"$ClientId`"" -ForegroundColor Cyan
            Write-Host "  `$env:GROUPMANAGER_TENANTID = `"$TenantId`"" -ForegroundColor Cyan
            Write-Host ""

            Write-Host "  Would you like to:" -ForegroundColor Yellow
            Write-Host "    1) Add automatically to PowerShell profile" -ForegroundColor White
            Write-Host "    2) Do it manually later" -ForegroundColor White
            Write-Host ""
            $choice = Read-Host "  Enter choice (1 or 2)"

            if ($choice -eq "1") {
                $profilePath = $PROFILE.CurrentUserAllHosts
                if (-not (Test-Path $profilePath)) {
                    New-Item -Path $profilePath -ItemType File -Force | Out-Null
                }

                $profileContent = @"

# GroupManager Configuration
`$env:GROUPMANAGER_CLIENTID = "$ClientId"
`$env:GROUPMANAGER_TENANTID = "$TenantId"
"@
                Add-Content -Path $profilePath -Value $profileContent
                Write-Host ""
                Write-Host "  Added to PowerShell profile: $profilePath" -ForegroundColor Green
                Write-Host "  Configuration will persist across sessions." -ForegroundColor Green
                Write-Host ""
            } else {
                Write-Host ""
                Write-Host "  You can add it manually later to: $($PROFILE.CurrentUserAllHosts)" -ForegroundColor Gray
                Write-Host ""
            }
        }
    }
    catch {
        Write-Host ""
        Write-Host "  Failed to save configuration: $_" -ForegroundColor Red
    }
}
