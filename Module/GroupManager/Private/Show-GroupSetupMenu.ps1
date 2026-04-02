function Show-GroupSetupMenu {
    while ($true) {
        $existingGroups = Get-GroupManagerConfig

        Show-Header -Subtitle "Manage Configured Groups"
        Write-Host ""
        if ($existingGroups) {
            Write-Host "  Current configured groups:" -ForegroundColor Yellow
            foreach ($g in $existingGroups) { Write-Host "    $($g.Name) ($($g.Id))" -ForegroundColor Gray }
        }

        Write-Host ""
        Write-Host "  CONFIGURE GROUPS" -ForegroundColor DarkCyan
        Write-Host ""
        Write-Host "    [1] " -ForegroundColor DarkGray -NoNewline
        Write-Host "Add a new group" -ForegroundColor White
        Write-Host "    [2] " -ForegroundColor DarkGray -NoNewline
        Write-Host "Remove a group" -ForegroundColor White
        Write-Host "    [3] " -ForegroundColor DarkGray -NoNewline
        Write-Host "Replace all groups" -ForegroundColor White
        Write-Host "    [4] " -ForegroundColor DarkGray -NoNewline
        Write-Host "Done" -ForegroundColor White
        Write-Host ""

        $choice = (Read-Host "  Select option (1-4)").Trim()
        if ($choice -notmatch '^[1-4]$') { Write-Host "Invalid selection. Please choose 1-4." -ForegroundColor Yellow; Start-Sleep -Milliseconds 600; continue }
        if ($choice -eq '4') { Write-Host "Done. Returning..." -ForegroundColor Cyan; Start-Sleep -Milliseconds 300; return }

        switch ($choice) {
            '1' {
                $groupId = (Read-Host "Enter the Group Object ID (GUID)").Trim()
                if ([string]::IsNullOrWhiteSpace($groupId)) { Write-Host "Group ID empty; returning." -ForegroundColor Yellow; Start-Sleep -Milliseconds 400; continue }
                try { $null = [System.Guid]::Parse($groupId) } catch { Write-Host "Invalid GUID format; returning." -ForegroundColor Red; Start-Sleep -Milliseconds 400; continue }
                $groupName = (Read-Host "Enter a friendly name for the group").Trim()
                if ([string]::IsNullOrWhiteSpace($groupName)) { Write-Host "Group name empty; returning." -ForegroundColor Yellow; Start-Sleep -Milliseconds 400; continue }
                $newGroup = @{ Name = $groupName; Id = $groupId }
                if ($existingGroups) { $allGroups = @($existingGroups) + $newGroup } else { $allGroups = @($newGroup) }
                Save-GroupManagerConfig -Groups $allGroups
                Write-Host "Group '$groupName' added." -ForegroundColor Green
                Start-Sleep -Milliseconds 600
                continue
            }
            '2' {
                if (-not $existingGroups -or $existingGroups.Count -eq 0) { Write-Host "No groups configured." -ForegroundColor Yellow; Start-Sleep -Milliseconds 400; continue }
                Write-Host "Select group to remove:" -ForegroundColor Yellow
                for ($i = 0; $i -lt $existingGroups.Count; $i++) { Write-Host "  $($i+1)) $($existingGroups[$i].Name)" }
                $removeChoice = (Read-Host "Enter number").Trim()
                if ($removeChoice -notmatch '^[0-9]+$' -or [int]$removeChoice -lt 1 -or [int]$removeChoice -gt $existingGroups.Count) { Write-Host "Invalid selection." -ForegroundColor Yellow; Start-Sleep -Milliseconds 400; continue }
                $removedGroup = $existingGroups[[int]$removeChoice - 1]
                $remainingGroups = @($existingGroups | Where-Object { $_.Id -ne $removedGroup.Id })
                Save-GroupManagerConfig -Groups $remainingGroups
                Write-Host "Removed: $($removedGroup.Name)" -ForegroundColor Green
                Start-Sleep -Milliseconds 600
                continue
            }
            '3' {
                Write-Host "Enter groups one at a time. Blank ID finishes." -ForegroundColor Yellow
                $newGroups = @(); $groupNum = 1
                while ($true) {
                    $groupId = (Read-Host "Group $groupNum - Object ID (or Enter to finish)").Trim()
                    if ([string]::IsNullOrWhiteSpace($groupId)) { break }
                    try { $null = [System.Guid]::Parse($groupId) } catch { Write-Host "Invalid GUID - skipping." -ForegroundColor Red; continue }
                    $groupName = (Read-Host "Friendly name").Trim()
                    if ([string]::IsNullOrWhiteSpace($groupName)) { Write-Host "Name empty - skipping." -ForegroundColor Yellow; continue }
                    $newGroups += @{ Name = $groupName; Id = $groupId }
                    $groupNum++
                }
                if ($newGroups.Count -gt 0) { Save-GroupManagerConfig -Groups $newGroups; Write-Host "Saved $($newGroups.Count) group(s)." -ForegroundColor Green } else { Write-Host "No groups saved." -ForegroundColor Yellow }
                Start-Sleep -Milliseconds 600
                continue
            }
        }
    }
}
