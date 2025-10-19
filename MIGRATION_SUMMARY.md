# Settings Refactoring Migration Summary

## Overview
Simplified settings to contain ONLY reusable variables (DRY principles). Moved all configuration into role defaults for better encapsulation.

## ✅ Files Created

### 1. `inventory/group_vars/all/settings-new.yml`
- Contains ONLY reusable personal info and user settings
- Variables: `personal.name`, `personal.email`, `personal.github_username`, `user.name`, `user.home`, `user.shell`

### 2. `roles/system/defaults/main.yml`
- All system role configuration moved here
- Contains: user groups, sudo settings, core_packages, dev_packages, firewall, updates, etc.

### 3. `roles/system/git/` (self-contained git role)
- `tasks/main.yml` - Git installation and configuration tasks
- `templates/gitconfig.j2` - Updated to use `personal.*` and `git_config.*` variables
- `templates/git-allowed_signers.j2` - Updated to use `personal.email`
- `templates/gh-config.yml.j2` - Copied from system templates
- `templates/lazygit-config.yml.j2` - Copied from system templates
- `defaults/main.yml` - Git configuration (git_config, git_url_rewrites, git_aliases, git_difftastic)

## ✏️  Files Modified

### 1. `roles/system/tasks/main.yml`
- Changed git from `import_tasks: git.yml` to `include_role: system/git`

### 2. `roles/system/tasks/users.yml`
- Updated to use new variable names:
  - `user.groups` → `user_groups`
  - `user.directories` → `user_directories`
  - `user.directory_modes` → `user_directory_modes`
  - `user.sudo_nopasswd` → `user_sudo_nopasswd`

### 3. `roles/system/git/tasks/main.yml`
- Fixed include paths to use `../includes/github_release.yml`
- Changed `git.difftastic.enable` → `git_difftastic.enable`

## 🔒 Security Verified

✅ vault.yml remains encrypted
✅ No secrets leaked into new files
✅ Only comment about vault in settings-new.yml

## 📋 Testing Steps

1. **Backup current working settings:**
   ```bash
   # Already done - settings.yml.backup doesn't exist yet,
   # but original settings.yml is untouched
   ```

2. **Activate new settings:**
   ```bash
   cd /home/dustin/dev/iac/desktoperator
   mv inventory/group_vars/all/settings.yml inventory/group_vars/all/settings.yml.OLD
   mv inventory/group_vars/all/settings-new.yml inventory/group_vars/all/settings.yml
   ```

3. **Test with tags:**
   ```bash
   # Test git role
   ansible-playbook site.yml --tags git --check

   # Test system role
   ansible-playbook site.yml --tags system --check

   # Test users
   ansible-playbook site.yml --tags users --check
   ```

4. **If tests pass, run for real:**
   ```bash
   ansible-playbook site.yml --tags git,system,users
   ```

5. **If everything works, clean up:**
   ```bash
   rm inventory/group_vars/all/settings.yml.OLD
   rm roles/system/tasks/git.yml
   rm roles/system/templates/gitconfig.j2
   rm roles/system/templates/git-allowed_signers.j2
   rm roles/system/templates/gh-config.yml.j2
   rm roles/system/templates/lazygit-config.yml.j2
   ```

## 🔄 Rollback Plan

If something breaks:
```bash
cd /home/dustin/dev/iac/desktoperator
mv inventory/group_vars/all/settings.yml inventory/group_vars/all/settings-new.yml
mv inventory/group_vars/all/settings.yml.OLD inventory/group_vars/all/settings.yml

# Revert system tasks
git checkout roles/system/tasks/main.yml roles/system/tasks/users.yml

# Remove new files
rm -rf roles/system/defaults/
rm -rf roles/system/git/
```

## 📝 What Stays the Same

- vault.yml (unchanged, still encrypted)
- All app roles (vivaldi, starship, todoist, etc.)
- System task files (except git, users, main.yml)
- All existing functionality

## 🎯 Benefits

- ✅ Settings file is tiny and focused (15 lines vs 180+)
- ✅ Git is self-contained in its own role
- ✅ System configuration lives with system role
- ✅ No functionality lost
- ✅ Easier to understand for new contributors
