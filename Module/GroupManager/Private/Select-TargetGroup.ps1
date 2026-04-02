function Select-TargetGroup {
    param([array]$AvailableGroups)

    Show-Header -Subtitle "Manage Group Membership"
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
