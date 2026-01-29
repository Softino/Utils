param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("Start", "Stop", "Status")]
    [string]$Action,

    [Parameter(Mandatory=$false)]
    [string]$Distro = "Ubuntu-24.04"  # Default name if none provided
)

# --- CONFIGURATION ---
$WslUser   = "whitew"                       # Your WSL Username
$OvpnConfig = "~/vpn_confs/conf.ovpn"  # Path inside WSL
$SsConfig   = "~/vpn_confs/config.json"     # Path inside WSL
# ---------------------

function Get-Status {
    Write-Host "--- Status for $Distro ---" -ForegroundColor Cyan
    
    # 1. Get WSL IP (ETH0) for Mullvad Bridge
    $WslIP = wsl -d $Distro -u $WslUser bash -c "ip addr show eth0 | grep 'inet\b' | awk '{print `$2}' | cut -d/ -f1" 2>$null
    if ($WslIP) {
        Write-Host "WSL IP:   " -NoNewline; Write-Host "$WslIP" -ForegroundColor Yellow
        Write-Host "          (Use this IP in Mullvad Bridge Settings)" -ForegroundColor DarkGray
    } else {
        Write-Host "WSL IP:   " -NoNewline; Write-Host "NOT FOUND" -ForegroundColor Red
    }

    # 2. Check OpenVPN
    $tun = wsl -d $Distro -u $WslUser ip addr show tun0 2>$null
    if ($tun -match "inet") { 
        Write-Host "OpenVPN:  " -NoNewline; Write-Host "CONNECTED" -ForegroundColor Green 
    } else { 
        Write-Host "OpenVPN:  " -NoNewline; Write-Host "DISCONNECTED" -ForegroundColor Red 
    }

    # 3. Check Shadowsocks
    $ss = wsl -d $Distro -u $WslUser pgrep -x ss-server 2>$null
    if ($ss) { 
        Write-Host "Proxy:    " -NoNewline; Write-Host "RUNNING (PID: $ss)" -ForegroundColor Green 
    } else { 
        Write-Host "Proxy:    " -NoNewline; Write-Host "STOPPED" -ForegroundColor Red 
    }
}

function Stop-Bridge {
    Write-Host "Stopping services on $Distro..." -ForegroundColor Yellow
    wsl -d $Distro -u $WslUser sudo killall openvpn 2>$null
    wsl -d $Distro -u $WslUser sudo killall ss-server 2>$null
    Write-Host "Services killed." -ForegroundColor Green
}

function Start-Bridge {
    Write-Host "--- Starting VPN Bridge on $Distro ---" -ForegroundColor Cyan

    # 1. Cleanup
    Stop-Bridge

    # 2. Start OpenVPN
    Write-Host "Starting OpenVPN..."
    wsl -d $Distro -u $WslUser sudo openvpn --config $OvpnConfig --daemon

    # 3. Wait for Tunnel
    Write-Host "Waiting for tunnel..." -NoNewline
    $retries = 0
    while ($retries -lt 10) {
        $check = wsl -d $Distro -u $WslUser ip addr show tun0 2>$null
        if ($check -match "inet") {
            Write-Host " [OK]" -ForegroundColor Green
            break
        }
        Start-Sleep -Seconds 1
        Write-Host "." -NoNewline
        $retries++
    }

    if ($retries -eq 10) {
        Write-Host " [FAILED]" -ForegroundColor Red
        return
    }

    # 4. Fix Routes
    Write-Host "Fixing return routes..."
    # Step A: Get the current subnet from WSL (calculated safely)
    $Subnet = wsl -d $Distro -u $WslUser bash -c "ip route show dev eth0 | grep 'proto kernel' | cut -d ' ' -f 1"
    
    # Step B: Ensure the route exists (Suppressing 'File exists' errors)
    if ($Subnet) {
        wsl -d $Distro -u $WslUser sudo ip route add $Subnet dev eth0 2>$null
    }

    # 5. Start Shadowsocks
    Write-Host "Starting Shadowsocks..."
    wsl -d $Distro -u $WslUser sudo ss-server -c $SsConfig -f /tmp/ss.pid

    Write-Host "--- Bridge Active ---" -ForegroundColor Green
}

# --- MAIN LOGIC ---
switch ($Action) {
    "Start"  { Start-Bridge }
    "Stop"   { Stop-Bridge }
    "Status" { Get-Status }
}

if ($Action -eq "Status") { Pause }