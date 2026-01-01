# Prerequisites Guide

## System Requirements

### Operating Systems
- ✅ Windows 10 (version 1809 or later)
- ✅ Windows 11
- ✅ Windows Server 2016 or later
- ✅ macOS 10.13+ (with PowerShell 7)
- ✅ Linux (Ubuntu 18.04+, CentOS 7+, with PowerShell 7)

### PowerShell Versions
- **Windows**: PowerShell 5.1 (pre-installed) or PowerShell 7+
- **macOS/Linux**: PowerShell 7+ (Core)

---

## Required Modules

### ExchangeOnlineManagement Module

**Version Required**: 2.0.5 or later

#### Installation Steps:

**Windows PowerShell 5.1:**
```powershell
# Run as Administrator or use -Scope CurrentUser
Install-Module -Name ExchangeOnlineManagement -Scope CurrentUser -Force

# Import the module
Import-Module ExchangeOnlineManagement

# Verify installation
Get-Module -ListAvailable ExchangeOnlineManagement
```

**PowerShell 7+ (All Platforms):**
```pwsh
# Install module
Install-Module -Name ExchangeOnlineManagement -Scope CurrentUser -Force

# Import module
Import-Module ExchangeOnlineManagement

# Check version
Get-InstalledModule ExchangeOnlineManagement
```

---

## Microsoft 365 Requirements

### Account Permissions

Your admin account must have **ONE** of the following roles:

1. **Exchange Administrator** (Minimum Required)
   - Can manage Exchange Online settings
   - Can modify user mailboxes and email addresses
   - Recommended for dedicated Exchange administrators

2. **Global Administrator** (Full Access)
   - Has all Exchange Administrator permissions
   - Can manage all aspects of Microsoft 365
   - Recommended if you manage multiple services

### How to Check Your Permissions:

1. Go to [Microsoft 365 Admin Center](https://admin.microsoft.com)
2. Navigate to **Users** → **Active users**
3. Select your account
4. Click **Manage roles**
5. Verify you have **Exchange Administrator** or **Global Administrator**

### How to Assign Permissions (if missing):

If you don't have the required role, ask a Global Administrator to:

1. Sign in to [Microsoft 365 Admin Center](https://admin.microsoft.com)
2. Go to **Users** → **Active users**
3. Select your account
4. Click **Manage roles**
5. Select **Exchange Administrator**
6. Click **Save changes**

---

## Network Requirements

### Required Endpoints

Ensure you can access these Microsoft endpoints:

- `*.outlook.office365.com` (Port 443)
- `*.protection.outlook.com` (Port 443)
- `*.login.microsoftonline.com` (Port 443)
- `*.compliance.microsoft.com` (Port 443)

### Firewall & Proxy

If behind a corporate firewall or proxy:

```powershell
# Configure proxy for PowerShell session
$proxyServer = "http://proxy.company.com:8080"
[System.Net.WebRequest]::DefaultWebProxy = New-Object System.Net.WebProxy($proxyServer)
```

### Test Connectivity:

```powershell
# Test connection to Exchange Online
Test-NetConnection -ComputerName outlook.office365.com -Port 443

# Test authentication endpoint
Test-NetConnection -ComputerName login.microsoftonline.com -Port 443
```

---

## Installation by Platform

### Windows 10/11

#### Step 1: Check PowerShell Version
```powershell
$PSVersionTable.PSVersion
```
Should show version 5.1 or higher.

#### Step 2: Set Execution Policy
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### Step 3: Install Module
```powershell
Install-Module -Name ExchangeOnlineManagement -Scope CurrentUser -Force
```

#### Step 4: Connect to Exchange Online
```powershell
Import-Module ExchangeOnlineManagement
Connect-ExchangeOnline
```

---

### macOS

#### Step 1: Install PowerShell 7
```bash
# Using Homebrew
brew install --cask powershell

# Verify installation
pwsh --version
```

#### Step 2: Launch PowerShell
```bash
pwsh
```

#### Step 3: Install Exchange Module
```powershell
Install-Module -Name ExchangeOnlineManagement -Scope CurrentUser -Force
```

#### Step 4: Connect to Exchange Online
```powershell
Import-Module ExchangeOnlineManagement
Connect-ExchangeOnline
```

---

### Linux (Ubuntu/Debian)

#### Step 1: Install PowerShell 7
```bash
# Update package list
sudo apt-get update

# Install PowerShell
sudo apt-get install -y wget apt-transport-https software-properties-common

# Download Microsoft repository GPG keys
wget -q "https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb"

# Register repository
sudo dpkg -i packages-microsoft-prod.deb

# Install PowerShell
sudo apt-get update
sudo apt-get install -y powershell

# Verify
pwsh --version
```

#### Step 2: Launch PowerShell
```bash
pwsh
```

#### Step 3: Install Exchange Module
```powershell
Install-Module -Name ExchangeOnlineManagement -Scope CurrentUser -Force
```

#### Step 4: Connect to Exchange Online
```powershell
Import-Module ExchangeOnlineManagement
Connect-ExchangeOnline
```

---

### Linux (CentOS/RHEL)

#### Step 1: Install PowerShell 7
```bash
# Register Microsoft repository
curl https://packages.microsoft.com/config/rhel/7/prod.repo | sudo tee /etc/yum.repos.d/microsoft.repo

# Install PowerShell
sudo yum install -y powershell

# Verify
pwsh --version
```

#### Step 2: Launch PowerShell
```bash
pwsh
```

#### Step 3: Install Exchange Module
```powershell
Install-Module -Name ExchangeOnlineManagement -Scope CurrentUser -Force
```

---

## Verification Checklist

Before running the migration script, verify:

- [ ] PowerShell version 5.1+ installed
- [ ] ExchangeOnlineManagement module installed
- [ ] Can connect to Exchange Online successfully
- [ ] Admin account has Exchange Administrator role
- [ ] Can run `Get-Mailbox` command without errors
- [ ] Execution policy allows script execution

### Quick Verification Script:

```powershell
# Run this to verify everything is ready
Write-Host "Checking prerequisites..." -ForegroundColor Cyan

# Check PowerShell version
$psVersion = $PSVersionTable.PSVersion.Major
if ($psVersion -ge 5) {
    Write-Host "✓ PowerShell version: $($PSVersionTable.PSVersion)" -ForegroundColor Green
} else {
    Write-Host "✗ PowerShell version too old: $($PSVersionTable.PSVersion)" -ForegroundColor Red
}

# Check module
$module = Get-Module -ListAvailable ExchangeOnlineManagement
if ($module) {
    Write-Host "✓ ExchangeOnlineManagement module installed: $($module.Version)" -ForegroundColor Green
} else {
    Write-Host "✗ ExchangeOnlineManagement module not found" -ForegroundColor Red
}

# Check connection
try {
    $null = Get-OrganizationConfig -ErrorAction Stop
    Write-Host "✓ Connected to Exchange Online" -ForegroundColor Green
} catch {
    Write-Host "✗ Not connected to Exchange Online" -ForegroundColor Yellow
    Write-Host "  Run: Connect-ExchangeOnline" -ForegroundColor Gray
}

Write-Host "`nPrerequisite check complete!" -ForegroundColor Cyan
```

---

## Troubleshooting Prerequisites

### Issue: "Install-Module: Access Denied"

**Solution:**
```powershell
# Install for current user only (no admin required)
Install-Module -Name ExchangeOnlineManagement -Scope CurrentUser -Force
```

### Issue: "Module not found after installation"

**Solution:**
```powershell
# Import module manually
Import-Module ExchangeOnlineManagement -Force

# Check module path
$env:PSModulePath -split ';'
```

### Issue: "Connect-ExchangeOnline not recognized"

**Solution:**
```powershell
# Uninstall and reinstall module
Uninstall-Module ExchangeOnlineManagement -Force
Install-Module -Name ExchangeOnlineManagement -Scope CurrentUser -Force
Import-Module ExchangeOnlineManagement
```

### Issue: "TLS Error" or "Certificate Error"

**Solution:**
```powershell
# Enable TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
```

---

## Next Steps

Once all prerequisites are met:

1. Download the script: `SafePrimaryEmailChanger.ps1`
2. Review the [README.md](README.md) for usage instructions
3. Test on a single user first
4. Proceed with bulk migration if needed

---

## Additional Resources

- [ExchangeOnlineManagement Module Documentation](https://docs.microsoft.com/powershell/exchange/exchange-online-powershell)
- [Install PowerShell on Windows](https://docs.microsoft.com/powershell/scripting/install/installing-powershell-on-windows)
- [Install PowerShell on macOS](https://docs.microsoft.com/powershell/scripting/install/installing-powershell-on-macos)
- [Install PowerShell on Linux](https://docs.microsoft.com/powershell/scripting/install/installing-powershell-on-linux)
- [Microsoft 365 Admin Roles](https://docs.microsoft.com/microsoft-365/admin/add-users/about-admin-roles)
