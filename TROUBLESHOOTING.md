# Troubleshooting Guide

Common issues and solutions for the Microsoft 365 Email Migration Tool.

---

## Table of Contents

1. [Connection Issues](#connection-issues)
2. [Permission Errors](#permission-errors)
3. [Module Problems](#module-problems)
4. [Script Execution Errors](#script-execution-errors)
5. [Mailbox Issues](#mailbox-issues)
6. [Alias Problems](#alias-problems)
7. [Platform-Specific Issues](#platform-specific-issues)

---

## Connection Issues

### Issue 1: "Not connected to Exchange Online"

**Error Message:**
```
❌ Not connected to Exchange Online!
```

**Cause:** Script requires active Exchange Online session.

**Solution:**
```powershell
# Connect to Exchange Online
Connect-ExchangeOnline

# Verify connection
Get-OrganizationConfig
```

**If connection fails:**
```powershell
# Try with specific admin credentials
Connect-ExchangeOnline -UserPrincipalName admin@yourdomain.com

# Or use device code authentication
Connect-ExchangeOnline -Device
```

---

### Issue 2: "Connection timeout" or "Unable to connect"

**Cause:** Network/firewall blocking Microsoft endpoints.

**Solution:**

1. **Check internet connection:**
   ```powershell
   Test-NetConnection -ComputerName outlook.office365.com -Port 443
   ```

2. **Configure proxy (if behind corporate proxy):**
   ```powershell
   $proxy = New-Object System.Net.WebProxy("http://proxy:8080")
   [System.Net.WebRequest]::DefaultWebProxy = $proxy
   Connect-ExchangeOnline
   ```

3. **Whitelist required endpoints:**
   - `*.outlook.office365.com`
   - `*.login.microsoftonline.com`
   - `*.protection.outlook.com`

---

### Issue 3: "Authentication failed"

**Cause:** MFA (Multi-Factor Authentication) or conditional access policies.

**Solution:**
```powershell
# Use modern authentication
Connect-ExchangeOnline -ShowBanner:$false

# Or use certificate-based authentication for automation
Connect-ExchangeOnline -CertificateThumbPrint "THUMBPRINT" -AppID "APP_ID" -Organization "tenant.onmicrosoft.com"
```

---

## Permission Errors

### Issue 4: "Access Denied" or "Insufficient Permissions"

**Error Message:**
```
Get-Mailbox : Access Denied
```

**Cause:** Admin account lacks required permissions.

**Solution:**

1. **Verify your role:**
   ```powershell
   # Check current admin roles
   Get-MsolUser -UserPrincipalName admin@domain.com | Select-Object -ExpandProperty Roles
   ```

2. **Required roles:**
   - Exchange Administrator (minimum)
   - Global Administrator (recommended)

3. **Request role assignment:**
   - Ask Global Admin to assign **Exchange Administrator** role
   - Or temporarily assign **Global Administrator** for migration

4. **Verify mailbox access:**
   ```powershell
   # Test if you can read mailboxes
   Get-Mailbox -ResultSize 1
   
   # Test if you can modify mailboxes
   Get-Mailbox -Identity "testuser@domain.com"
   ```

---

### Issue 5: "Operation not allowed on this mailbox"

**Cause:** Mailbox is a shared mailbox or has special restrictions.

**Solution:**
```powershell
# Check mailbox type
Get-Mailbox -Identity user@domain.com | Select-Object RecipientTypeDetails

# This script works for:
# - UserMailbox ✓
# - SharedMailbox ✓
# - RoomMailbox ✗ (not recommended)
# - EquipmentMailbox ✗ (not recommended)
```

---

## Module Problems

### Issue 6: "Module ExchangeOnlineManagement not found"

**Cause:** Module not installed or not in module path.

**Solution:**
```powershell
# Install module
Install-Module -Name ExchangeOnlineManagement -Scope CurrentUser -Force

# Import module
Import-Module ExchangeOnlineManagement

# Verify installation
Get-Module -ListAvailable ExchangeOnlineManagement
```

**If still not found:**
```powershell
# Check module path
$env:PSModulePath -split ';'

# Install to specific location
Install-Module -Name ExchangeOnlineManagement -Scope CurrentUser -Force -Repository PSGallery
```

---

### Issue 7: "Module version incompatible"

**Cause:** Old version of ExchangeOnlineManagement module.

**Solution:**
```powershell
# Check current version
Get-InstalledModule ExchangeOnlineManagement

# Update to latest version
Update-Module -Name ExchangeOnlineManagement -Force

# Or uninstall and reinstall
Uninstall-Module ExchangeOnlineManagement -AllVersions -Force
Install-Module -Name ExchangeOnlineManagement -Scope CurrentUser -Force
```

---

### Issue 8: "Could not load type 'System.Security.Cryptography.SHA256Cng'"

**Cause:** .NET Framework issue on older systems.

**Solution:**
```powershell
# Option 1: Use PowerShell 7
pwsh
Install-Module ExchangeOnlineManagement
Connect-ExchangeOnline

# Option 2: Update .NET Framework (Windows)
# Download from: https://dotnet.microsoft.com/download/dotnet-framework
```

---

## Script Execution Errors

### Issue 9: "Script cannot be loaded because running scripts is disabled"

**Error Message:**
```
.\SafePrimaryEmailChanger.ps1 : File cannot be loaded because running scripts is disabled on this system.
```

**Cause:** PowerShell execution policy restricts script execution.

**Solution:**
```powershell
# Check current policy
Get-ExecutionPolicy

# Set policy for current user
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Or bypass for single session
PowerShell -ExecutionPolicy Bypass -File .\SafePrimaryEmailChanger.ps1
```

---

### Issue 10: "Parameter binding failed"

**Cause:** Invalid parameters passed to script.

**Solution:**
```powershell
# Correct syntax:
.\SafePrimaryEmailChanger.ps1 -UserUPN "user@domain.com" -NewPrimaryEmail "user@newdomain.com"

# Or use interactive mode:
.\SafePrimaryEmailChanger.ps1
```

---

### Issue 11: "Unexpected token" or syntax errors

**Cause:** Script file corrupted or encoding issue.

**Solution:**
```powershell
# Re-download script from GitHub
# Ensure file encoding is UTF-8

# Check file encoding
Get-Content .\SafePrimaryEmailChanger.ps1 -Encoding UTF8

# Save with correct encoding
Get-Content .\SafePrimaryEmailChanger.ps1 | Set-Content -Path .\SafePrimaryEmailChanger_Fixed.ps1 -Encoding UTF8
```

---

## Mailbox Issues

### Issue 12: "Mailbox not found"

**Error Message:**
```
Get-Mailbox : The operation couldn't be performed because object 'user@domain.com' couldn't be found
```

**Cause:** User doesn't exist or UPN is incorrect.

**Solution:**
```powershell
# Search for user
Get-Mailbox -Identity *username* | Select-Object DisplayName, UserPrincipalName, PrimarySmtpAddress

# Or search by email
Get-Mailbox -Filter "EmailAddresses -like '*user@domain.com*'"

# Verify exact UPN
Get-MsolUser -SearchString "username" | Select-Object UserPrincipalName
```

---

### Issue 13: "Mailbox is in different datacenter"

**Cause:** Exchange Online routing issue (rare).

**Solution:**
```powershell
# Reconnect to correct datacenter
Disconnect-ExchangeOnline -Confirm:$false
Connect-ExchangeOnline -ExchangeEnvironmentName O365Default

# Or specify region
Connect-ExchangeOnline -ConnectionUri https://outlook.office365.com/powershell-liveid/
```

---

### Issue 14: "Cannot modify mailbox during migration"

**Cause:** Mailbox is being migrated or is in a transitional state.

**Solution:**
```powershell
# Check mailbox move status
Get-MoveRequest -Identity user@domain.com

# Wait for move to complete or clear
Remove-MoveRequest -Identity user@domain.com -Confirm:$false
```

---

## Alias Problems

### Issue 15: "Email address already in use"

**Error Message:**
```
The email address 'user@domain.com' is already being used
```

**Cause:** Email address is assigned to another mailbox or as an alias.

**Solution:**
```powershell
# Find where email is used
Get-Mailbox -Filter "EmailAddresses -like '*user@domain.com*" | Select-Object DisplayName, UserPrincipalName, EmailAddresses

# Remove from other mailbox if needed
Set-Mailbox -Identity "othermailbox@domain.com" -EmailAddresses @{Remove="smtp:user@domain.com"}

# Then run migration script again
```

---

### Issue 16: "Aliases not preserved after migration"

**Cause:** Script interruption or Exchange Online sync delay.

**Solution:**
```powershell
# Re-run script - it will add missing aliases
.\SafePrimaryEmailChanger.ps1 -UserUPN "user@domain.com" -NewPrimaryEmail "user@newdomain.com"

# Or manually add missing aliases
Set-Mailbox -Identity "user@domain.com" -EmailAddresses @{Add="smtp:oldalias@domain.com"}

# Verify aliases
Get-Mailbox -Identity "user@domain.com" | Select-Object -ExpandProperty EmailAddresses
```

---

### Issue 17: "Old primary not added as alias"

**Cause:** Old primary same as new primary (no change needed).

**Solution:**
This is expected behavior. The script only adds old primary as alias if it's different from new primary.

**Verify:**
```powershell
# Check all aliases
Get-Mailbox -Identity "user@domain.com" | Select-Object -ExpandProperty EmailAddresses

# Should show old primary with lowercase "smtp:" prefix
```

---

## Platform-Specific Issues

### Issue 18: macOS - "Operation not permitted"

**Cause:** macOS security restrictions.

**Solution:**
```bash
# Grant Full Disk Access to Terminal
# System Preferences → Security & Privacy → Privacy → Full Disk Access → Add Terminal

# Or use PowerShell 7
pwsh
./SafePrimaryEmailChanger.ps1
```

---

### Issue 19: Linux - "System.PlatformNotSupportedException"

**Cause:** Missing .NET dependencies on Linux.

**Solution:**
```bash
# Install required libraries (Ubuntu/Debian)
sudo apt-get install -y libicu-dev

# Install PowerShell 7 (not older versions)
# See PREREQUISITES.md for installation steps
```

---

### Issue 20: macOS - "Brew install powershell failed"

**Solution:**
```bash
# Update Homebrew
brew update

# Install PowerShell
brew install --cask powershell

# If fails, try:
brew install --cask --force powershell

# Verify installation
pwsh --version
```

---

## Performance Issues

### Issue 21: "Script running very slow"

**Cause:** Large number of aliases or Exchange Online throttling.

**Solution:**
```powershell
# Add delays between operations
Start-Sleep -Seconds 3

# For bulk processing, add delays between users
Import-Csv users.csv | ForEach-Object {
    .\SafePrimaryEmailChanger.ps1 -UserUPN $_.UserUPN -NewPrimaryEmail $_.NewPrimaryEmail
    Start-Sleep -Seconds 10  # Add 10 second delay
}

# Run during off-peak hours (nights/weekends)
```

---

### Issue 22: "Throttling errors"

**Error Message:**
```
The user has exceeded the maximum number of requests
```

**Cause:** Too many API calls to Exchange Online.

**Solution:**
```powershell
# Slow down batch processing
Start-Sleep -Seconds 30  # Wait 30 seconds between users

# Or process in smaller batches
# Process 10 users, wait 5 minutes, process next 10
```

---

## Validation Issues

### Issue 23: "UPN changed unexpectedly"

**Cause:** Email address policy override.

**Solution:**
The script uses `-EmailAddressPolicyEnabled $false` to prevent this. If UPN still changed:

```powershell
# Manually revert UPN
Set-Mailbox -Identity "user@newdomain.com" -UserPrincipalName "user@olddomain.com"

# Verify email address policy is disabled
Get-Mailbox -Identity "user@olddomain.com" | Select-Object EmailAddressPolicyEnabled
```

---

### Issue 24: "Validation shows False but email works"

**Cause:** Exchange Online replication delay (can take 5-15 minutes).

**Solution:**
```powershell
# Wait a few minutes
Start-Sleep -Seconds 300

# Re-check mailbox
Get-Mailbox -Identity "user@domain.com" | Select-Object UserPrincipalName, PrimarySmtpAddress, EmailAddresses

# Test email delivery
# Send test email to new primary address
# Send test email to old primary address (should still work)
```

---

## Getting Help

If your issue isn't listed here:

1. **Check Exchange Online Service Health:**
   - Go to [Microsoft 365 Admin Center](https://admin.microsoft.com)
   - Navigate to **Health** → **Service health**
   - Check for Exchange Online issues

2. **Enable Verbose Logging:**
   ```powershell
   $VerbosePreference = "Continue"
   .\SafePrimaryEmailChanger.ps1 -UserUPN "user@domain.com" -NewPrimaryEmail "user@newdomain.com" -Verbose
   ```

3. **Check Exchange Online Logs:**
   ```powershell
   # Get recent mailbox changes
   Search-AdminAuditLog -Cmdlets Set-Mailbox -StartDate (Get-Date).AddHours(-24)
   ```

4. **Open GitHub Issue:**
   - Go to [GitHub Issues](https://github.com/yourusername/m365-email-migration-tool/issues)
   - Provide error message, PowerShell version, and steps to reproduce

5. **Microsoft Support:**
   - For Exchange Online issues: [Microsoft Support](https://support.microsoft.com)
   - For module issues: [PowerShell Gallery](https://www.powershellgallery.com/packages/ExchangeOnlineManagement)

---

## Diagnostic Script

Run this to collect diagnostic information:

```powershell
Write-Host "`n=== Diagnostic Information ===" -ForegroundColor Cyan

# PowerShell version
Write-Host "`nPowerShell Version:" -ForegroundColor Yellow
$PSVersionTable.PSVersion

# Module version
Write-Host "`nExchange Module:" -ForegroundColor Yellow
Get-Module ExchangeOnlineManagement -ListAvailable | Select-Object Name, Version

# Connection status
Write-Host "`nConnection Status:" -ForegroundColor Yellow
try {
    $org = Get-OrganizationConfig -ErrorAction Stop
    Write-Host "✓ Connected to: $($org.Name)" -ForegroundColor Green
} catch {
    Write-Host "✗ Not connected" -ForegroundColor Red
}

# Current user
Write-Host "`nCurrent Admin:" -ForegroundColor Yellow
try {
    $admin = Get-ConnectionInformation | Select-Object -First 1
    Write-Host "User: $($admin.UserPrincipalName)" -ForegroundColor White
} catch {
    Write-Host "Cannot determine" -ForegroundColor Gray
}

# Execution policy
Write-Host "`nExecution Policy:" -ForegroundColor Yellow
Get-ExecutionPolicy -List

Write-Host "`n=== End Diagnostics ===" -ForegroundColor Cyan
```

---

**Still need help?** Open an issue on GitHub with the diagnostic output above.
