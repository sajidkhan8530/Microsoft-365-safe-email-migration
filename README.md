# 🔄 Microsoft 365 Email Migration Tool

A PowerShell automation tool for safely changing primary email addresses in Microsoft 365 while preserving UserPrincipalName (UPN) and all existing aliases. Perfect for company rebranding, domain migrations, and organizational restructuring.

![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Exchange Online](https://img.shields.io/badge/Exchange-Online-orange)

---

## 📋 Table of Contents

- [Problem Statement](#problem-statement)
- [Solution](#solution)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)
- [Examples](#examples)
- [How It Works](#how-it-works)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)
- [Contributing](#contributing)
- [License](#license)

---

## ❗ Problem Statement

When changing a user's primary email address through the **Microsoft 365 Admin Center**, the system automatically updates both the primary email **AND** the UserPrincipalName (UPN). This causes several critical issues:

### Issues with Default UI Method:

- ❌ **Breaks OneDrive Access**: OneDrive URLs contain the UPN (e.g., `username@domain-my.sharepoint.com`)
- ❌ **SharePoint Links Fail**: All SharePoint personal site URLs become invalid
- ❌ **User Re-authentication Required**: Users must sign in again with new credentials
- ❌ **Loses Email Aliases**: Existing aliases may not be properly preserved
- ❌ **Service Disruption**: Interrupts workflow and causes user confusion

### Real-World Scenario:
During our company rebranding from `chronica.care` to `hifinite.com`, we needed to update 100+ user email addresses without disrupting their access to OneDrive, SharePoint, or requiring password resets.

---

## ✅ Solution

This PowerShell script safely changes the primary email address while:

- ✔️ **Preserving the UPN**: Keeps username unchanged (e.g., `user@chronica.care` remains as login)
- ✔️ **Maintaining All Aliases**: All existing email aliases are preserved
- ✔️ **Adding Old Primary as Alias**: Users continue receiving emails at their old address
- ✔️ **Zero Downtime**: No service interruption or re-authentication needed
- ✔️ **Comprehensive Validation**: Built-in checks ensure safe migration

---

## 🚀 Features

| Feature | Description |
|---------|-------------|
| **Safe Migration** | Changes primary email without affecting UPN |
| **Alias Preservation** | Automatically preserves all existing email aliases |
| **Old Email Retention** | Adds previous primary email as an alias |
| **Interactive Mode** | Prompts for input when run without parameters |
| **Batch Support** | Can be integrated into bulk migration scripts |
| **Validation Checks** | Pre-flight and post-flight validation |
| **Error Handling** | Comprehensive error messages and rollback capability |
| **Color-Coded Output** | Easy-to-read status messages |
| **Connection Verification** | Ensures Exchange Online connection before execution |

---

## 📦 Prerequisites

### Required Software:
- **Windows PowerShell 5.1+** or **PowerShell 7+**
- **ExchangeOnlineManagement Module**
- **Microsoft 365 Admin Account** with Exchange Administrator role

### Required Permissions:
- Exchange Administrator
- Global Administrator (recommended for full access)

### Platform Support:
- ✅ Windows 10/11
- ✅ Windows Server 2016+
- ✅ macOS (with PowerShell 7)
- ✅ Linux (with PowerShell 7)

---

## 🔧 Installation

### Step 1: Install PowerShell (if needed)

#### On Windows:
PowerShell 5.1 is pre-installed. For PowerShell 7:
```powershell
winget install Microsoft.PowerShell
```

#### On macOS:
```bash
brew install --cask powershell
```

#### On Linux:
```bash
# Ubuntu/Debian
sudo apt-get install -y powershell

# CentOS/RHEL
sudo yum install -y powershell
```

### Step 2: Install Exchange Online Management Module

Open PowerShell and run:

```powershell
# Install the module
Install-Module -Name ExchangeOnlineManagement -Scope CurrentUser -Force

# Import the module
Import-Module ExchangeOnlineManagement

# Verify installation
Get-Module -ListAvailable ExchangeOnlineManagement
```

### Step 3: Connect to Exchange Online

```powershell
Connect-ExchangeOnline
```

You'll be prompted to sign in with your Microsoft 365 admin credentials.

### Step 4: Download the Script

```powershell
# Clone the repository
git clone https://github.com/sajidkhan8530/m365-email-migration-tool.git
cd m365-email-migration-tool
```

Or download `SafePrimaryEmailChanger.ps1` directly from the repository.

---

## 💻 Usage

### Interactive Mode (Recommended for Single Users)

```powershell
.\SafePrimaryEmailChanger.ps1
```

You'll be prompted to enter:
1. **User UPN** (current login): `john.doe@oldomain.com`
2. **New Primary Email**: `john.doe@newdomain.com`

### Parameter Mode (For Automation)

```powershell
.\SafePrimaryEmailChanger.ps1 -UserUPN "john.doe@chronica.care" -NewPrimaryEmail "john.doe@hifinite.com"
```

### Batch Processing Multiple Users

Create a CSV file `users.csv`:
```csv
UserUPN,NewPrimaryEmail
john.doe@chronica.care,john.doe@hifinite.com
jane.smith@chronica.care,jane.smith@hifinite.com
bob.jones@chronica.care,bob.jones@hifinite.com
```

Then run:
```powershell
Import-Csv users.csv | ForEach-Object {
    .\SafePrimaryEmailChanger.ps1 -UserUPN $_.UserUPN -NewPrimaryEmail $_.NewPrimaryEmail
    Start-Sleep -Seconds 5
}
```

---

## 📊 Examples

### Example 1: Single User Migration

**Before:**
```
Username (UPN): baba@chronica.care
Primary Email: baba@chronica.care
Aliases: xyz@hifinite.com, testuser@chronica.care
```

**Command:**
```powershell
PS C:\> .\SafePrimaryEmailChanger.ps1
=== Safe primary email change ===
Enter user UPN (login, e.g. user@chronica.care): baba@chronica.care
Enter NEW primary email (e.g. user@hifinite.com): abc@chronica.care
```

**Output:**
```
╔═══════════════════════════════════════════════════════════╗
║   Safe Primary Email Changer for Microsoft 365           ║
║   Preserves UPN & Aliases During Email Migration         ║
╚═══════════════════════════════════════════════════════════╝

✓ Connected to Exchange Online

[Step 1/5] Retrieving mailbox information...
  Original UPN           : baba@chronica.care
  Original Primary SMTP  : baba@chronica.care
  Original Alias Count   : 8

[Step 2/5] Analyzing existing aliases...
  Found 7 existing aliases to preserve

[Step 3/5] Setting new primary SMTP to abc@chronica.care ...

[Step 4/5] Verifying changes...
  UPN unchanged          : True
  Primary email updated  : True

[Step 5/5] Ensuring all aliases are preserved...
  ✓ Alias exists: xyz@hifinite.com
  ✓ Alias exists: testuser@chronica.care
  ✓ Alias exists: testnew1@hifinite.com
  ✓ Alias exists: test.new@chronica.care
  ✓ Old primary preserved: baba@chronica.care

╔═══════════════════════════════════════════════════════════╗
║                   FINAL VALIDATION                        ║
╚═══════════════════════════════════════════════════════════╝

  UPN preserved          : True
  Primary email set      : True
  Original alias count   : 8
  Final alias count      : 8
  Aliases added/preserved: True

✅ Successfully completed email migration for: baba@chronica.care
   Old primary: baba@chronica.care
   New primary: abc@chronica.care
```

**After:**
```
Username (UPN): baba@chronica.care ← UNCHANGED
Primary Email: abc@chronica.care ← UPDATED
Aliases: baba@chronica.care, xyz@hifinite.com, testuser@chronica.care ← ALL PRESERVED
```

### Example 2: Real Company Rebranding

Our company migrated from `chronica.care` to `hifinite.com`:

```powershell
# User keeps their UPN for login
.\SafePrimaryEmailChanger.ps1 `
    -UserUPN "admin@chronica.care" `
    -NewPrimaryEmail "admin@hifinite.com"
```

**Result:**
- ✅ User still logs in with `admin@chronica.care`
- ✅ New emails sent from `admin@hifinite.com`
- ✅ Emails to `admin@chronica.care` still arrive
- ✅ OneDrive URL unchanged: `https://company-my.sharepoint.com/personal/admin_chronica_care`

---

## 🔍 How It Works

### Technical Flow:

1. **Connection Verification**
   - Checks active Exchange Online session
   - Validates admin permissions

2. **Mailbox Analysis**
   - Retrieves current UPN
   - Captures primary email address
   - Inventories all existing aliases

3. **Safe Primary Update**
   - Sets new primary email via `Set-Mailbox`
   - Uses `-EmailAddressPolicyEnabled $false` to prevent UPN change
   - Validates primary email updated successfully

4. **Alias Preservation**
   - Compares pre/post alias lists
   - Adds any missing aliases back
   - Ensures old primary becomes an alias

5. **Validation & Reporting**
   - Confirms UPN unchanged
   - Verifies new primary set correctly
   - Ensures all aliases present

### Key PowerShell Commands Used:

```powershell
# Get mailbox details
Get-Mailbox -Identity $UserUPN

# Set new primary without changing UPN
Set-Mailbox -Identity $UserUPN `
            -PrimarySmtpAddress $NewPrimaryEmail `
            -EmailAddressPolicyEnabled $false

# Add missing aliases
Set-Mailbox -Identity $UserUPN `
            -EmailAddresses @{Add=$addressesToAdd}
```

---

## 🛠️ Troubleshooting

### Issue 1: "Not connected to Exchange Online"

**Solution:**
```powershell
Connect-ExchangeOnline
```

### Issue 2: "Access Denied" or Permission Errors

**Solution:**
Ensure your admin account has **Exchange Administrator** role:
1. Go to Microsoft 365 Admin Center
2. Navigate to **Users** → **Active users**
3. Select your admin account
4. Assign **Exchange Administrator** role

### Issue 3: Module Not Found

**Solution:**
```powershell
Install-Module -Name ExchangeOnlineManagement -Scope CurrentUser -Force
Import-Module ExchangeOnlineManagement
```

### Issue 4: Execution Policy Error

**Solution:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Issue 5: On macOS/Linux - Module Installation Fails

**Solution:**
```bash
# Install PowerShell 7 first
pwsh

# Then install module
Install-Module -Name ExchangeOnlineManagement -Scope CurrentUser -Force
```

For more issues, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

---

## 📝 Best Practices

### Before Running:

1. ✅ **Test on a single user first**
2. ✅ **Backup user list and current settings**
3. ✅ **Verify Exchange Online connection**
4. ✅ **Notify users about email changes**
5. ✅ **Run during low-activity hours**

### During Migration:

1. ✅ **Process users in batches**
2. ✅ **Add delays between batches** (`Start-Sleep -Seconds 5`)
3. ✅ **Monitor for errors**
4. ✅ **Keep log of processed users**

### After Migration:

1. ✅ **Verify user can send/receive emails**
2. ✅ **Confirm OneDrive access works**
3. ✅ **Test old email alias receives emails**
4. ✅ **Update email signatures**
5. ✅ **Update distribution lists**

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- Microsoft Exchange Online team for the PowerShell module
- Our IT team for successful company-wide rebranding
- Community contributors and testers

---

## 📧 Contact & Support

- **Issues**: [GitHub Issues](https://github.com/sajidkhan8530/m365-email-migration-tool/issues)
- **Discussions**: [GitHub Discussions](https://github.com/sajidkhan8530/m365-email-migration-tool/discussions)

---

## ⭐ Star This Repository

If this tool helped you with your Microsoft 365 email migration, please give it a star! ⭐

---

**Made with ❤️ for IT Administrators**
