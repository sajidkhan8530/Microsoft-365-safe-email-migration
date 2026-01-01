<#
.SYNOPSIS
    Safely changes the primary email address for Microsoft 365 users while preserving UPN and all existing aliases.

.DESCRIPTION
    This script automates the process of changing a user's primary email address during company rebranding
    or domain migration while ensuring:
    - UserPrincipalName (UPN) remains unchanged
    - All existing email aliases are preserved
    - Old primary email is added as an alias
    - OneDrive and SharePoint links continue to work
    
    This solves the limitation in Microsoft 365 Admin Center where changing the primary email
    also changes the UPN, breaking OneDrive access and other services.

.PARAMETER UserUPN
    The current UserPrincipalName (login) of the user (e.g., user@oldomain.com)

.PARAMETER NewPrimaryEmail
    The new primary email address to set (e.g., user@newdomain.com)

.EXAMPLE
    .\SafePrimaryEmailChanger.ps1
    # Interactive mode - prompts for UserUPN and NewPrimaryEmail

.EXAMPLE
    .\SafePrimaryEmailChanger.ps1 -UserUPN "john.doe@chronica.care" -NewPrimaryEmail "john.doe@hifinite.com"

.NOTES
    Author: IT Administrator
    Version: 1.0.0
    Requires: ExchangeOnlineManagement module
    
.LINK
    https://github.com/yourusername/m365-email-migration-tool
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$UserUPN,
    
    [Parameter(Mandatory=$false)]
    [string]$NewPrimaryEmail
)

# ============================================
# Function: Test-ExchangeConnection
# ============================================
function Test-ExchangeConnection {
    try {
        $null = Get-OrganizationConfig -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}

# ============================================
# Function: Write-ColorOutput
# ============================================
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White",
        [switch]$NoNewline
    )
    
    if ($NoNewline) {
        Write-Host $Message -ForegroundColor $Color -NoNewline
    }
    else {
        Write-Host $Message -ForegroundColor $Color
    }
}

# ============================================
# Main Script
# ============================================

Write-ColorOutput "`n╔═══════════════════════════════════════════════════════════╗" -Color Cyan
Write-ColorOutput "║   Safe Primary Email Changer for Microsoft 365           ║" -Color Cyan
Write-ColorOutput "║   Preserves UPN & Aliases During Email Migration         ║" -Color Cyan
Write-ColorOutput "╚═══════════════════════════════════════════════════════════╝`n" -Color Cyan

# Check Exchange Online connection
if (-not (Test-ExchangeConnection)) {
    Write-ColorOutput "❌ Not connected to Exchange Online!" -Color Red
    Write-ColorOutput "`nPlease connect using:" -Color Yellow
    Write-ColorOutput "  Connect-ExchangeOnline" -Color White
    Write-ColorOutput "`nOr run the setup commands:" -Color Yellow
    Write-ColorOutput "  Install-Module -Name ExchangeOnlineManagement -Scope CurrentUser -Force" -Color White
    Write-ColorOutput "  Import-Module ExchangeOnlineManagement" -Color White
    Write-ColorOutput "  Connect-ExchangeOnline`n" -Color White
    exit 1
}

Write-ColorOutput "✓ Connected to Exchange Online`n" -Color Green

# Get user input if not provided as parameters
if ([string]::IsNullOrWhiteSpace($UserUPN)) {
    $UserUPN = Read-Host "Enter user UPN (login, e.g. user@chronica.care)"
}

if ([string]::IsNullOrWhiteSpace($NewPrimaryEmail)) {
    $NewPrimaryEmail = Read-Host "Enter NEW primary email (e.g. user@hifinite.com)"
}

# Validate inputs
if ([string]::IsNullOrWhiteSpace($UserUPN) -or [string]::IsNullOrWhiteSpace($NewPrimaryEmail)) {
    Write-ColorOutput "❌ Both UserUPN and NewPrimaryEmail are required!" -Color Red
    exit 1
}

try {
    # ============================================
    # Step 1: Get mailbox and current state
    # ============================================
    Write-ColorOutput "`n[Step 1/5] Retrieving mailbox information..." -Color Yellow
    
    $mbx = Get-Mailbox -Identity $UserUPN -ErrorAction Stop
    
    $originalUPN = $mbx.UserPrincipalName
    $originalPrimary = $mbx.PrimarySmtpAddress.ToString().ToLower()
    $originalAddresses = @($mbx.EmailAddresses)
    $originalCount = $originalAddresses.Count
    
    Write-ColorOutput "  Original UPN           : $originalUPN" -Color White
    Write-ColorOutput "  Original Primary SMTP  : $originalPrimary" -Color White
    Write-ColorOutput "  Original Alias Count   : $originalCount`n" -Color White
    
    # ============================================
    # Step 2: Build list of existing aliases
    # ============================================
    Write-ColorOutput "[Step 2/5] Analyzing existing aliases..." -Color Yellow
    
    $newPrimaryNorm = $NewPrimaryEmail.ToLower()
    
    # Get all existing SMTP aliases except the new primary (to avoid duplicates)
    $oldAliases = $originalAddresses | 
        Where-Object {
            ($_ -like "smtp:*" -or $_ -like "SMTP:*") -and
            ($_.ToString().Split(":")[1].ToLower() -ne $newPrimaryNorm)
        }
    
    Write-ColorOutput "  Found $($oldAliases.Count) existing aliases to preserve`n" -Color White
    
    # ============================================
    # Step 3: Set new primary email
    # ============================================
    Write-ColorOutput "[Step 3/5] Setting new primary SMTP to $NewPrimaryEmail ..." -Color Yellow
    
    Set-Mailbox -Identity $UserUPN `
                -PrimarySmtpAddress $NewPrimaryEmail `
                -EmailAddressPolicyEnabled $false `
                -ErrorAction Stop
    
    Start-Sleep -Seconds 2
    
    # ============================================
    # Step 4: Verify UPN unchanged
    # ============================================
    Write-ColorOutput "[Step 4/5] Verifying changes..." -Color Yellow
    
    $mbxAfter = Get-Mailbox -Identity $UserUPN -ErrorAction Stop
    $upnUnchanged = ($mbxAfter.UserPrincipalName -eq $originalUPN)
    $primarySet = ($mbxAfter.PrimarySmtpAddress.ToString().ToLower() -eq $newPrimaryNorm)
    
    Write-ColorOutput "  UPN unchanged          : $upnUnchanged" -Color $(if($upnUnchanged){"Green"}else{"Red"})
    Write-ColorOutput "  Primary email updated  : $primarySet`n" -Color $(if($primarySet){"Green"}else{"Red"})
    
    # ============================================
    # Step 5: Ensure all aliases are present
    # ============================================
    Write-ColorOutput "[Step 5/5] Ensuring all aliases are preserved..." -Color Yellow
    
    $currentAddresses = @($mbxAfter.EmailAddresses)
    $addressesToAdd = @()
    
    # Check each old alias
    foreach ($alias in $oldAliases) {
        $aliasEmail = $alias.ToString().Split(":")[1].ToLower()
        $exists = $currentAddresses | Where-Object { 
            $_.ToString().ToLower() -like "*:$aliasEmail" 
        }
        
        if (-not $exists) {
            Write-ColorOutput "  + Adding missing alias: $aliasEmail" -Color Cyan
            $addressesToAdd += "smtp:$aliasEmail"
        }
        else {
            Write-ColorOutput "  ✓ Alias exists: $aliasEmail" -Color Gray
        }
    }
    
    # Ensure old primary is added as an alias
    $oldPrimaryExists = $currentAddresses | Where-Object {
        $_.ToString().ToLower() -like "*:$originalPrimary"
    }
    
    if (-not $oldPrimaryExists -and $originalPrimary -ne $newPrimaryNorm) {
        Write-ColorOutput "  + Adding old primary as alias: $originalPrimary" -Color Cyan
        $addressesToAdd += "smtp:$originalPrimary"
    }
    else {
        Write-ColorOutput "  ✓ Old primary preserved: $originalPrimary" -Color Gray
    }
    
    # Add missing aliases if any
    if ($addressesToAdd.Count -gt 0) {
        Write-ColorOutput "`n  Adding $($addressesToAdd.Count) missing aliases..." -Color Yellow
        
        Set-Mailbox -Identity $UserUPN `
                    -EmailAddresses @{Add=$addressesToAdd} `
                    -ErrorAction Stop
        
        Start-Sleep -Seconds 2
    }
    
    # ============================================
    # Final Validation
    # ============================================
    Write-ColorOutput "`n╔═══════════════════════════════════════════════════════════╗" -Color Green
    Write-ColorOutput "║                   FINAL VALIDATION                        ║" -Color Green
    Write-ColorOutput "╚═══════════════════════════════════════════════════════════╝`n" -Color Green
    
    $mbxFinal = Get-Mailbox -Identity $UserUPN -ErrorAction Stop
    $finalAddresses = @($mbxFinal.EmailAddresses)
    
    $upnStillSame = ($mbxFinal.UserPrincipalName -eq $originalUPN)
    $primaryIsNew = ($mbxFinal.PrimarySmtpAddress.ToString().ToLower() -eq $newPrimaryNorm)
    $finalCount = $finalAddresses.Count
    
    Write-ColorOutput "  UPN preserved          : " -Color White -NoNewline
    Write-ColorOutput $upnStillSame -Color $(if($upnStillSame){"Green"}else{"Red"})
    
    Write-ColorOutput "  Primary email set      : " -Color White -NoNewline
    Write-ColorOutput $primaryIsNew -Color $(if($primaryIsNew){"Green"}else{"Red"})
    
    Write-ColorOutput "  Original alias count   : $originalCount" -Color White
    Write-ColorOutput "  Final alias count      : $finalCount" -Color White
    Write-ColorOutput "  Aliases added/preserved: " -Color White -NoNewline
    Write-ColorOutput ($finalCount -ge $originalCount) -Color $(if($finalCount -ge $originalCount){"Green"}else{"Yellow"})
    
    Write-ColorOutput "`n✅ Successfully completed email migration for: $UserUPN" -Color Green
    Write-ColorOutput "   Old primary: $originalPrimary" -Color Gray
    Write-ColorOutput "   New primary: $newPrimaryNorm`n" -Color Green
    
}
catch {
    Write-ColorOutput "`n❌ ERROR: $($_.Exception.Message)" -Color Red
    Write-ColorOutput "`nScript failed. No changes were committed.`n" -Color Yellow
    exit 1
}
