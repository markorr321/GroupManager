function Connect-GroupManager {
    <#
    .SYNOPSIS
        Connects to Microsoft Graph for GroupManager operations.
    .DESCRIPTION
        Establishes a connection to Microsoft Graph with the required scopes.
        Uses custom app registration if configured via Set-GroupManagerAuth.
    .PARAMETER Force
        Disconnect and reconnect even if already connected.
    .EXAMPLE
        Connect-GroupManager
    .EXAMPLE
        Connect-GroupManager -Force
    #>
    [CmdletBinding()]
    param(
        [switch]$Force
    )

    # Disable WAM - use browser-based auth for cross-platform support (Windows/macOS/Linux)
    $env:AZURE_CLIENT_DISABLE_WAM = "true"

    $customClientId = if ($env:GROUPMANAGER_CLIENTID) { $env:GROUPMANAGER_CLIENTID } else { [System.Environment]::GetEnvironmentVariable('GROUPMANAGER_CLIENTID', 'User') }
    $customTenantId = if ($env:GROUPMANAGER_TENANTID) { $env:GROUPMANAGER_TENANTID } else { [System.Environment]::GetEnvironmentVariable('GROUPMANAGER_TENANTID', 'User') }

    $GraphContext = Get-MgContext

    if ($Force -and $GraphContext) {
        Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
        $GraphContext = $null
    }

    if (-not $GraphContext) {
        Write-Host ""
        Write-Host "  Connecting to Microsoft Graph..." -ForegroundColor Cyan

        if ($customClientId -and $customTenantId) {
            Write-Host "  Using custom app registration" -ForegroundColor DarkGray
            
            # Use custom OAuth flow with branded success page
            $token = Get-GroupManagerToken -ClientId $customClientId -TenantId $customTenantId
            if ($token) {
                Connect-MgGraph -AccessToken ($token | ConvertTo-SecureString -AsPlainText -Force) -NoWelcome -WarningAction SilentlyContinue
            }
            else {
                throw "Failed to acquire authentication token"
            }
        }
        else {
            Connect-MgGraph -Scopes "GroupMember.ReadWrite.All", "User.Read.All" -NoWelcome -WarningAction SilentlyContinue
        }
    }
    else {
        Write-Host "  Already connected as $($GraphContext.Account)" -ForegroundColor Green
    }
}

function Get-GroupManagerToken {
    <#
    .SYNOPSIS
        Acquires an access token using OAuth authorization code flow with custom success page.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ClientId,
        
        [Parameter(Mandatory)]
        [string]$TenantId
    )

    $scopes = "https://graph.microsoft.com/.default offline_access openid profile"
    $port = Get-Random -Minimum 49152 -Maximum 65535
    $redirectUri = "http://localhost:$port"
    $state = [Guid]::NewGuid().ToString()
    
    # PKCE
    $codeVerifier = -join ((65..90) + (97..122) + (48..57) + 45, 46, 95, 126 | Get-Random -Count 64 | ForEach-Object { [char]$_ })
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $hash = $sha256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($codeVerifier))
    $codeChallenge = [Convert]::ToBase64String($hash).TrimEnd('=').Replace('+', '-').Replace('/', '_')

    # Build auth URL
    $authUrl = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/authorize?" + 
    "client_id=$ClientId" +
    "&response_type=code" +
    "&redirect_uri=$([Uri]::EscapeDataString($redirectUri))" +
    "&response_mode=query" +
    "&scope=$([Uri]::EscapeDataString($scopes))" +
    "&state=$state" +
    "&code_challenge=$codeChallenge" +
    "&code_challenge_method=S256"

    # Start listener
    $listener = [System.Net.HttpListener]::new()
    $listener.Prefixes.Add("$redirectUri/")
    $listener.Start()

    # Open browser
    Start-Process $authUrl

    # Wait for callback
    $context = $listener.GetContext()
    $request = $context.Request
    $response = $context.Response

    # Parse the authorization code
    $query = [System.Web.HttpUtility]::ParseQueryString($request.Url.Query)
    $code = $query["code"]
    $returnedState = $query["state"]
    $error = $query["error"]

    # Custom success/error page
    $moduleVersion = (Get-Module GroupManager -ErrorAction SilentlyContinue | Select-Object -First 1).Version
    if (-not $moduleVersion) { $moduleVersion = "1.0.0" } else { $moduleVersion = $moduleVersion.ToString() }

    if ($error -or $returnedState -ne $state) {
        $html = Get-AuthErrorPage -ErrorMessage ($query["error_description"] ?? "Authentication failed") -Version $moduleVersion
        $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
        $response.ContentLength64 = $buffer.Length
        $response.ContentType = "text/html"
        $response.OutputStream.Write($buffer, 0, $buffer.Length)
        $response.OutputStream.Close()
        $listener.Stop()
        return $null
    }

    $html = Get-AuthSuccessPage -Version $moduleVersion
    $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
    $response.ContentLength64 = $buffer.Length
    $response.ContentType = "text/html"
    $response.OutputStream.Write($buffer, 0, $buffer.Length)
    $response.OutputStream.Close()
    $listener.Stop()

    # Exchange code for token
    $tokenUrl = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"
    $body = @{
        client_id     = $ClientId
        scope         = $scopes
        code          = $code
        redirect_uri  = $redirectUri
        grant_type    = "authorization_code"
        code_verifier = $codeVerifier
    }

    try {
        $tokenResponse = Invoke-RestMethod -Uri $tokenUrl -Method Post -Body $body -ContentType "application/x-www-form-urlencoded"
        return $tokenResponse.access_token
    }
    catch {
        Write-Error "Token exchange failed: $_"
        return $null
    }
}

function Get-AuthSuccessPage {
    param([string]$Version)
    
    @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>GroupManager - Authentication Successful</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
            background: linear-gradient(135deg, #0078D4 0%, #00BCF2 100%);
            color: white;
            text-align: center;
            padding: 20px;
        }
        .container { max-width: 500px; }
        .logo {
            font-size: 0.85rem;
            letter-spacing: 0.3em;
            opacity: 0.8;
            margin-bottom: 2rem;
        }
        .checkmark {
            font-size: 4rem;
            margin-bottom: 1rem;
        }
        h1 {
            font-size: 1.75rem;
            font-weight: 500;
            margin-bottom: 0.75rem;
        }
        .subtitle {
            opacity: 0.9;
            font-size: 1rem;
            margin-bottom: 2rem;
        }
        .author {
            font-size: 0.75rem;
            opacity: 0.6;
            margin-top: 2rem;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="logo">[ G R O U P M A N A G E R ] v$Version</div>
        <div class="checkmark">✓</div>
        <h1>Authentication Successful</h1>
        <p class="subtitle">You can close this window and return to PowerShell.</p>
        <p class="author">by Mark Orr</p>
    </div>
</body>
</html>
"@
}

function Get-AuthErrorPage {
    param(
        [string]$ErrorMessage,
        [string]$Version
    )
    
    @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>GroupManager - Authentication Failed</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
            background: linear-gradient(135deg, #e66767 0%, #a24b76 100%);
            color: white;
            text-align: center;
            padding: 20px;
        }
        .container { max-width: 500px; }
        .logo {
            font-size: 0.85rem;
            letter-spacing: 0.3em;
            opacity: 0.8;
            margin-bottom: 2rem;
        }
        .icon {
            font-size: 4rem;
            margin-bottom: 1rem;
        }
        h1 {
            font-size: 1.75rem;
            font-weight: 500;
            margin-bottom: 0.75rem;
        }
        .error-message {
            opacity: 0.9;
            font-size: 0.95rem;
            background: rgba(0,0,0,0.2);
            padding: 1rem;
            border-radius: 8px;
            margin-top: 1rem;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="logo">[ G R O U P M A N A G E R ] v$Version</div>
        <div class="icon">✕</div>
        <h1>Authentication Failed</h1>
        <p class="error-message">$ErrorMessage</p>
    </div>
</body>
</html>
"@
}
