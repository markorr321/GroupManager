function Invoke-RemoveUserFromGroup {
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
