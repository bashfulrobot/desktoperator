# Pake Infrastructure Rollback Guide

## Current Architecture (Refactored)

As of the latest refactor, Pake infrastructure uses a clean separation of concerns:

1. **`generate-icon-set`** - Download and process icons (standalone, reusable)
2. **`create-web-app`** - Build Pake app (.deb) and Ansible scaffolding (no icon logic)

## If You Need to Rollback

### Check if Backup Exists

```bash
ls -lh ~/dev/iac/desktoperator/roles/apps/pake/templates/pake-wrapper.fish.j2.backup*
```

### Restore Previous Version

```bash
# Restore the backup (replace with your specific backup file)
cp ~/dev/iac/desktoperator/roles/apps/pake/templates/pake-wrapper.fish.j2.backup \
   ~/dev/iac/desktoperator/roles/apps/pake/templates/pake-wrapper.fish.j2

# Redeploy
ansible-playbook site.yml --tags pake

# Restart terminal to load old functions
```

### Alternative: Use Git

```bash
cd ~/dev/iac/desktoperator

# View recent commits
git log --oneline roles/apps/pake/ | head -10

# Restore to specific commit
git checkout <commit-hash> -- roles/apps/pake/

# Redeploy
ansible-playbook site.yml --tags pake
```

## Major Refactoring Changes

### What Changed

**Old Architecture:**
- Single monolithic `_generate_pake_icons` function (private)
- Brandfetch API calls embedded in icon generation
- Complex argument parsing (6 positional args)
- Icons generated during app creation
- `regenerate-pake-icons` wrapper function

**New Architecture (Current):**
- **`generate-icon-set`** - Public, standalone icon processing
- No Brandfetch API (manual icon URL input)
- Simple arguments (icon_url, name, flags)
- Icons generated separately from app creation
- `regenerate-pake-icons` removed (redundant)

### Function Signature Changes

**Old:**
```fish
_generate_pake_icons <url> <name> <custom_domain> <output_dir> <add_background> <user_icon_path>
create-web-app <url> <name> [custom_domain] [--add-background] [--icon <url>] [pake-options...]
regenerate-pake-icons <url> <name> [custom_domain] [--add-background] [--icon <url>]
```

**New:**
```fish
generate-icon-set <icon_source> <name> [--output <path>] [--add-background]
create-web-app <app_url> <name> [pake-options...]
# regenerate-pake-icons - REMOVED (use generate-icon-set instead)
```

### Script Updates

**Old Workflow:**
```bash
# Everything in one step
create-web-app https://github.com github --icon 'https://...'
```

**New Workflow:**
```bash
# Step 1: Build app
create-web-app https://github.com github

# Step 2: Generate icons separately
generate-icon-set 'https://github.../logo.svg' github
```

## Testing After Rollback

```bash
# Test old functions work
create-web-app https://example.com test-app --icon 'https://example.com/logo.png'

# Verify Brandfetch API still works
create-web-app https://github.com test-github  # Should auto-fetch icon

# Clean up test apps
rm -rf ~/dev/iac/desktoperator/roles/apps/test-*
```

## Troubleshooting

### Functions Not Found

```bash
# Check which version is deployed
grep "^function" ~/.config/fish/conf.d/pake-wrapper.fish

# Expected (new):  generate-icon-set, create-web-app
# Expected (old):  create-web-app, regenerate-pake-icons
```

### Brandfetch API Errors

The new architecture doesn't use Brandfetch API. If you need automatic icon fetching, you must rollback to the old version.

### Scripts Fail

Old scripts expect the old function signatures. After rollback:

```bash
# Old scripts will work again
./scripts/regenerate-pake-apps.fish   # Uses old create-web-app
./scripts/regenerate-pake-icons.fish  # Uses old regenerate-pake-icons
```

## Migration Path Forward

If rollback works but you want the new architecture:

1. Update your scripts to use new workflow
2. Find icon URLs manually (Brandfetch web UI, favicons, etc.)
3. Use `generate-icon-set` for icon processing
4. Keep app building and icon generation separate

## Contact

If you encounter issues, check:
- Git history: `git log roles/apps/pake/`
- Documentation: `roles/apps/pake/README.md`
- Template file: `roles/apps/pake/templates/pake-wrapper.fish.j2`
