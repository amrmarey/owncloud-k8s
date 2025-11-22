# Git Cleanup and Push Guide

This guide will help you remove the archive folder from Git tracking and push the reorganized project to GitHub.

## Step 1: Remove Archive from Git Tracking

The archive folder is now in `.gitignore`, but if it was previously tracked by Git, you need to remove it from the Git index:

```bash
# Remove archive folder from Git index (keeps it locally)
git rm -r --cached archive/
```

## Step 2: Stage All Changes

```bash
# Stage all changes
git add .
```

## Step 3: Check What Will Be Committed

```bash
# Review changes
git status
```

You should see:
- Modified files (README.md, .gitignore, etc.)
- New files (SECURITY.md, CONTRIBUTING.md, etc.)
- Deleted files (from archive/ if it was previously tracked)

## Step 4: Commit Changes

```bash
git commit -m "chore: Reorganize project structure

- Separated KIND and production configurations into dedicated folders
- Moved all documentation to docs/ folder
- Moved legacy files to archive/ (excluded from Git)
- Removed PowerShell scripts (Bash only)
- Added comprehensive legal disclaimers and security policy
- Created .gitignore, LICENSE, CONTRIBUTING.md, and SECURITY.md
- Updated all READMEs with new structure
- Educational purpose only - see LICENSE and SECURITY.md"
```

## Step 5: Push to GitHub

### Option A: Normal Push (Recommended)

```bash
# If your default branch is 'main'
git push origin main

# If your default branch is 'master'
git push origin master
```

### Option B: Force Push (Use with Caution!)

⚠️ **Warning**: Only use force push if you're sure no one else is working on the repository!

```bash
# Force push to main
git push -f origin main

# Or force push to master
git push -f origin master
```

## Step 6: Verify on GitHub

1. Go to your GitHub repository: https://github.com/amrmarey/owncloud-k8s
2. Verify that:
   - ✅ Archive folder is not visible
   - ✅ New structure is present (kind/, production/, docs/)
   - ✅ SECURITY.md and other new files are there
   - ✅ README shows the disclaimer

## Quick Command Summary

```bash
# All in one go:
git rm -r --cached archive/
git add .
git commit -m "chore: Reorganize project structure with legal disclaimers"
git push origin main
```

## Alternative: Using the Provided Script

```bash
# Make the script executable
chmod +x cleanup-and-commit.sh

# Run the script
./cleanup-and-commit.sh

# Then manually push
git push origin main
```

## Troubleshooting

### If archive folder still appears on GitHub after push:

```bash
# Ensure it's in .gitignore
cat .gitignore | grep archive

# Remove from Git index again
git rm -r --cached archive/

# Commit and push
git add .gitignore
git commit -m "fix: Remove archive folder from Git tracking"
git push origin main
```

### If you get merge conflicts:

```bash
# Pull latest changes first
git pull origin main --rebase

# Resolve any conflicts, then
git add .
git rebase --continue
git push origin main
```

### If you need to completely reset (DANGER!):

⚠️ **This will overwrite remote repository!**

```bash
git push -f origin main
```

## Notes

- The archive folder will remain on your local machine
- It just won't be tracked by Git or appear on GitHub
- This keeps your GitHub repository clean and professional
- Legacy files are preserved locally if you need them

## After Pushing

Your GitHub repository will show:
- Clean root directory (only README, LICENSE, CONTRIBUTING, SECURITY, .gitignore)
- Organized folders (kind/, production/, docs/)
- No archive folder
- Professional, production-ready structure
