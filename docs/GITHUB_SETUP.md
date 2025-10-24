# 🚀 GitHub Setup Guide - Soulitek-All-In-One-Scripts

This guide will walk you through uploading this project to GitHub.

---

## ✅ Prerequisites

Before you begin, make sure you have:
- [x] Git installed and initialized (already done ✓)
- [ ] A GitHub account ([Sign up here](https://github.com/join))
- [ ] Git configured with your name and email

---

## 📋 Step-by-Step Instructions

### Step 1: Configure Git (if not already done)

Open PowerShell or Git Bash and run:

```bash
# Set your name
git config --global user.name "Your Name"

# Set your email (use your GitHub email)
git config --global user.email "your.email@example.com"

# Verify configuration
git config --list
```

---

### Step 2: Create a New Repository on GitHub

1. **Go to GitHub:** https://github.com
2. **Sign in** to your account
3. **Click the "+" icon** in the top-right corner
4. **Select "New repository"**

#### Repository Settings:

| Setting | Value |
|---------|-------|
| **Repository name** | `Soulitek-All-In-One-Scripts` |
| **Description** | Professional PowerShell Tools for IT Technicians & Helpdesk Engineers |
| **Visibility** | ⚪ Public *(or)* ⚪ Private |
| **Initialize** | ❌ Do NOT initialize with README (we already have one) |
| **Add .gitignore** | ❌ None (we already have one) |
| **Choose a license** | ❌ None (we already have LICENSE file) |

5. **Click "Create repository"**

---

### Step 3: Connect Local Repository to GitHub

After creating the repository, GitHub will show you instructions. Use these commands:

#### Option A: Using HTTPS (Recommended for beginners)

```bash
# Add GitHub as remote origin
git remote add origin https://github.com/YOUR_USERNAME/Soulitek-All-In-One-Scripts.git

# Verify remote was added
git remote -v

# Rename branch to 'main' (if needed)
git branch -M main

# Push your code to GitHub
git push -u origin main
```

**Replace `YOUR_USERNAME` with your actual GitHub username!**

#### Option B: Using SSH (More secure, requires SSH key setup)

First, set up SSH keys if you haven't:
1. Follow: https://docs.github.com/en/authentication/connecting-to-github-with-ssh

Then run:
```bash
# Add GitHub as remote origin (SSH)
git remote add origin git@github.com:YOUR_USERNAME/Soulitek-All-In-One-Scripts.git

# Verify remote was added
git remote -v

# Rename branch to 'main' (if needed)
git branch -M main

# Push your code to GitHub
git push -u origin main
```

---

### Step 4: Verify Upload

1. Go to your repository: `https://github.com/YOUR_USERNAME/Soulitek-All-In-One-Scripts`
2. You should see all your files including:
   - ✓ README.md
   - ✓ All PowerShell scripts
   - ✓ LICENSE
   - ✓ TODO.md

---

### Step 5: Configure Repository Settings (Optional but Recommended)

#### Add Topics/Tags:
1. Go to your repository on GitHub
2. Click the **⚙️ Settings** gear icon near "About"
3. Add topics: `powershell`, `windows`, `it-tools`, `helpdesk`, `system-administration`, `scripting`

#### Add Description:
In the "About" section, add:
- **Description:** Professional PowerShell Tools for IT Technicians & Helpdesk Engineers
- **Website:** https://soulitek.co.il

#### Enable Issues:
1. Go to **Settings** → **General**
2. Ensure "Issues" is checked under Features

#### Set Branch Protection (for collaboration):
1. Go to **Settings** → **Branches**
2. Add rule for `main` branch
3. Consider enabling:
   - Require pull request reviews
   - Require status checks to pass

---

## 🔄 Making Future Changes

After the initial push, use these commands for updates:

```bash
# Check what files have changed
git status

# Stage specific files
git add <filename>

# Or stage all changes
git add .

# Commit changes with a message
git commit -m "Description of what you changed"

# Push to GitHub
git push

# Pull latest changes from GitHub (if working from multiple computers)
git pull
```

---

## 📝 Commit Message Best Practices

Use clear, descriptive commit messages:

**Good examples:**
```
git commit -m "feat: Add network diagnostics tool"
git commit -m "fix: Correct battery report generation on desktops"
git commit -m "docs: Update README with new tool descriptions"
git commit -m "refactor: Improve error handling in PST Finder"
```

**Commit Types:**
- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation changes
- `style:` - Formatting, no code change
- `refactor:` - Code restructuring
- `test:` - Adding tests
- `chore:` - Maintenance tasks

---

## 🌟 Recommended Next Steps

### 1. Add a GitHub Actions Workflow (CI/CD)

Create `.github/workflows/powershell-test.yml`:

```yaml
name: PowerShell Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run PSScriptAnalyzer
        shell: pwsh
        run: |
          Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser
          Invoke-ScriptAnalyzer -Path . -Recurse
```

### 2. Create Issue Templates

Create `.github/ISSUE_TEMPLATE/bug_report.md`:

```markdown
---
name: Bug Report
about: Create a report to help us improve
title: '[BUG] '
labels: bug
assignees: ''
---

**Describe the bug**
A clear and concise description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Run script '...'
2. Click on '...'
3. See error

**Expected behavior**
What you expected to happen.

**Environment:**
 - OS: [e.g. Windows 10 21H2]
 - PowerShell Version: [e.g. 5.1]
 - Script: [e.g. battery_report_generator.ps1]

**Screenshots/Logs**
If applicable, add screenshots or log files.
```

### 3. Add GitHub Releases

When you're ready to release a version:

```bash
# Create and push a tag
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0
```

Then on GitHub:
1. Go to **Releases** → **Draft a new release**
2. Choose your tag
3. Add release notes
4. Attach any compiled binaries or packages

---

## 🐛 Troubleshooting

### Problem: "Permission denied" when pushing

**Solution:** You need to authenticate with GitHub:
- **HTTPS:** You'll be prompted for username and password (use Personal Access Token)
- **SSH:** Set up SSH keys: https://docs.github.com/en/authentication/connecting-to-github-with-ssh

### Problem: "Remote origin already exists"

**Solution:** Update the existing remote:
```bash
git remote set-url origin https://github.com/YOUR_USERNAME/Soulitek-All-In-One-Scripts.git
```

### Problem: "Failed to push some refs"

**Solution:** Pull first, then push:
```bash
git pull origin main --rebase
git push origin main
```

### Problem: Large files rejected

**Solution:** Add to `.gitignore` or use Git LFS:
```bash
# Install Git LFS
git lfs install

# Track large files
git lfs track "*.zip"

# Commit and push
git add .gitattributes
git commit -m "Configure Git LFS"
git push
```

---

## 📚 Additional Resources

### Git & GitHub Learning:
- **GitHub Docs:** https://docs.github.com
- **Git Basics:** https://git-scm.com/book/en/v2
- **GitHub Skills:** https://skills.github.com
- **Git Cheat Sheet:** https://education.github.com/git-cheat-sheet-education.pdf

### PowerShell on GitHub:
- **PowerShell Style Guide:** https://poshcode.gitbook.io/powershell-practice-and-style/
- **PSScriptAnalyzer:** https://github.com/PowerShell/PSScriptAnalyzer
- **Pester Testing:** https://pester.dev

---

## 🎯 Quick Reference Commands

```bash
# Check repository status
git status

# View commit history
git log --oneline

# View differences
git diff

# Create a new branch
git checkout -b feature/new-tool

# Switch branches
git checkout main

# Merge a branch
git merge feature/new-tool

# View all branches
git branch -a

# Delete a local branch
git branch -d feature/new-tool

# Clone repository to another computer
git clone https://github.com/YOUR_USERNAME/Soulitek-All-In-One-Scripts.git

# Update from GitHub
git pull

# Push changes
git push
```

---

## ✅ Checklist for First Upload

- [ ] Git configured with name and email
- [ ] Created repository on GitHub
- [ ] Added remote origin
- [ ] Pushed code successfully
- [ ] Verified files are visible on GitHub
- [ ] Added repository description
- [ ] Added topics/tags
- [ ] Enabled Issues
- [ ] (Optional) Created first release
- [ ] (Optional) Added GitHub Actions workflow
- [ ] (Optional) Created issue templates

---

## 🎉 Success!

Once you've completed these steps, your Soulitek-All-In-One-Scripts toolkit will be live on GitHub!

**Share your repository:**
```
https://github.com/YOUR_USERNAME/Soulitek-All-In-One-Scripts
```

### Next Steps:
1. ⭐ Star your own repository
2. 📢 Share with colleagues and the IT community
3. 📝 Keep README and TODO.md updated
4. 🐛 Track issues and feature requests
5. 🤝 Accept contributions from others

---

## 📞 Need Help?

If you encounter any issues:
1. Check the [Troubleshooting](#-troubleshooting) section above
2. Search GitHub Docs: https://docs.github.com
3. Contact SouliTEK: contact@soulitek.co.il

---

<div align="center">

**Made with ❤️ by SouliTEK**

*Happy coding and version controlling!*

</div>

