function Invoke-GetGroupMemberList {
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
