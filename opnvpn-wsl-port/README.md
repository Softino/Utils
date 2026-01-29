```markdown
# WSL VPN Bridge Manager

A PowerShell automation tool to route Windows traffic through a "Double VPN" setup using WSL2. 

**Architecture:** `Windows (Mullvad Bridge Mode)` -> `WSL2 (Shadowsocks Proxy)` -> `WSL2 (OpenVPN Tunnel)` -> `Internet`

## 🚀 Features
* **Automated Startup:** Launches OpenVPN and Shadowsocks in the background with one click.
* **Smart Routing:** Automatically fixes WSL routing tables to prevent connection loops.
* **Status Monitoring:** Check the live status of the OpenVPN tunnel and Proxy server.
* **Clean Shutdown:** Kills all background processes when stopped.

---

## 📋 Prerequisites

### 1. Windows
* **WSL2** installed (default Ubuntu distro recommended).
* **Mullvad VPN** (or any app supporting Bridge Mode/Shadowsocks).
* **PowerShell** (Administrator rights not usually required, but recommended for initial setup).

### 2. WSL (Ubuntu) Dependencies
Install OpenVPN and Shadowsocks inside your WSL instance:
```bash
sudo apt update
sudo apt install openvpn shadowsocks-libev -y

```

---

## ⚙️ Installation & Setup

### Step 1: Prepare WSL Configurations

Create a folder in your WSL home directory (e.g., `~/vpn_confs/`) and place your files there:

1. **OpenVPN Profile:** `myprofile.ovpn` (Ensure it contains `auth-user-pass` pointing to a file if credentials are needed).
2. **Shadowsocks Config:** `config.json`

**Example `config.json`:**

```json
{
    "server": "0.0.0.0",
    "server_port": 1080,
    "password": "StrongPasswordHere",
    "timeout": 300,
    "method": "chacha20-ietf-poly1305"
}

```

### Step 2: Configure Passwordless Sudo

The script needs to run `openvpn` as root without a password prompt.

1. Open WSL terminal.
2. Run `sudo visudo`.
3. Add this line to the bottom (replace `youruser` with your actual WSL username):

```text
youruser ALL=(ALL) NOPASSWD: /usr/sbin/openvpn, /usr/bin/ss-server, /usr/bin/ip, /usr/bin/killall

```

### Step 3: Configure the Script

Open `VPN-Manager.ps1` and edit the configuration block at the top:

```powershell
$WslUser    = "your_wsl_username"
$OvpnConfig = "~/vpn_confs/myprofile.ovpn"
$SsConfig   = "~/vpn_confs/config.json"

```

---

## 🎮 Usage

You can run the script directly from PowerShell or create shortcuts.

### Start the Bridge

```powershell
.\VPN-Manager.ps1 -Action Start

```

### Check Status

Shows if OpenVPN is connected (Tun0 active) and if Shadowsocks is running.

```powershell
.\VPN-Manager.ps1 -Action Status

```

### Stop the Bridge

Kills the background processes.

```powershell
.\VPN-Manager.ps1 -Action Stop

```

---

## 🔗 Connecting Mullvad (Windows)

1. Open Mullvad Settings -> **VPN Settings** -> **Bridge Mode**.
2. Set to **On** -> **Configure Bridge**.
3. Add a **Custom Bridge**:

* **IP:** Your WSL IP (The script ensures this is reachable).
* **Port:** `1080` (or whatever is in your json).
* **Password:** (From your json).

4. Connect Mullvad.

## 🛠️ Troubleshooting

* **"Transport endpoint is not connected":** The OpenVPN tunnel is down. Run `Status` to check.
* **Mullvad connects/disconnects loop:** The routing fix failed. Stop the bridge and Start it again.
* **Permission Denied:** Ensure you completed **Step 2 (visudo)** correctly.

```

To complete your setup, I can help you create the "One-Click" desktop icons mentioned in the Usage section.

* [Creating the desktop shortcuts script](http://googleusercontent.com/interactive_content/0)
* [Generating a troubleshooting script](http://googleusercontent.com/interactive_content/1)
* [Adding multi-profile support](http://googleusercontent.com/interactive_content/2)

```


### Fix the PowerShell Error

Your system is blocking the script for security reasons. To allow it to run, open your PowerShell terminal and run this single command:

**PowerShell**

```
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

*Press `Y` (Yes) when asked.*

**Alternative:** If you don't want to change the global setting, you can run the script once using the "Bypass" flag:

**PowerShell**

```
powershell.exe -ExecutionPolicy Bypass -File .\VPN-Manager.ps1 -Action Start
```
