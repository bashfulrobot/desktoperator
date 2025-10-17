# Password Handling in Desktop Operator

## Overview

Desktop Operator is configured to minimize password prompts during normal operation.

## Password Types

### 1. Vault Password (Ansible Vault)

**Purpose**: Decrypt `group_vars/all/vault.yml` containing secrets

**Handled By**: `.vault_pass` file (created during bootstrap)

**Configuration**:
```ini
# ansible.cfg
vault_password_file = .vault_pass
```

**No Prompt**: ✅ Ansible reads password from file automatically

**Setup**:
```bash
# During bootstrap
./scripts/bootstrap.sh  # Retrieves from 1Password and saves to .vault_pass

# Manual setup
echo "your-vault-password" > .vault_pass
chmod 600 .vault_pass
```

### 2. Become Password (sudo)

**Purpose**: Elevate privileges for system tasks

**Handled By**: NOPASSWD sudo configuration

**Configuration**:
```ini
# ansible.cfg
[privilege_escalation]
become = True
become_method = sudo
become_user = root
become_ask_pass = False
```

**No Prompt**: ✅ (after initial bootstrap sets up NOPASSWD sudo)

## Scenarios

### Scenario 1: Fresh System Bootstrap

**First run on a brand new system** where user doesn't have NOPASSWD sudo yet:

```bash
# Use this command for first-time bootstrap
just bootstrap-ask poptop

# You'll be prompted once for sudo password
# After this run, NOPASSWD sudo is configured
```

**What happens**:
1. You're prompted for sudo password
2. Ansible configures NOPASSWD sudo
3. Future runs don't require password

### Scenario 2: Existing System

**System already has NOPASSWD sudo configured**:

```bash
# No password prompts at all
just all
just system
just apps
```

### Scenario 3: Remote System via SSH

**Running against remote host** with SSH keys already deployed:

```bash
# No password prompts
just host poptop
just push poptop
```

**If SSH keys aren't deployed yet**:
```bash
# First manually copy SSH key
ssh-copy-id poptop

# Then run Ansible (no password needed)
just host poptop
```

### Scenario 4: Managing Vault

**Creating or editing encrypted vault**:

```bash
# Will prompt for vault password (not stored in .vault_pass yet)
just vault-init

# After .vault_pass exists, no prompts
just vault-edit
just vault-view
```

## Manual Password Prompts

If you need to override and force password prompts:

### Force Vault Password Prompt
```bash
ansible-playbook playbooks/site.yml --ask-vault-pass
```

### Force Become Password Prompt
```bash
ansible-playbook playbooks/site.yml --ask-become-pass
```

### Both Passwords
```bash
ansible-playbook playbooks/site.yml --ask-vault-pass --ask-become-pass
```

## Security Notes

### .vault_pass File

**Location**: Repository root (`.vault_pass`)

**Permissions**: `600` (read/write for owner only)

**Git**: Ignored via `.gitignore`

**Security**:
- ⚠️ Contains plaintext vault password
- ✅ Never committed to git
- ✅ Only exists on control machine
- ✅ Retrieved securely from 1Password during bootstrap

**Best Practice**: Delete `.vault_pass` when not actively managing infrastructure

```bash
# Delete when done
rm .vault_pass

# Recreate when needed
op read "op://Private/Ansible Vault/password" > .vault_pass
chmod 600 .vault_pass
```

### NOPASSWD Sudo

**Location**: `/etc/sudoers.d/dustin` (on managed hosts)

**Content**:
```
dustin ALL=(ALL) NOPASSWD: ALL
```

**Security Considerations**:
- ✅ Validated with `visudo` before applying
- ⚠️ Allows passwordless sudo for the user
- ✅ Only configured on your personal systems
- ✅ Required for unattended automation

**Alternative**: If you prefer password-required sudo, set in `group_vars/all/settings.yml`:
```yaml
user:
  sudo_nopasswd: false
```

Then run Ansible with:
```bash
just all --ask-become-pass
```

## Troubleshooting

### "ERROR! Attempting to decrypt but no vault secrets found"

**Cause**: Missing `.vault_pass` file

**Solution**:
```bash
# Retrieve from 1Password
op read "op://Private/Ansible Vault/password" > .vault_pass
chmod 600 .vault_pass
```

### "sudo: a password is required"

**Cause**: NOPASSWD sudo not configured yet

**Solution**:
```bash
# First-time bootstrap with password prompt
just bootstrap-ask hostname

# Or run with password prompt
ansible-playbook playbooks/site.yml --ask-become-pass
```

### "Failed to authenticate"

**Cause**: SSH keys not deployed or wrong permissions

**Solution**:
```bash
# Copy SSH key to remote host
ssh-copy-id hostname

# Or check SSH key permissions
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub
```

## Quick Reference

| Command | Vault Password | Become Password | Notes |
|---------|---------------|-----------------|-------|
| `just all` | No prompt | No prompt | Normal operation |
| `just bootstrap-ask poptop` | No prompt | **Prompts** | First-time setup |
| `just vault-edit` | No prompt | N/A | After bootstrap |
| `just vault-init` | **Prompts** | N/A | Creating new vault |
| `just check` | No prompt | No prompt | Dry run |

## Best Practices

1. **Use bootstrap script** for initial setup to handle 1Password integration
2. **Keep .vault_pass secure** with `600` permissions
3. **Use NOPASSWD sudo** for automation convenience on personal systems
4. **Delete .vault_pass** when not actively managing infrastructure
5. **Use `just bootstrap-ask`** for first-time system setup
6. **Store vault password** in 1Password for secure retrieval
