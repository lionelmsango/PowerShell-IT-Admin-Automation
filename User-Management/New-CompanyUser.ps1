<#
.SYNOPSIS
    Automates employee onboarding for TechSolutions GmbH
    
.DESCRIPTION
    Creates AD user account with proper OU placement, adds to security groups,
    and generates onboarding report.
    
.PARAMETER FirstName
    Employee's first name
    
.PARAMETER LastName
    Employee's last name
    
.PARAMETER Department
    Department name - must match existing OU
    Valid values: Geschaeftsfuehrung, IT-Abteilung, Vertrieb, Marketing
    
.PARAMETER JobTitle
    Employee's job title
    
.EXAMPLE
    .\New-CompanyUser.ps1 -FirstName "Hans" -LastName "Becker" -Department "IT-Abteilung" -JobTitle "System Administrator"
    
.NOTES
    Author: Lionel Sango
    Created: 2026-03-24
    Version: 1.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$FirstName,
    
    [Parameter(Mandatory=$true)]
    [string]$LastName,
    
    [Parameter(Mandatory=$true)]
    [ValidateSet("Geschaeftsfuehrung","IT-Abteilung","Vertrieb","Marketing")]
    [string]$Department,
    
    [Parameter(Mandatory=$true)]
    [string]$JobTitle
)

# Error handling
$ErrorActionPreference = "Stop"

# Logging function
$LogPath = "C:\IT-Automation\Logs\UserCreation-$(Get-Date -Format 'yyyy-MM-dd').log"

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

# Main script
try {
    Write-Log "========================================" "INFO"
    Write-Log "Starting user creation process" "INFO"
    Write-Log "User: $FirstName $LastName" "INFO"
    Write-Log "Department: $Department | Title: $JobTitle" "INFO"
    Write-Log "========================================" "INFO"
    
    # Get domain info
    $DomainDN = (Get-ADDomain).DistinguishedName
    $DomainDNS = (Get-ADDomain).DNSRoot
    
    # Generate username (first letter + last name, lowercase)
    $Username = ($FirstName.Substring(0,1) + $LastName).ToLower()
    $UPN = "$Username@$DomainDNS"
    
    # Check if user already exists
    if (Get-ADUser -Filter "SamAccountName -eq '$Username'" -ErrorAction SilentlyContinue) {
        throw "User '$Username' already exists!"
    }
    
    # Define OU path
    $OU = "OU=$Department,OU=TechSolutions,$DomainDN"
    
    # Generate secure random password
    Add-Type -AssemblyName 'System.Web'
    $TempPassword = [System.Web.Security.Membership]::GeneratePassword(12, 3)
    $SecurePassword = ConvertTo-SecureString $TempPassword -AsPlainText -Force
    
    Write-Log "Creating AD user account..." "INFO"
    
    # Create AD user
    New-ADUser -Name "$FirstName $LastName" `
               -GivenName $FirstName `
               -Surname $LastName `
               -SamAccountName $Username `
               -UserPrincipalName $UPN `
               -Department $Department `
               -Title $JobTitle `
               -EmailAddress $UPN `
               -Path $OU `
               -AccountPassword $SecurePassword `
               -Enabled $true `
               -ChangePasswordAtLogon $true `
               -Description "Created: $(Get-Date -Format 'yyyy-MM-dd')"
    
    Write-Log "AD user created: $Username" "SUCCESS"
    
    # Add to All-Staff group
    Write-Log "Adding user to security groups..." "INFO"
    Add-ADGroupMember -Identity "GRP-All-Staff" -Members $Username
    
    # Add to department-specific group
    $DeptGroupName = switch ($Department) {
        "Geschaeftsfuehrung" { "GRP-Geschaeftsfuehrung" }
        "IT-Abteilung"       { "GRP-IT-Team" }
        "Vertrieb"           { "GRP-Vertrieb" }
        "Marketing"          { "GRP-Marketing" }
    }
    
    Add-ADGroupMember -Identity $DeptGroupName -Members $Username
    Write-Log "Added to groups: GRP-All-Staff, $DeptGroupName" "SUCCESS"
    
    # Create summary report
    $Report = @"

========================================
    EMPLOYEE ONBOARDING SUMMARY
========================================

Employee Information:
  Name:           $FirstName $LastName
  Username:       $Username
  Email:          $UPN
  Department:     $Department
  Job Title:      $JobTitle
  
Account Details:
  Temporary Password:  $TempPassword
  Password Change Required: Yes (first login)
  Account Status:  Enabled
  
Group Memberships:
  - GRP-All-Staff
  - $DeptGroupName
  
OU Location:
  $OU
  
Created: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

========================================
NEXT STEPS:
========================================
  1. Send credentials to employee securely
  2. Create Microsoft 365 mailbox (if hybrid)
  3. Assign necessary software licenses
========================================
"@
    
    Write-Host $Report -ForegroundColor Cyan
    Write-Log "User creation completed successfully" "SUCCESS"
    
    # Save report to file
    $ReportPath = "C:\IT-Automation\Logs\Onboarding-$Username-$(Get-Date -Format 'yyyyMMdd').txt"
    $Report | Out-File -FilePath $ReportPath
    Write-Log "Onboarding report saved: $ReportPath" "INFO"
    
} catch {
    Write-Log "ERROR: $($_.Exception.Message)" "ERROR"
    Write-Log "User creation failed for $FirstName $LastName" "ERROR"
    throw
}