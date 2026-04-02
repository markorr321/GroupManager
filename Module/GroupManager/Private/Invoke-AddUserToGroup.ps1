function Invoke-AddUserToGroup {
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
