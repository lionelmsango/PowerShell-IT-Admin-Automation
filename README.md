# PowerShell IT Administration Automation

> Practical user and group management automation for Active Directory environments

## Why I Built This

I got tired of manually creating users in Active Directory. After clicking through the same menus repeatedly during my lab work, I thought: *"This is exactly what a real IT admin would automate."*

So I built this — not as an academic exercise, but as the toolkit I'd want on day one in an IT department.

## The Problem This Solves

Manual user management for even a medium-sized company:
- **10-15 minutes** per new employee (creating account, adding to groups, documenting)
- **Error-prone** (easy to forget a step or group)
- **Inconsistent** documentation

**With automation:**
- **30 seconds** per employee
- **Zero errors** (consistent execution every time)
- **Automatic** documentation and logging

## What's Inside

**5 PowerShell scripts for user and group lifecycle management:**

### User Management
- **`New-CompanyUser.ps1`** - Automated employee onboarding
- **`Remove-CompanyUser.ps1`** - Secure offboarding (disables, doesn't delete)
- **`Get-UserAuditReport.ps1`** - CSV reports for audits

### Group Management
- **`Add-UsersToGroups.ps1`** - CSV-driven bulk group operations
- **`Get-GroupMembershipReport.ps1`** - Complete group membership audit

## The Scenario

**TechSolutions GmbH** - fictional but realistic German SME:
- 25 employees across 4 departments
- Departments: Geschäftsführung, IT-Abteilung, Vertrieb, Marketing
- Active Directory environment
- Weekly onboarding/offboarding needs

## Technical Approach

**What makes this different:**

Most PowerShell tutorials show basic commands with no error handling or logging.

**This project:**
- ✅ Production-quality error handling (try/catch blocks)
- ✅ Comprehensive logging to files (audit trail)
- ✅ CSV-based reporting (works without additional modules)
- ✅ Bulk operations via CSV (scalability)
- ✅ Formatted, readable console output

### What I Learned

**Technical:**
- Error handling isn't optional in production
- Logging makes troubleshooting actually possible
- German companies take OU structure seriously
- Never delete accounts immediately (compliance)

**Practical:**
- Group naming conventions matter (`GRP-Department`)
- Documentation saves more time than writing the script
- CSV is universally compatible (no module dependencies)

## Quick Start

### Prerequisites
```powershell
# Active Directory module (built into Windows Server)
Import-Module ActiveDirectory
```

### Usage Examples

**Onboard a new employee:**
```powershell
.\New-CompanyUser.ps1 -FirstName "Hans" -LastName "Becker" `
                      -Department "IT-Abteilung" -JobTitle "System Administrator"
```

**Generate audit report:**
```powershell
.\Get-UserAuditReport.ps1
# Creates CSV report with all users
```

**Bulk group operations:**
```powershell
.\Add-UsersToGroups.ps1 -CSVPath ".\Templates\BulkGroupAdd.csv"
```

## 📸 Project Screenshots

### Automated User Onboarding
![User Onboarding](docs/onboarding-demo.png)
*Script execution showing automated employee onboarding with colored output and success messages*

### Professional Onboarding Report
![Onboarding Report](docs/onboarding-report.png)
*Automatically generated onboarding summary with credentials and next steps*

### CSV-Based Audit Reports
![CSV Report](docs/csv-report.png)
*User inventory report exported to CSV format - opens in Excel or any spreadsheet application*

### Bulk Group Operations
![Bulk Operations](docs/bulk-operations.png)
*CSV-driven bulk group membership assignment - scalability in action*

### Complete User Lifecycle Demo
![Complete Workflow](docs/complete-workflow.png)
*End-to-end demonstration: user creation, reporting, and offboarding in a single session*

## Project Structure

## Real-World Impact

**From my testing:**
- Manual user creation: ~10 minutes
- Automated: 30 seconds
- **Time savings: 95%**

**Accuracy:**
- Manual: Forgot group membership 30% of the time
- Automated: 0% error rate

**Compliance:**
- All actions logged automatically
- Audit-ready from day one

## Built With

- Windows Server 2022
- Active Directory Domain Services
- PowerShell 5.1
- PowerShell ISE
- Built-in modules only (no dependencies)

## Why This Matters

**If you're hiring:**  
This shows I can write production-quality automation, not just lab demos.

**If you're learning PowerShell:**  
Use this as a template for structuring real deployment scripts.

**If you're an IT admin:**  
Steal whatever's useful. Built to solve real problems.

## Author

**Lionel Sango**  
*Building IT infrastructure and automation skills through hands-on projects*

- GitHub: [@lionelmsango](https://github.com/lionelmsango)
- LinkedIn: [lionel-sango](https://www.linkedin.com/in/lionel-sango-417681273/)
- Location: Köln, Germany

Currently transitioning into IT administration and cybersecurity roles. This project demonstrates automation, scripting, and system administration capabilities.

## License

MIT License - Use it, modify it, share it.

---

**Project Status:** ✅ Complete and tested  
**Environment:** Windows Server 2022 + Active Directory  
**No Dependencies:** Uses built-in PowerShell modules only  
**Code Quality:** Production-ready with error handling and logging

*"The best IT admins automate everything so they can focus on interesting problems."*