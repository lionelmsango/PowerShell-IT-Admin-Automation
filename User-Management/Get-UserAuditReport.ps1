<#
.SYNOPSIS
    Generates comprehensive user audit report for TechSolutions GmbH
    
.DESCRIPTION
    Creates CSV reports of all users with department breakdown.
    No additional modules required.
    
.EXAMPLE
    .\Get-UserAuditReport.ps1
    
.NOTES
    Author: Lionel Sango
    Created: 2026-03-24
    Version: 1.0 - CSV Edition
#>

$ErrorActionPreference = "Stop"

try {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "  GENERATING USER AUDIT REPORT" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan
    
    Write-Host "Collecting user data from Active Directory..." -ForegroundColor Yellow
    
    # Get all users in TechSolutions OU
    $DomainDN = (Get-ADDomain).DistinguishedName
    $SearchBase = "OU=TechSolutions,$DomainDN"
    
    $Users = Get-ADUser -Filter * -SearchBase $SearchBase -Properties `
        Department, Title, EmailAddress, Enabled, LastLogonDate, Created, MemberOf |
        Select-Object @{Name='Name';Expression={$_.Name}},
                     @{Name='Username';Expression={$_.SamAccountName}},
                     @{Name='Email';Expression={$_.EmailAddress}},
                     @{Name='Department';Expression={$_.Department}},
                     @{Name='JobTitle';Expression={$_.Title}},
                     @{Name='Status';Expression={if($_.Enabled){'Enabled'}else{'Disabled'}}},
                     @{Name='Created';Expression={$_.Created.ToString('yyyy-MM-dd')}},
                     @{Name='LastLogon';Expression={if($_.LastLogonDate){$_.LastLogonDate.ToString('yyyy-MM-dd')}else{'Never'}}},
                     @{Name='GroupCount';Expression={($_.MemberOf | Measure-Object).Count}}
    
    $TotalUsers = ($Users | Measure-Object).Count
    $EnabledUsers = ($Users | Where-Object {$_.Status -eq 'Enabled'} | Measure-Object).Count
    $DisabledUsers = ($Users | Where-Object {$_.Status -eq 'Disabled'} | Measure-Object).Count
    
    Write-Host "Found $TotalUsers users" -ForegroundColor Green
    
    # Department breakdown
    $DeptStats = $Users | Group-Object Department | 
                 Select-Object @{Name='Department';Expression={$_.Name}}, 
                              @{Name='UserCount';Expression={$_.Count}} |
                 Sort-Object Department
    
    # Generate CSV report
    $ReportPath = "C:\IT-Automation\Logs\UserAuditReport-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
    
    Write-Host "Creating CSV report..." -ForegroundColor Yellow
    
    # Export to CSV
    $Users | Export-Csv -Path $ReportPath -NoTypeInformation
    
    # Create summary file
    $SummaryPath = "C:\IT-Automation\Logs\UserAuditSummary-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
    $SummaryContent = @"
========================================
    USER AUDIT REPORT SUMMARY
========================================
Report Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

Total Users:       $TotalUsers
Enabled Accounts:  $EnabledUsers
Disabled Accounts: $DisabledUsers

Department Breakdown:
$($DeptStats | Format-Table -AutoSize | Out-String)

Main Report: $ReportPath
========================================
"@
    
    $SummaryContent | Out-File -FilePath $SummaryPath
    
    # Console output
    Write-Host "`n========================================" -ForegroundColor Green
    Write-Host "       USER AUDIT REPORT SUMMARY" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Total Users:       $TotalUsers" -ForegroundColor White
    Write-Host "Enabled Accounts:  " -NoNewline -ForegroundColor White
    Write-Host "$EnabledUsers" -ForegroundColor Green
    Write-Host "Disabled Accounts: " -NoNewline -ForegroundColor White
    Write-Host "$DisabledUsers" -ForegroundColor Yellow
    Write-Host "`nDepartment Breakdown:" -ForegroundColor Cyan
    $DeptStats | Format-Table -AutoSize
    
    Write-Host "`n✓ CSV Report saved: $ReportPath" -ForegroundColor Green
    Write-Host "✓ Summary saved: $SummaryPath" -ForegroundColor Green
    Write-Host "`nOpening report..." -ForegroundColor Yellow
    
    # Open CSV in default program (usually Excel)
    Start-Process $ReportPath
    
} catch {
    Write-Host "`nERROR: $($_.Exception.Message)" -ForegroundColor Red
    throw
}