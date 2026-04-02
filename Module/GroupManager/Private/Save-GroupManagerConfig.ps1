function Save-GroupManagerConfig {
    param([array]$Groups)

    $configPath = Get-ConfigPath
    $configDir = Split-Path $configPath -Parent
    if (-not (Test-Path $configDir)) {
        New-Item -Path $configDir -ItemType Directory -Force | Out-Null
    }

    $config = @{ Groups = $Groups }
    $config | ConvertTo-Json -Depth 10 | Set-Content $configPath -Force
}
