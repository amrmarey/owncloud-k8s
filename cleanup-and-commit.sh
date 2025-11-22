#!/bin/bash
# Script to remove archive folder from Git and push changes to GitHub

echo "=== Removing archive folder from Git tracking ==="

# Remove archive folder from Git index (but keep it locally)
git rm -r --cached archive/

echo ""
echo "=== Staging all changes ==="

# Stage all changes including .gitignore update
git add .

echo ""
echo "=== Creating commit ==="

# Commit the changes
git commit -m "chore: Reorganize project structure

- Separated KIND and production configurations into dedicated folders
- Moved all documentation to docs/ folder
- Moved legacy files to archive/ (excluded from Git)
- Removed PowerShell scripts (Bash only)
- Added comprehensive legal disclaimers and security policy
- Created .gitignore, LICENSE, CONTRIBUTING.md, and SECURITY.md
- Updated all READMEs with new structure
- Educational purpose only - see LICENSE and SECURITY.md"

echo ""
echo "=== Ready to push to GitHub ==="
echo ""
echo "To push to GitHub, run:"
echo "  git push origin main"
echo ""
echo "Or if your default branch is 'master':"
echo "  git push origin master"
echo ""
echo "If you want to force push (use with caution!):"
echo "  git push -f origin main"
echo ""
