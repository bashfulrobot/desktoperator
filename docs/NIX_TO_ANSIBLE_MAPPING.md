# Nix to Ansible Variable Mapping

This document maps all variables from your Nix configuration to their Ansible equivalents.

## ✅ Restic/Autorestic Configuration

| Nix Variable/Secret | Ansible Location | Status |
|---------------------|------------------|--------|
| `secrets.b2.account_id` | `vault_b2_account_id` in `vault.yml` | ✅ Configured |
| `secrets.b2.account_key` | `vault_b2_account_key` in `vault.yml` | ✅ Configured |
| `secrets.b2.bucket` | `vault_b2_bucket` in `vault.yml` | ✅ Configured |
| `secrets.restic.password` | `vault_restic_password` in `vault.yml` | ✅ Configured |
| Backup schedule (cron) | `restic.schedule` in `settings.yml` | ✅ Configured |
| Retention policy | `restic.retention_policy.*` in `settings.yml` | ✅ Configured |
| Folder name (hostname) | `restic.folder_name: "{{ ansible_hostname }}"` in `settings.yml` | ✅ Configured |
| Exclude patterns | `restic.custom_excludes` in `settings.yml` + template | ✅ Configured |

### Ansible Files:
- **Template**: `roles/apps/restic/templates/autorestic.yml.j2`
- **Settings**: `group_vars/all/settings.yml` (lines 102-133)
- **Secrets**: `group_vars/all/vault.yml` (lines 48-55)
- **Bootstrap**: `scripts/bootstrap.sh` (lines 98-186)

## ✅ Git Configuration

| Nix Variable/Secret | Ansible Location | Status |
|---------------------|------------------|--------|
| `secrets.git.username` | `git.user.name` in `settings.yml` | ✅ Configured |
| `secrets.git.email` | `git.user.email` in `settings.yml` | ✅ Configured |
| `secrets.git.ssh-signing-key` | `vault_git_ssh_signing_key` in `vault.yml` | ✅ Configured |
| `secrets.git.ssh-signing-key-content` | `vault_git_ssh_signing_key_content` in `vault.yml` | ✅ Configured |
| Git config options | `git.config.*` in `settings.yml` | ✅ Configured |
| Git aliases | `git.aliases.*` in `settings.yml` | ✅ Configured |
| Difftastic settings | `git.difftastic.*` in `settings.yml` | ✅ Configured |

### Ansible Files:
- **Template**: `roles/system/templates/gitconfig.j2`
- **Template**: `roles/system/templates/git-allowed_signers.j2`
- **Settings**: `group_vars/all/settings.yml` (lines 35-77)
- **Secrets**: `group_vars/all/vault.yml` (lines 37-40)
- **Tasks**: `roles/system/tasks/git.yml`

## ✅ Git Tools

| Nix Package | Ansible Installation Method | Status |
|-------------|----------------------------|--------|
| `git` | apt (core_packages) | ✅ Installed |
| `git-lfs` | apt | ✅ Installed |
| `difftastic` | GitHub releases | ✅ Installed |
| `lazygit` | GitHub releases | ✅ Installed |
| `gitui` | GitHub releases | ✅ Installed |
| `gh` (GitHub CLI) | Official apt repo | ✅ Installed |
| `helix` | PPA (maveonair/helix-editor) | ✅ Installed |

### Ansible Files:
- **Tasks**: `roles/system/tasks/git.yml`
- **Templates**: `roles/system/templates/lazygit-config.yml.j2`
- **Templates**: `roles/system/templates/gh-config.yml.j2`

## ❌ Not Yet Implemented

| Nix Package/Config | Reason | Recommendation |
|-------------------|--------|----------------|
| `git-crypt` | User said to ignore | N/A |
| `gptcommit` | Complex OpenAI config, requires API key | Optional - manual install |
| `secrets.openai.api-key` | Only needed for gptcommit | Add to vault if needed |

## ✅ 1Password CLI Paths (Bootstrap Only)

Bootstrap credentials are stored in a single 1Password item:

**Item:** `op://Personal/desktoperator-bootstrap`

### Bootstrap Script (`scripts/bootstrap.sh`)

**Only these fields are needed from 1Password:**
```bash
# Ansible Vault password
op read "op://Personal/desktoperator-bootstrap/ansible-vault"

# Restic/B2 credentials (for bootstrap restic config)
op read "op://Personal/desktoperator-bootstrap/b2_account_id"
op read "op://Personal/desktoperator-bootstrap/b2_account_key"
op read "op://Personal/desktoperator-bootstrap/b2_repository"
op read "op://Personal/desktoperator-bootstrap/restic_password"
```

**SSH/GPG/Git keys are NOT in 1Password** - they're stored in `vault.yml` (encrypted) and deployed by Ansible.

**See:** `docs/1PASSWORD_SETUP.md` for complete setup instructions and commands to extract keys from your current system.

## Variable Usage Flow

### Bootstrap (First-time setup):
```
1Password → bootstrap.sh → ~/.config/autorestic/autorestic.yml (temporary)
```

### Ansible (Ongoing management):
```
1Password (manual) → vault.yml (encrypted) → Ansible → Config files
```

### Settings (Non-secret):
```
settings.yml → Ansible → Config files
```

## Validation Checklist

- ✅ All Nix restic settings mapped to `settings.yml`
- ✅ All Nix restic secrets mapped to `vault.yml`
- ✅ Ansible template uses correct vault variables
- ✅ Bootstrap script retrieves from 1Password
- ✅ Git config settings match Nix config
- ✅ Git signing keys mapped to vault
- ✅ All git tools installed
- ✅ Helix installed and configured as editor
- ⚠️ Need correct 1Password paths from user
- ⚠️ gptcommit not implemented (optional)

## Next Steps

1. **User provides correct 1Password CLI paths**
2. Update `scripts/bootstrap.sh` with correct paths
3. Document the 1Password vault structure in `docs/1PASSWORD_SETUP.md`
4. (Optional) Add gptcommit if desired
