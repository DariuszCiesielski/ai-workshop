---
name: github-init
description: Tworzenie nowego repozytorium GitHub i push lokalnego projektu. Inicjalizacja git, setup remote, initial commit. Używaj przy starcie nowego projektu wymagającego repo na GitHubie lub pierwszym pushu istniejącego projektu.
---

# GitHub Repository Initialization

This skill guides you through creating a GitHub repository and pushing a local project.

## When to Use

- Starting a new project that needs version control
- Pushing an existing local project to GitHub
- Setting up a private repository
- Integrating with Vercel or other CI/CD

## Prerequisites

- GitHub CLI (`gh`) installed: `winget install GitHub.cli` or `brew install gh`
- Authenticated: `gh auth login`

## Quick Start

### Option 1: From Existing Local Project

```bash
# Navigate to project directory
cd my-project

# Initialize git (if not already)
git init

# Create .gitignore if needed
cat > .gitignore << 'EOF'
# Dependencies
node_modules/
.pnp
.pnp.js

# Build
dist/
dist-ssr/
*.local

# Environment
.env
.env.local
.env.*.local

# Editor
.vscode/*
!.vscode/extensions.json
.idea/

# OS
.DS_Store
Thumbs.db

# Logs
*.log
npm-debug.log*

# TypeScript
*.tsbuildinfo

# Vercel
.vercel/
EOF

# Stage all files
git add .

# Create initial commit
git commit -m "Initial commit"

# Create GitHub repository (private by default)
gh repo create my-project --private --source=. --push
```

### Option 2: Create Repo First, Clone Later

```bash
# Create empty repository on GitHub
gh repo create my-project --private --description "Project description"

# Clone it
gh repo clone my-project
cd my-project

# Start adding files...
```

## Detailed Steps

### 1. Initialize Git

```bash
git init
git branch -M main  # Rename master to main
```

### 2. Create .gitignore

For React/Vite projects:

```gitignore
# Dependencies
node_modules/

# Build
dist/

# Environment (IMPORTANT: never commit secrets)
.env
.env.local
.env.*.local

# Editor
.vscode/*
!.vscode/extensions.json
.idea/

# OS
.DS_Store
Thumbs.db

# TypeScript
*.tsbuildinfo

# Vercel
.vercel/

# Claude
.claude/settings.local.json
```

### 3. Create Repository on GitHub

Using GitHub CLI:

```bash
# Private repository
gh repo create repo-name --private --description "Description"

# Public repository
gh repo create repo-name --public --description "Description"

# With source and push
gh repo create repo-name --private --source=. --push

# In specific organization
gh repo create org-name/repo-name --private
```

Using MCP Tool (if available):

```
mcp__github__create_repository with:
  name: "repo-name"
  description: "Description"
  private: true
  autoInit: false
```

### 4. Connect Local to Remote

If repo was created without `--source=. --push`:

```bash
# Add remote
git remote add origin https://github.com/username/repo-name.git

# Verify remote
git remote -v

# Push with upstream tracking
git push -u origin main
```

### 5. First Commit

```bash
# Stage files
git add .

# Commit with descriptive message
git commit -m "$(cat <<'EOF'
Initial commit

- Project scaffold with Vite + React + TypeScript
- Tailwind CSS v4 configuration
- Basic routing setup
- README and documentation

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"

# Push
git push -u origin main
```

## Common Operations

### Update Remote URL

```bash
# Change from HTTPS to SSH
git remote set-url origin git@github.com:username/repo.git

# Change to different repo
git remote set-url origin https://github.com/username/new-repo.git
```

### Remove Existing Remote

```bash
# Remove remote named 'origin'
git remote remove origin

# Remove specific remote
git remote remove vercel
```

### View Repository Info

```bash
# List remotes
git remote -v

# View repo on GitHub
gh repo view --web

# Get repo info
gh repo view
```

## Repository Settings

### Add Collaborators

```bash
gh repo edit --add-collaborator username
```

### Change Visibility

```bash
# Make public
gh repo edit --visibility public

# Make private
gh repo edit --visibility private
```

### Set Default Branch

```bash
gh repo edit --default-branch main
```

## Branch Protection (Optional)

For important projects:

```bash
# Via GitHub CLI (limited)
gh api repos/{owner}/{repo}/branches/main/protection \
  -X PUT \
  -H "Accept: application/vnd.github+json" \
  -f required_pull_request_reviews='{"required_approving_review_count":1}'
```

Or via GitHub web interface: Settings → Branches → Add rule

## Integration with Vercel

After creating the GitHub repo:

```bash
# Deploy to Vercel (will auto-connect to GitHub)
vercel --prod

# Or link existing Vercel project
vercel link
```

Vercel will automatically:
- Deploy on push to main
- Create preview deployments for PRs
- Run builds with your environment variables

## Troubleshooting

### Issue: "remote origin already exists"

```bash
git remote remove origin
git remote add origin https://github.com/username/repo.git
```

### Issue: "failed to push some refs"

```bash
# If remote has commits you don't have
git pull origin main --rebase
git push

# Or force push (careful - overwrites remote)
git push -f origin main
```

### Issue: Large files rejected

```bash
# Find large files
find . -type f -size +100M

# Add to .gitignore and remove from tracking
echo "large-file.zip" >> .gitignore
git rm --cached large-file.zip
git commit -m "Remove large file"
```

### Issue: Sensitive data committed

```bash
# Remove file from history (requires git-filter-repo)
pip install git-filter-repo
git filter-repo --path secret.env --invert-paths

# Force push all branches
git push origin --force --all
```

## Best Practices

1. **Always create .gitignore first** before adding files
2. **Never commit .env files** with secrets
3. **Use meaningful commit messages**
4. **Create README.md** with project description
5. **Set repository to private** if it contains sensitive code
6. **Enable branch protection** for production branches
