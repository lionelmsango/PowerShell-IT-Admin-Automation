<#
.SYNOPSIS
    Securely offboards employees from TechSolutions GmbH
    
.DESCRIPTION
    Disables AD account, removes from all groups, documents memberships.
    Does NOT delete the account (data retention compliance).
    
.PARAMETER Username
    The SamAccountName of the user to offboard
    
.EXAMPLE
    .\Remove-CompanyUser.ps1 -Username "hbecker"
    
.NOTES
    Author: Lionel Sango
    Created: 2026-03-24
    Version: 1.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$Username
)

$ErrorActionPreference = "Stop"

# Logging
$LogPath = "C:\IT-Automation\Logs\UserOffboarding-$(Get-Date -Format 'yyyy-MM-dd').log"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "$Timestamp [$Level] - $Message"
    Add-Content -Path $LogPath -Value $LogEntry
    
    switch ($Level) {
        "ERROR"   { Write-Host $Message -ForegroundColor Red }
        "SUCCESS" { Write-Host $Message -ForegroundColor Green }
        "WARNING" { Write-Host $Message -ForegroundColor Yellow }
        default   { Write-Host $Message }
    }
}

try {
    Write-Log "========================================" "INFO"
    Write-Log "Starting offboarding process for $Username" "INFO"
    Write-Log "========================================" "INFO"
    
    # Get user object
    $User = Get-ADUser -Identity $Username -Properties MemberOf, DisplayName, Department, Title, EmailAddress
    
    if (!$User) {
        throw "User '$Username' not found!"
    }
    
    Write-Log "Found user: $($User.DisplayName) ($($User.EmailAddress))" "INFO"
    
    # Document current group memberships
    Write-Log "Documenting current group memberships..." "INFO"
    $Groups = $User.MemberOf | ForEach-Object {
        (Get-ADGroup $_).Name
    }
    
    $GroupCount = ($Groups | Measure-Object).Count
    Write-Log "User is member of $GroupCount groups" "INFO"
    
    # Remove from all groups except Domain Users
    Write-Log "Removing user from security groups..." "INFO"
    foreach ($GroupDN in $User.MemberOf) {
        $GroupName = (Get-ADGroup $GroupDN).Name
        if ($GroupName -ne "Domain Users") {
            Remove-ADGroupMember -Identity $GroupDN -Members $Username -Confirm:$false
            Write-Log "Removed from: $GroupName" "INFO"
        }
    }
    
    # Disable account
    Write-Log "Disabling user account..." "INFO"
    Disable-ADAccount -Identity $Username
    
    # Update description with offboarding date
    Set-ADUser -Identity $Username -Description "Offboarded: $(Get-Date -Format 'yyyy-MM-dd')"
    
    Write-Log "Account disabled successfully" "SUCCESS"
    
    # Create offboarding report
    $Report = @"

========================================
    EMPLOYEE OFFBOARDING SUMMARY
========================================

Employee Information:
  Name:           $($User.DisplayName)
  Username:       $Username
  Email:          $($User.EmailAddress)
  Department:     $($User.Department)
  Job Title:      $($User.Title)
  
Offboarding Actions Completed:
  ✓ Account disabled
  ✓ Removed from $GroupCount security groups
  ✓ Group memberships documented
  ✓ Description updated with offboarding date
  
Previous Group Memberships:
$($Groups | ForEach-Object { "  - $_" } | Out-String)
  
Offboarded: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

========================================
NEXT STEPS:
========================================
  1. Archive user's home folder and mailbox
  2. Redirect emails to manager (if needed)
  3. Convert mailbox to shared (M365)
  4. Keep account for 90 days before deletion
========================================
"@
    
    Write-Host $Report -ForegroundColor Cyan
    Write-Log "Offboarding completed successfully" "SUCCESS"
    
    # Save report
    $ReportPath = "C:\IT-Automation\Logs\Offboarding-$Username-$(Get-Date -Format 'yyyyMMdd').txt"
    $Report | Out-File -FilePath $ReportPath
    Write-Log "Offboarding report saved: $ReportPath" "INFO"
    
} catch {
    Write-Log "ERROR: $($_.Exception.Message)" "ERROR"
    throw
}