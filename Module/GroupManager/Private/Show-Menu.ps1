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
