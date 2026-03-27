<#
.SYNOPSIS
    Bulk adds users to AD groups from CSV file
    
.DESCRIPTION
    Reads CSV file with Username and GroupName columns and adds users to groups.
    Useful for role-based access management.
    
.PARAMETER CSVPath
    Path to CSV file containing Username and GroupName columns
    
.EXAMPLE
    .\Add-UsersToGroups.ps1 -CSVPath "C:\IT-Automation\Templates\BulkGroupAdd.csv"
    
.NOTES
    Author: Lionel Sango
    Created: 2026-03-24
    Version: 1.0
    
    CSV Format:
    Username,GroupName
    hbecker,GRP-IT-Team
    mmueller,GRP-Geschaeftsfuehrung
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$CSVPath
)

$ErrorActionPreference = "Stop"

# Logging
$LogPath = "C:\IT-Automation\Logs\GroupMembership-$(Get-Date -Format 'yyyy-MM-dd').log"

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
    Write-Log "Starting bulk group membership assignment" "INFO"
    Write-Log "========================================" "INFO"
    
    # Verify CSV exists
    if (!(Test-Path $CSVPath)) {
        throw "CSV file not found: $CSVPath"
    }
    
    Write-Log "CSV file found: $CSVPath" "INFO"
    
    # Import CSV
    $Data = Import-Csv -Path $CSVPath
    $TotalRows = ($Data | Measure-Object).Count
    Write-Log "Loaded $TotalRows entries from CSV" "INFO"
    
    Write-Host "`nProcessing entries...`n" -ForegroundColor Cyan
    
    # Process each row
    $SuccessCount = 0
    $SkipCount = 0
    $FailCount = 0
    
    foreach ($Row in $Data) {
        try {
            # Validate user exists
            $User = Get-ADUser -Identity $Row.Username -ErrorAction Stop
            
            # Validate group exists
            $Group = Get-ADGroup -Identity $Row.GroupName -ErrorAction Stop
            
            # Check if user is already a member
            $IsMember = Get-ADGroupMember -Identity $Row.GroupName -ErrorAction SilentlyContinue | 
                       Where-Object {$_.SamAccountName -eq $Row.Username}
            
            if ($IsMember) {
                Write-Log "SKIP: $($Row.Username) already in $($Row.GroupName)" "WARNING"
                $SkipCount++
            } else {
                # Add user to group
                Add-ADGroupMember -Identity $Row.GroupName -Members $Row.Username
                Write-Log "SUCCESS: Added $($Row.Username) to $($Row.GroupName)" "SUCCESS"
                $SuccessCount++
            }
            
        } catch {
            Write-Log "FAILED: $($Row.Username) -> $($Row.GroupName) | Error: $($_.Exception.Message)" "ERROR"
            $FailCount++
        }
    }
    
    # Summary
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "  BULK GROUP ASSIGNMENT SUMMARY" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Total Entries:  $TotalRows" -ForegroundColor White
    Write-Host "Successful:     " -NoNewline -ForegroundColor White
    Write-Host "$SuccessCount" -ForegroundColor Green
    Write-Host "Skipped:        " -NoNewline -ForegroundColor White
    Write-Host "$SkipCount" -ForegroundColor Yellow
    Write-Host "Failed:         " -NoNewline -ForegroundColor White
    Write-Host "$FailCount" -ForegroundColor Red
    Write-Host "`n✓ Process completed" -ForegroundColor Green
    Write-Log "Bulk assignment completed: $SuccessCount success, $SkipCount skipped, $FailCount failed" "INFO"
    
} catch {
    Write-Log "CRITICAL ERROR: $($_.Exception.Message)" "ERROR"
    throw
}