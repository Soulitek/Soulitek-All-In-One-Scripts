# Contributing to Soulitek-All-In-One-Scripts

First off, thank you for considering contributing to Soulitek-All-In-One-Scripts! It's people like you that make this toolkit a great resource for the IT community.

## 🎯 Code of Conduct

This project and everyone participating in it is governed by our commitment to:
- Be respectful and inclusive
- Accept constructive criticism gracefully
- Focus on what is best for the community
- Show empathy towards other community members

## 🤝 How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the existing issues to avoid duplicates. When you create a bug report, include as many details as possible:

**Bug Report Template:**
```markdown
**Describe the bug**
A clear and concise description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Run script '...'
2. Select option '...'
3. See error

**Expected behavior**
What you expected to happen.

**Screenshots/Logs**
If applicable, add screenshots or log files.

**Environment:**
 - OS: [e.g., Windows 10 21H2]
 - PowerShell Version: [e.g., 5.1]
 - Script Version: [e.g., 1.0.0]
 - Admin privileges: [Yes/No]

**Additional context**
Any other context about the problem.
```

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, please include:

**Enhancement Template:**
```markdown
**Is your feature request related to a problem?**
A clear description of the problem.

**Describe the solution you'd like**
A clear description of what you want to happen.

**Describe alternatives you've considered**
Any alternative solutions or features you've considered.

**Use case**
Describe a specific scenario where this would be useful.

**Additional context**
Any other context, mockups, or screenshots.
```

### Pull Requests

1. **Fork the repository** and create your branch from `main`
2. **Follow the coding standards** (see below)
3. **Test your changes** on Windows 10/11
4. **Update documentation** if needed
5. **Write clear commit messages**
6. **Submit your pull request**

## 📝 Coding Standards

### PowerShell Best Practices

#### 1. Script Structure
```powershell
<#
.SYNOPSIS
    Brief description

.DESCRIPTION
    Detailed description

.PARAMETER ParamName
    Parameter description

.EXAMPLE
    Example usage

.NOTES
    Author, version, etc.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$RequiredParam
)

# Functions here
function Verb-Noun {
    [CmdletBinding()]
    param()
    
    # Implementation
}

# Main execution
```

#### 2. Naming Conventions
- **Functions:** Use approved PowerShell verbs (Get, Set, New, Remove, etc.)
- **Variables:** Use camelCase for local, PascalCase for script scope
- **Parameters:** Use PascalCase
- **Constants:** Use UPPER_CASE

```powershell
# Good
$script:LogFolder = "..."
$localVariable = "..."
[Parameter()]$InputPath

# Avoid
$log_folder = "..."
$LOCALVAR = "..."
```

#### 3. Error Handling
Always use try/catch for operations that might fail:

```powershell
try {
    $result = Get-SomeData -Path $Path -ErrorAction Stop
}
catch {
    Write-Error "Failed to get data: $_"
    Write-Log "Error details: $($_.Exception.Message)" -Level ERROR
    throw
}
finally {
    # Cleanup if needed
}
```

#### 4. Logging
Use the logging infrastructure:

```powershell
Write-Log "Starting operation" -Level INFO
Write-Verbose "Detailed step information"
Write-Warning "This might be a problem"
Write-Error "This is an error"
```

#### 5. Administrator Checks
For scripts requiring admin privileges:

```powershell
if (-not (Test-AdministratorPrivilege)) {
    Write-Host "This script requires Administrator privileges" -ForegroundColor Red
    Write-Host "Please run as Administrator" -ForegroundColor Yellow
    exit 1
}
```

#### 6. Comment-Based Help
Every function must have:

```powershell
<#
.SYNOPSIS
    Short description (one line)

.DESCRIPTION
    Longer description explaining what the function does
    and any important details

.PARAMETER ParamName
    What this parameter does

.EXAMPLE
    Verb-Noun -ParamName "Value"
    
    Description of what this example does

.OUTPUTS
    What type of object is returned

.NOTES
    Additional information, author, version
#>
```

#### 7. WhatIf/Confirm Support
For destructive operations:

```powershell
[CmdletBinding(SupportsShouldProcess = $true)]
param()

if ($PSCmdlet.ShouldProcess($Target, $Operation)) {
    # Perform action
}
```

### Code Style

#### Indentation
- Use 4 spaces (not tabs)
- Align opening and closing braces

```powershell
# Good
if ($condition) {
    # Code here
}

# Avoid
if ($condition) 
{
    # Code here
    }
```

#### Line Length
- Keep lines under 120 characters when possible
- Break long lines at logical points

```powershell
# Good
$result = Get-Item -Path $LongPath |
    Where-Object { $_.Length -gt 1MB } |
    Select-Object Name, Length

# Avoid
$result = Get-Item -Path $LongPath | Where-Object { $_.Length -gt 1MB } | Select-Object Name, Length, LastWriteTime, CreationTime, Extension
```

#### Comments
- Use comments to explain "why", not "what"
- Keep comments up-to-date with code
- Use inline comments sparingly

```powershell
# Good
# Check cache first to avoid expensive API call
$cached = Get-CachedData

# Avoid
# Get cached data
$cached = Get-CachedData
```

## 🧪 Testing Requirements

### Manual Testing Checklist
- [ ] Tested on Windows 10
- [ ] Tested on Windows 11
- [ ] Tested as Administrator
- [ ] Tested as regular user (should show appropriate error)
- [ ] Tested with invalid inputs
- [ ] Tested error handling
- [ ] Verified log files created correctly
- [ ] Verified exports work correctly

### Automated Testing (Pester)
If adding new functions, include Pester tests:

```powershell
Describe "Function-Name Tests" {
    Context "Parameter Validation" {
        It "Should accept valid input" {
            { Function-Name -Param "valid" } | Should -Not -Throw
        }
        
        It "Should reject invalid input" {
            { Function-Name -Param "" } | Should -Throw
        }
    }
    
    Context "Functionality" {
        It "Should return expected output" {
            $result = Function-Name -Param "test"
            $result | Should -BeOfType [PSCustomObject]
        }
    }
}
```

## 📚 Documentation

### Update README.md
If adding a new script or major feature:
1. Add to "Available Tools" section
2. Include usage examples
3. List key features
4. Note any prerequisites

### Update TODO.md
- Mark completed tasks
- Add new planned features
- Update status of in-progress items

### Inline Documentation
- Add XML-based help to all functions
- Include at least 2 examples per function
- Document all parameters

## 🔄 Git Workflow

### Branch Naming
- `feature/description` - New features
- `bugfix/description` - Bug fixes
- `hotfix/description` - Urgent fixes
- `docs/description` - Documentation updates

### Commit Messages
Follow conventional commits:

```
type(scope): subject

body

footer
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Formatting
- `refactor`: Code restructuring
- `test`: Adding tests
- `chore`: Maintenance

Examples:
```
feat(battery): Add battery wear level alerts

Implemented new feature to alert users when battery wear
exceeds 20%. Includes email notification option.

Closes #123
```

```
fix(pst): Correct deep scan progress calculation

Fixed issue where progress bar showed incorrect percentage
during deep scan of large drives.

Fixes #456
```

### Pull Request Process

1. **Update documentation** as needed
2. **Add yourself** to contributors in README
3. **Describe changes** thoroughly in PR description
4. **Link related issues**
5. **Request review** from maintainers
6. **Address feedback** promptly

**PR Template:**
```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Tested on Windows 10
- [ ] Tested on Windows 11
- [ ] All existing tests pass
- [ ] Added new tests

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-reviewed code
- [ ] Commented complex code
- [ ] Updated documentation
- [ ] No new warnings
- [ ] Added tests

## Related Issues
Closes #(issue number)
```

## 🎨 UI/UX Guidelines

### Console Output
- Use colors appropriately:
  - **Cyan**: Headers, informational
  - **Green**: Success messages
  - **Yellow**: Warnings
  - **Red**: Errors
  - **Gray**: Secondary information

- Include progress indicators for long operations
- Provide clear instructions for user actions
- Show helpful error messages with remediation steps

### Menu Design
```powershell
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  MENU TITLE" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Select an option:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  [1] Option 1 - Description" -ForegroundColor White
Write-Host "  [2] Option 2 - Description" -ForegroundColor White
Write-Host "  [0] Exit" -ForegroundColor White
Write-Host ""
```

## 🌍 Internationalization

When adding Hebrew translations:
- Keep English as primary
- Add Hebrew in comments or separate section
- Ensure RTL layout works correctly
- Test with Hebrew Windows locale

## 📦 Release Process

1. Update version numbers
2. Update CHANGELOG.md
3. Create release notes
4. Tag release in git
5. Create GitHub release
6. Update documentation

## 💬 Community

- Join discussions in GitHub Issues
- Share your use cases
- Help answer questions
- Promote the project

## 📞 Questions?

If you have questions about contributing:
- Open a GitHub Discussion
- Check existing Issues and Discussions
- Contact via email: contact@soulitek.co.il

## 🙏 Recognition

Contributors will be recognized in:
- README.md Contributors section
- Release notes
- Project website (if applicable)

---

**Thank you for contributing to Soulitek-All-In-One-Scripts!**

Together we're building better tools for the IT community.

---

*SouliTEK - IT Solutions for Your Business*  
*https://soulitek.co.il*

