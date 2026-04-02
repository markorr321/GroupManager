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
    }
    catch {
        Write-Host ""
        Write-Host "  Failed to save configuration: $_" -ForegroundColor Red
    }
}
