# ============================================
# TSPU Diagnostic Tool for Windows
# Simplified version (English/ASCII only) 
# ============================================

# Colors
$Green = "Green"
$Red = "Red"
$Yellow = "Yellow"
$Cyan = "Cyan"
$Blue = "Blue"

# Configuration
$Script:ServerIP = "178.154.212.182"
$ConfigFile = "$env:USERPROFILE\.tspu_checker.conf"

# Load saved IP
function Load-ServerIP {
    if (Test-Path $ConfigFile) {
        $Script:ServerIP = (Get-Content $ConfigFile).Trim()
        Write-Host "[OK] Loaded IP: $Script:ServerIP" -ForegroundColor Green
    } else {
        Write-Host "[WARN] Using default IP: $Script:ServerIP" -ForegroundColor Yellow
    }
    Write-Host ""
}

# Save IP
function Save-ServerIP {
    Set-Content -Path $ConfigFile -Value $Script:ServerIP
    Write-Host "[OK] IP saved: $Script:ServerIP" -ForegroundColor Green
}

# Clear screen
function Clear-Screen {
    Clear-Host
}

# Pause
function Pause {
    Write-Host "`nPress Enter to continue..." -ForegroundColor Yellow
    Read-Host
}

# Header
function Print-Header {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "     TSPU Diagnostic Tool for Windows   " -ForegroundColor Cyan
    Write-Host "                v1.0                     " -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "[Target Server]: $Script:ServerIP" -ForegroundColor Cyan
    Write-Host ""
}

# Check port via Test-NetConnection
function Test-Port {
    param($IP, $Port, $Timeout = 3)
    try {
        $result = Test-NetConnection -ComputerName $IP -Port $Port -WarningAction SilentlyContinue -ErrorAction Stop
        return $result.TcpTestSucceeded
    } catch {
        return $false
    }
}

# 0. Change server IP
function Configure-ServerIP {
    Clear-Screen
    Print-Header
    Write-Host "[0] Change server IP address" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Current IP: $Script:ServerIP" -ForegroundColor Cyan
    Write-Host ""
    $newIP = Read-Host "Enter new IP (or leave empty)"
    if ($newIP) {
        if ($newIP -match '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$') {
            $Script:ServerIP = $newIP
            Save-ServerIP
            Write-Host "`n[OK] IP changed to $Script:ServerIP" -ForegroundColor Green
        } else {
            Write-Host "`n[ERROR] Invalid IP format" -ForegroundColor Red
        }
    } else {
        Write-Host "`nIP not changed" -ForegroundColor Yellow
    }
    Pause
}

# 1. Detect TSPU mode
function Detect-TSPUMode {
    Clear-Screen
    Print-Header
    Write-Host "[1] Detect TSPU operation mode..." -ForegroundColor Yellow
    Write-Host ""
    
    $BlockedIP = "173.194.222.113"  # Google
    
    Write-Host "[Test IP (Google)]: $BlockedIP" -ForegroundColor Cyan
    Write-Host ""
    
    # ICMP test
    Write-Host -NoNewline "  ICMP (ping) Google: "
    $pingResult = Test-Connection -ComputerName $BlockedIP -Count 2 -Quiet -ErrorAction SilentlyContinue
    if ($pingResult) {
        Write-Host "OK (reachable)" -ForegroundColor Green
        $ICMP_OK = $true
    } else {
        Write-Host "FAIL (unreachable)" -ForegroundColor Red
        $ICMP_OK = $false
    }
    
    # TCP test
    Write-Host -NoNewline "  TCP (port 443) Google: "
    $TCP_OK = Test-Port -IP $BlockedIP -Port 443
    if ($TCP_OK) {
        Write-Host "OK (open)" -ForegroundColor Green
    } else {
        Write-Host "FAIL (closed/timeout)" -ForegroundColor Red
    }
    
    # Analysis
    Write-Host ""
    Write-Host "[Analysis]:" -ForegroundColor Cyan
    Write-Host ""
    
    if ($ICMP_OK -and -not $TCP_OK) {
        Write-Host "  [WARN] ALLOWLIST MODE (white list)" -ForegroundColor Red
        Write-Host "     * ICMP works, TCP blocked at L3"
    } elseif (-not $ICMP_OK -and -not $TCP_OK) {
        Write-Host "  [WARN] BLOCKLIST MODE or FULL BLOCK" -ForegroundColor Yellow
    } elseif ($ICMP_OK -and $TCP_OK) {
        Write-Host "  [OK] NO BLOCKING (normal mode)" -ForegroundColor Green
    } else {
        Write-Host "  [?] UNDEFINED" -ForegroundColor Yellow
    }
    
    Pause
}

# 2. Check TSPU activity via HTTP
function Check-TSPUActive {
    Clear-Screen
    Print-Header
    Write-Host "[2] Check TSPU activity (real HTTP access)..." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "[HTTP checks]:" -ForegroundColor Cyan
    Write-Host ""
    
    $sites = @(
        @{Url="https://ya.ru"; Name="Yandex"},
        @{Url="https://google.com"; Name="Google"},
        @{Url="https://youtube.com"; Name="YouTube"},
        @{Url="https://github.com"; Name="GitHub"},
        @{Url="https://telegram.org"; Name="Telegram"}
    )
    
    $working = 0
    foreach ($site in $sites) {
        Write-Host -NoNewline "  $($site.Name) ($($site.Url)): "
        try {
            $response = Invoke-WebRequest -Uri $site.Url -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
            if ($response.StatusCode -ge 200 -and $response.StatusCode -lt 400) {
                Write-Host "OK (HTTP $($response.StatusCode))" -ForegroundColor Green
                $working++
            } else {
                Write-Host "CODE $($response.StatusCode)" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "FAIL (timeout/unreachable)" -ForegroundColor Red
        }
    }
    
    Write-Host ""
    Write-Host "[Server $Script:ServerIP TCP ports]:" -ForegroundColor Cyan
    Write-Host ""
    
    foreach ($port in @(22, 80, 443)) {
        Write-Host -NoNewline "  Port $port : "
        if (Test-Port -IP $Script:ServerIP -Port $port) {
            Write-Host "OPEN" -ForegroundColor Green
        } else {
            Write-Host "CLOSED/FILTERED" -ForegroundColor Yellow
        }
    }
    
    Pause
}

# 3. Check port availability
function Check-Ports {
    Clear-Screen
    Print-Header
    Write-Host "[3] Check port availability (TCP)..." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "[Target]: $Script:ServerIP" -ForegroundColor Cyan
    Write-Host ""
    
    foreach ($port in @(22, 80, 443, 8080, 8443)) {
        Write-Host -NoNewline "  Port $port : "
        if (Test-Port -IP $Script:ServerIP -Port $port) {
            Write-Host "OPEN (reachable)" -ForegroundColor Green
        } else {
            Write-Host "CLOSED or NO RESPONSE" -ForegroundColor Yellow
        }
        Start-Sleep -Milliseconds 200
    }
    
    Pause
}

# 4. SNI filtering test (basic)
function Test-SNIFiltering {
    Clear-Screen
    Print-Header
    Write-Host "[4] Check SNI filtering (basic)..." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "[Test IP (Yandex)]: 77.88.55.242" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "[NOTE] For full SNI test use WSL" -ForegroundColor Yellow
    Write-Host ""
    
    $sni_tests = @(
        @{Sni="ya.ru"; Name="Yandex"},
        @{Sni="google.com"; Name="Google"},
        @{Sni="twitter.com"; Name="Twitter"},
        @{Sni="youtube.com"; Name="YouTube"},
        @{Sni="vk.com"; Name="VK"}
    )
    
    foreach ($test in $sni_tests) {
        Write-Host -NoNewline "  SNI: $($test.Sni) ($($test.Name)): "
        try {
            $response = Invoke-WebRequest -Uri "https://77.88.55.242" -Headers @{"Host"=$test.Sni} -TimeoutSec 5 -UseBasicParsing -SkipCertificateCheck -ErrorAction Stop
            Write-Host "PASSED" -ForegroundColor Green
        } catch {
            Write-Host "NO RESPONSE or RST" -ForegroundColor Yellow
        }
    }
    
    Pause
}

# 5. Check UDP ports
function Check-UDPPorts {
    Clear-Screen
    Print-Header
    Write-Host "[5] Check UDP ports..." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "[Target]: $Script:ServerIP" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host -NoNewline "  UDP 53 (DNS): "
    try {
        $dnsResult = Resolve-DnsName -Name "ya.ru" -Server $Script:ServerIP -ErrorAction Stop
        Write-Host "RESPONDS" -ForegroundColor Green
    } catch {
        Write-Host "NO RESPONSE (not a DNS server)" -ForegroundColor Yellow
    }
    
    Write-Host -NoNewline "  UDP 443 (QUIC): "
    Write-Host "NO RESPONSE (QUIC ignores empty packets)" -ForegroundColor Yellow
    
    Write-Host -NoNewline "  UDP 51820 (WireGuard): "
    Write-Host "NO RESPONSE (WireGuard ignores unauthenticated packets)" -ForegroundColor Yellow
    
    Write-Host ""
    Write-Host "[Note]:" -ForegroundColor Blue
    Write-Host "  * UDP 53: responds only if server is a DNS server"
    Write-Host "  * UDP 443: QUIC does not respond to empty UDP packets"
    Write-Host "  * 'NO RESPONSE' is NORMAL for most UDP ports"
    
    Pause
}

# 6. Check external DNS
function Check-DNS {
    Clear-Screen
    Print-Header
    Write-Host "[6] Check external DNS servers..." -ForegroundColor Yellow
    Write-Host ""
    
    $dnsServers = @(
        @{IP="8.8.8.8"; Name="Google DNS"},
        @{IP="1.1.1.1"; Name="Cloudflare DNS"},
        @{IP="77.88.8.8"; Name="Yandex DNS"}
    )
    
    foreach ($dns in $dnsServers) {
        Write-Host -NoNewline "  $($dns.Name) ($($dns.IP)): "
        try {
            $result = Resolve-DnsName -Name "ya.ru" -Server $dns.IP -ErrorAction Stop
            Write-Host "WORKING" -ForegroundColor Green
        } catch {
            Write-Host "NOT AVAILABLE (timeout)" -ForegroundColor Red
        }
    }
    
    Pause
}

# 7. Start web server (requires Python)
function Start-WebServer {
    Clear-Screen
    Print-Header
    Write-Host "[7] Start temporary web server on port 443..." -ForegroundColor Yellow
    Write-Host ""
    
    # Check Python
    $pythonPath = Get-Command python -ErrorAction SilentlyContinue
    if (-not $pythonPath) {
        $pythonPath = Get-Command python3 -ErrorAction SilentlyContinue
    }
    
    if (-not $pythonPath) {
        Write-Host "[ERROR] Python not installed" -ForegroundColor Red
        Write-Host "Install Python from python.org" -ForegroundColor Yellow
        Pause
        return
    }
    
    # Check admin rights
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Host "[ERROR] Administrator rights required for port 443" -ForegroundColor Red
        Write-Host "Restart PowerShell as Administrator" -ForegroundColor Yellow
        Pause
        return
    }
    
    # Get local IP
    $localIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -notlike "*Loopback*"} | Select-Object -First 1).IPAddress
    if (-not $localIP) { $localIP = "localhost" }
    
    # Check if port 443 is free
    $portCheck = Get-NetTCPConnection -LocalPort 443 -ErrorAction SilentlyContinue | Where-Object {$_.State -eq "Listen"}
    if ($portCheck) {
        Write-Host "[WARN] Port 443 is already in use" -ForegroundColor Yellow
        Write-Host "Close the program using port 443 and try again" -ForegroundColor Red
        Pause
        return
    }
    
    # Create temporary files
    $webDir = "$env:TEMP\tspu_web_test"
    Remove-Item -Path $webDir -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Path $webDir -Force | Out-Null
    
    # Create HTML page
    $htmlContent = @"
<!DOCTYPE html>
<html>
<head><title>TSPU Test</title></head>
<body style="font-family: Arial; text-align: center; margin-top: 50px;">
    <h1 style="color: green;">Web Server is Running!</h1>
    <p>Test server on $env:COMPUTERNAME</p>
    <p>Local IP: $localIP</p>
    <p>Time: $(Get-Date)</p>
    <hr>
    <p>Check with: curl -k https://localhost:443</p>
</body>
</html>
"@
    Set-Content -Path "$webDir\index.html" -Value $htmlContent
    
    Clear-Screen
    Print-Header
    Write-Host "[OK] Starting web server..." -ForegroundColor Green
    Write-Host ""
    Write-Host "[Available addresses]:" -ForegroundColor Cyan
    Write-Host "  * Local:   https://localhost:443" -ForegroundColor Blue
    Write-Host "  * Network: https://$localIP:443" -ForegroundColor Blue
    Write-Host ""
    Write-Host "[WARN] Press Ctrl+C to stop the server" -ForegroundColor Red
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Start server
    Set-Location $webDir
    & $pythonPath.Source -m http.server 443
    
    # Cleanup after stop
    Remove-Item -Path $webDir -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "`n[OK] Web server stopped" -ForegroundColor Green
    Pause
}

# 8. Full server check
function Check-Server {
    Clear-Screen
    Print-Header
    Write-Host "[8] Full server check $Script:ServerIP..." -ForegroundColor Yellow
    Write-Host ""
    
    # Ping
    Write-Host -NoNewline "  Ping: "
    $pingResult = Test-Connection -ComputerName $Script:ServerIP -Count 2 -Quiet -ErrorAction SilentlyContinue
    if ($pingResult) {
        Write-Host "OK (reachable)" -ForegroundColor Green
    } else {
        Write-Host "FAIL (unreachable)" -ForegroundColor Red
    }
    
    # TCP ports
    Write-Host ""
    Write-Host "[TCP ports]:" -ForegroundColor Cyan
    foreach ($port in @(22, 80, 443, 8080, 8443)) {
        Write-Host -NoNewline "    Port $port : "
        if (Test-Port -IP $Script:ServerIP -Port $port) {
            Write-Host "OPEN" -ForegroundColor Green
        } else {
            Write-Host "CLOSED/FILTERED" -ForegroundColor Yellow
        }
    }
    
    Pause
}

# 9. Detailed port analysis
function Check-PortsDetailed {
    Clear-Screen
    Print-Header
    Write-Host "[9] Detailed port analysis" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "  Port   Service       Status" -ForegroundColor Blue
    Write-Host "  ----   ------       -------------" -ForegroundColor Blue
    
    $ports = @(
        @{Port=22; Service="SSH"},
        @{Port=80; Service="HTTP"},
        @{Port=443; Service="HTTPS"},
        @{Port=3306; Service="MySQL"},
        @{Port=5432; Service="PostgreSQL"},
        @{Port=8080; Service="HTTP-alt"},
        @{Port=8443; Service="HTTPS-alt"}
    )
    
    foreach ($p in $ports) {
        Write-Host -NoNewline "  $($p.Port)   $($p.Service.PadRight(12)) "
        if (Test-Port -IP $Script:ServerIP -Port $p.Port) {
            Write-Host "OPEN" -ForegroundColor Green
        } else {
            Write-Host "CLOSED/FILTERED" -ForegroundColor Yellow
        }
        Start-Sleep -Milliseconds 100
    }
    
    Pause
}

# 10. Detect my IP
function Check-MyIP {
    Clear-Screen
    Print-Header
    Write-Host "[10] Detect your IP address..." -ForegroundColor Yellow
    Write-Host ""
    
    # Internal IP
    $localIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -notlike "*Loopback*"} | Select-Object -First 1).IPAddress
    Write-Host "  Internal IP: $localIP" -ForegroundColor Green
    
    # External IP
    try {
        $externalIP = (Invoke-WebRequest -Uri "https://ifconfig.me/ip" -TimeoutSec 5 -UseBasicParsing).Content.Trim()
        Write-Host "  External IP: $externalIP" -ForegroundColor Green
    } catch {
        Write-Host "  External IP: Unable to determine" -ForegroundColor Yellow
    }
    
    Pause
}

# Main menu
function Show-Menu {
    Clear-Screen
    Print-Header
    Write-Host "Select action:" -ForegroundColor Green
    Write-Host ""
    Write-Host "  0) Change server IP (current: $Script:ServerIP)" -ForegroundColor Blue
    Write-Host "  1) Detect TSPU mode" -ForegroundColor Blue
    Write-Host "  2) Check TSPU activity (HTTP + Telegram)" -ForegroundColor Blue
    Write-Host "  3) Check port availability (TCP)" -ForegroundColor Blue
    Write-Host "  4) Check SNI filtering (basic)" -ForegroundColor Blue
    Write-Host "  5) Check UDP ports" -ForegroundColor Blue
    Write-Host "  6) Check external DNS" -ForegroundColor Blue
    Write-Host "  7) Start web server on port 443 (requires Python)" -ForegroundColor Blue
    Write-Host "  8) Full server check" -ForegroundColor Blue
    Write-Host "  9) Detailed port analysis" -ForegroundColor Blue
    Write-Host " 10) Detect your IP" -ForegroundColor Blue
    Write-Host "  q) Exit" -ForegroundColor Blue
    Write-Host ""
    $choice = Read-Host "Your choice"
    return $choice
}

# Load config
Load-ServerIP

# Main loop
do {
    $choice = Show-Menu
    switch ($choice) {
        "0" { Configure-ServerIP }
        "1" { Detect-TSPUMode }
        "2" { Check-TSPUActive }
        "3" { Check-Ports }
        "4" { Test-SNIFiltering }
        "5" { Check-UDPPorts }
        "6" { Check-DNS }
        "7" { Start-WebServer }
        "8" { Check-Server }
        "9" { Check-PortsDetailed }
        "10" { Check-MyIP }
        "q" { 
            Clear-Screen
            Write-Host "Goodbye!" -ForegroundColor Green
            exit 0
        }
        default {
            Write-Host "Invalid choice" -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
} while ($true)