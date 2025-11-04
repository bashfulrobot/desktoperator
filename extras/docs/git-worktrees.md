# Git Worktrees Cheat Sheet

Quick reference for git worktree workflow with Claude Code parallel development.

## Setup & Creation

```bash
# Create a worktree (using our helper)
gtr create feature1

# Create multiple worktrees at once
gtr create feature1 feature2 bugfix

# Create worktree from specific branch (raw git)
git worktree add ~/dev/worktrees/myrepo/feature1 -b claude/feature1 main

# List all worktrees
gtr list
git worktree list
```

## Working in a Worktree

```bash
# Change to worktree directory
gtr cd feature1

# Or manually
cd ~/dev/worktrees/myrepo/feature1

# Launch Claude Code in worktree
gtr claude feature1

# Check status
git status
git branch --show-current  # Should show: claude/feature1
```

## Commit & Push

```bash
# Inside worktree directory
git add .
git commit -m "feat: add new feature"

# Push to remote (first time)
git push -u origin claude/feature1

# Push subsequent changes
git push
```

## Merge to Main

```bash
# Option 1: From main repo directory
cd ~/dev/iac/desktoperator
git checkout main
git pull
git merge claude/feature1
git push

# Option 2: From worktree (merge main into your branch first)
cd ~/dev/worktrees/desktoperator/feature1
git fetch origin
git merge origin/main
# Resolve conflicts if any
git push

# Then go to main and merge
cd ~/dev/iac/desktoperator
git checkout main
git merge claude/feature1
git push
```

## Cleanup

```bash
# Remove worktree after merge
gtr rm feature1

# Or manually
git worktree remove ~/dev/worktrees/myrepo/feature1

# Delete the branch
git branch -d claude/feature1

# Delete remote branch
git push origin --delete claude/feature1

# Clean up stale worktree references
gtr prune
git worktree prune
```

## Automated Cleanup

```bash
# Clean up all merged worktrees
gwt-cleanup-merged

# Check status of all worktrees
gwt-status
```

## Common Workflows

### Quick Feature Development

```bash
# 1. Create worktree
gtr create new-feature

# 2. Code in worktree
gtr claude new-feature
# ... make changes ...

# 3. Commit & push
git add .
git commit -m "feat: implement new feature"
git push -u origin claude/new-feature

# 4. Create PR (optional)
gh pr create --title "Add new feature"

# 5. After PR merged, cleanup
gtr rm new-feature
git branch -d claude/new-feature
```

### Parallel Development (Multiple Features)

```bash
# Create multiple worktrees
gtr create auth-refactor api-v2 bug-fix

# Terminal 1: Work on auth
cd ~/dev/worktrees/myrepo/auth-refactor
claude

# Terminal 2: Work on API
cd ~/dev/worktrees/myrepo/api-v2
claude

# Terminal 3: Fix bug
cd ~/dev/worktrees/myrepo/bug-fix
claude

# Each can be committed/pushed independently
```

### Emergency Hotfix (No Stashing)

```bash
# Already working in a feature worktree
# No need to stash! Just create new worktree

gtr create hotfix
gtr claude hotfix

# Fix bug, commit, push
git add .
git commit -m "fix: critical bug"
git push -u origin claude/hotfix

# Merge to main immediately
cd ~/dev/iac/desktoperator
git checkout main
git merge claude/hotfix
git push

# Clean up
gtr rm hotfix
git branch -d claude/hotfix

# Continue with original feature work - context preserved!
```

## Troubleshooting

```bash
# Branch already checked out error
git worktree list  # Find where it's checked out
gtr rm old-name    # Remove the old worktree
gtr create new-name

# Worktree directory exists but not in git
rm -rf ~/dev/worktrees/myrepo/stale-worktree
git worktree prune

# Check all worktree status at once
gwt-status

# List all branches (including worktree branches)
git branch -a
```

## Path Structure

```
~/dev/iac/desktoperator/           # Main repo (pristine)
~/dev/worktrees/
  └── desktoperator/
      ├── feature1/                # Worktree 1
      ├── feature2/                # Worktree 2
      └── bugfix/                  # Worktree 3
```

## Raw Git Commands (Without gtr)

```bash
# Create worktree
git worktree add ~/dev/worktrees/myrepo/feature1 -b claude/feature1

# List worktrees
git worktree list

# Remove worktree
git worktree remove ~/dev/worktrees/myrepo/feature1

# Prune stale references
git worktree prune

# Move/rename worktree
git worktree move ~/dev/worktrees/myrepo/old ~/dev/worktrees/myrepo/new
```

## Tips

- Main repo stays pristine - never work directly in it
- Each worktree has its own working directory but shares git history
- No more `git stash` needed for context switching
- Claude Code maintains full context in each worktree
- Branches prefixed with `claude/` for easy identification
- Can run different Claude sessions in parallel without conflicts
