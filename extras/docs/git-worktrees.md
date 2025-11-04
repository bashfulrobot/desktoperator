# Git Worktrees Cheat Sheet

Quick reference for git worktree workflow with Claude Code parallel development.

## Complete Workflow (Start to Finish)

```bash
# Starting from ANY main repository (wherever it lives on your system)
cd ~/path/to/your/repo

# 1. Create worktree and enter it
gtr create my-feature
# → Now in: ~/dev/worktrees/repo/my-feature

# 2. Do your work
# ... edit files, code, etc ...

# 3. Commit your changes (in Claude Code)
/commit
# → Uses conventional commit format with emoji
# → Creates proper commit message

# 4. Finish (merges to main, cleans up everything)
gtr finish
# → Pushes to remote
# → Merges to main
# → Pushes main to remote
# → Deletes worktree
# → Deletes branch
# → Returns you to: ~/path/to/your/repo (on main, with changes pulled)

# Done! All worktrees and branches cleaned up, changes in main.
# Your repo can live ANYWHERE - gtr automatically finds it.
```

## The Simple Workflow (Recommended)

This is all you need for 90% of your work:

```bash
# 1. Create worktree and cd into it
gtr create my-feature

# 2. Do your work (manually or with Claude)
# ... edit files, code, etc ...

# 3. Commit using Claude Code's /commit command
/commit

# 4. Finish - merge and cleanup
gtr finish
# - Pushes to remote
# - Merges to main branch
# - Cleans up worktree
# - Returns you to main repo

# That's it!
```

## Available Commands

```bash
# Primary workflow
gtr create <name>     # Create worktree and cd into it
gtr finish            # Complete workflow from worktree (commit, merge, cleanup)

# Other useful commands
gtr list              # List all worktrees
gtr cd <name>         # Change to worktree directory
gtr claude <name>     # Launch Claude Code in worktree
gtr done [name]       # Cleanup after external merge (e.g., GitHub PR)
gtr rm <name>         # Remove worktree manually
gtr prune             # Clean up stale references

# Bulk operations
gwt-cleanup-merged    # Remove all merged worktrees at once
gwt-status            # Show status of all worktrees
```

## Typical Day Examples

### Single Feature Development

```bash
# Start work
gtr create user-auth

# Work on the feature
# ... make your changes ...

# Commit using Claude Code
/commit

# Finish and merge
gtr finish
# Everything happens automatically!
```

### Quick Bug Fix

```bash
# Create worktree for fix
gtr create fix-login-bug

# Make the fix
# ... edit files ...

# Commit the fix
/commit

# Done - merge it
gtr finish
```

### Parallel Development (Multiple Features)

```bash
# Terminal 1: Work on feature A
gtr create auth-refactor
# ... work on auth ...
/commit
gtr finish

# Terminal 2: Work on feature B (simultaneously!)
gtr create api-v2
# ... work on API ...
/commit
gtr finish

# No stashing, no context switching headaches
```

### Emergency Hotfix (No Stashing Required)

```bash
# Already working in a feature worktree?
# No need to stash! Just create new worktree

gtr create hotfix
# ... fix the critical bug ...
/commit
gtr finish

# Original feature work still intact - context preserved!
gtr cd original-feature
# Continue where you left off
```

### Using GitHub PRs Instead of Direct Merge

```bash
# Create and work in worktree
gtr create new-feature
# ... do your work ...

# Commit and push (without merging)
git add -A
git commit -m "feat: add new feature"
git push -u origin claude/new-feature

# Create PR via GitHub
gh pr create --title "Add new feature"

# After PR is merged on GitHub, cleanup
gtr done
# Automatically detects worktree, pulls latest main, cleans up
```

## Advanced Usage

### Manual Workflow (More Control)

If you want more control over the process:

```bash
# Create and work in worktree
gtr create feature1

# Commit manually
git add -A
git commit -m "feat: my feature"

# Push manually
git push -u origin claude/feature1

# Use 'done' instead of 'finish' if already merged externally (e.g., via GitHub PR)
gtr done

# Or remove manually
gtr rm feature1
```

### Bulk Cleanup

```bash
# Remove all merged worktrees at once
gwt-cleanup-merged

# Check status of all worktrees
gwt-status
```

## Troubleshooting

```bash
# Branch already exists error
gtr list              # See all worktrees
gtr rm old-name      # Remove the conflicting one

# Stale worktree references
gtr prune

# Check status of all worktrees
gwt-status

# View all branches
gtr list
git branch -a
```

## Path Structure

```
~/anywhere/you/want/myrepo/        # Main repo (stays pristine, can be anywhere)
~/dev/worktrees/                   # Worktrees always go here (standard location)
  └── myrepo/
      ├── feature1/                # Worktree 1
      ├── feature2/                # Worktree 2
      └── bugfix/                  # Worktree 3
```

**Key Point**: Your main repos can live anywhere on your system. Worktrees always go to `~/dev/worktrees/<repo-name>/`. The `gtr` commands automatically find your main repo location and handle the back-and-forth navigation for you.

## Why This Works

- **Main repo stays clean** - Never work directly in it
- **No stashing** - Each worktree preserves its context
- **Parallel work** - Multiple features simultaneously
- **Claude-friendly** - Each worktree keeps full Claude Code context
- **Simple** - Just two commands: `create` and `finish`
