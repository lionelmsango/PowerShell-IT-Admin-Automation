<#
.SYNOPSIS
    Generates group membership audit report
    
.DESCRIPTION
    Creates CSV report of all security groups and their members.
    No additional modules required.
    
.EXAMPLE
    .\Get-GroupMembershipReport.ps1
    
.NOTES
    Author: Lionel Sango
    Created: 2026-03-24
    Version: 1.0 - CSV Edition
#>

$ErrorActionPreference = "Stop"

try {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "  GENERATING GROUP MEMBERSHIP REPORT" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan
    
    Write-Host "Collecting group data from Active Directory..." -ForegroundColor Yellow
    
    # Get all groups in Groups OU
    $DomainDN = (Get-ADDomain).DistinguishedName
    $GroupsOU = "OU=Groups,OU=TechSolutions,$DomainDN"
    
    $Groups = Get-ADGroup -Filter * -SearchBase $GroupsOU -Properties Members, Description
    
    Write-Host "Found $($Groups.Count) groups" -ForegroundColor Green
    Write-Host "Processing group memberships..." -ForegroundColor Yellow
    
    # Build report data
    $ReportData = @()
    
    foreach ($Group in $Groups) {
        $Members = Get-ADGroupMember -Identity $Group -ErrorAction SilentlyContinue
        $MemberCount = ($Members | Measure-Object).Count
        
        if ($MemberCount -gt 0) {
            foreach ($Member in $Members) {
                $UserInfo = Get-ADUser -Identity $Member -Properties Department, Title -ErrorAction SilentlyContinue
                
                $ReportData += [PSCustomObject]@{
                    'GroupName' = $Group.Name
                    'GroupDescription' = $Group.Description
                    'MemberUsername' = $Member.SamAccountName
                    'MemberName' = $UserInfo.Name
                    'Department' = $UserInfo.Department
                    'JobTitle' = $UserInfo.Title
                }
            }
        } else {
            # Empty group
            $ReportData += [PSCustomObject]@{
                'GroupName' = $Group.Name
                'GroupDescription' = $Group.Description
                'MemberUsername' = '(No members)'
                'MemberName' = ''
                'Department' = ''
                'JobTitle' = ''
            }
        }
    }
    
    # Group summary
    $GroupSummary = $Groups | Select-Object @{Name='GroupName';Expression={$_.Name}}, 
                                            @{Name='Description';Expression={$_.Description}}, `
                                            @{Name='MemberCount';Expression={(Get-ADGroupMember -Identity $_ -ErrorAction SilentlyContinue).Count}}
    
    # Generate CSV report
    $ReportPath = "C:\IT-Automation\Logs\GroupMembershipReport-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
    
    Write-Host "Creating CSV report..." -ForegroundColor Yellow
    
    $ReportData | Export-Csv -Path $ReportPath -NoTypeInformation
    
    # Console output
    Write-Host "`n========================================" -ForegroundColor Green
    Write-Host "  GROUP MEMBERSHIP REPORT SUMMARY" -ForegroundColor Green
    Write-Host "========================================`n" -ForegroundColor Green
    
    $GroupSummary | Format-Table -AutoSize
    
    Write-Host "`n✓ Report saved: $ReportPath" -ForegroundColor Green
    Write-Host "Opening report...`n" -ForegroundColor Yellow
    
    Start-Process $ReportPath
    
} catch {
    Write-Host "`nERROR: $($_.Exception.Message)" -ForegroundColor Red
    throw
}