# Microsoft 365 Safe Email Migration

## Overview
PowerShell automation to safely change users' primary email addresses in Microsoft 365 / Exchange Online **without** changing their UPN, so OneDrive, SharePoint, Teams and existing links continue working during a company rebranding.

## Problem
- Changing primary email from the Microsoft 365 admin UI also changes the UPN.
- UPN is embedded in OneDrive and SharePoint URLs.
- If UPN changes:
  - Users lose access to OneDrive links.
  - Existing document links and shares break.
  - Manual fix is slow and risky for many users.

## Solution
This project contains a PowerShell script that:
- Keeps the UPN unchanged while switching the primary SMTP address.
- Preserves all existing aliases.
- Adds the *old* primary email as an alias so old addresses still receive mail.
- Performs validation before and after the change.
- Can be used interactively, per user.

## Features
- Safe per‑user migration of primary email.
- UPN preservation (no broken OneDrive/SharePoint URLs).
- Automatic handling of aliases (no loss).
- Clear console output with validation checks.
- Works with Exchange Online / Microsoft 365.

## Prerequisites
- Exchange Online tenant (Microsoft 365).
- Account with Exchange Admin (or higher) rights.
- PowerShell 5.1+ (Windows) or PowerShell 7+ (cross‑platform).
- Exchange Online PowerShell module:
