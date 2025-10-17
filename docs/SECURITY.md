# Security & Sensitive File Handling

## Overview

Desktop Operator uses a layered security approach to protect sensitive data:

1. **Encryption**: Secrets stored encrypted using Ansible Vault
2. **Git Exclusion**: Sensitive files automatically excluded via `.gitignore`
3. **File Permissions**: Strict permissions (600) on all sensitive files
4. **Interactive Setup**: Prompts for sensitive values, never hardcoded
5. **Automated Checks**: Security verification before git operations

## Secure Setup Process

### Initial Setup

Run the secure setup script:

```bash
./scripts/secure-setup.sh
```

This interactive script:
1. ✅ Prompts for vault password (or generates one)
2. ✅ Creates `.vault_pass` file (600 permissions, gitignored)
3. ✅ Creates `vault.yml` from template
4. ✅ Lets you edit `vault.yml` with your secrets
5. ✅ Encrypts `vault.yml` with Ansible Vault
6. ✅ Verifies all files are properly secured
7. ✅ Checks git status for accidentally staged secrets

### Quick Setup with Justfile

```bash
just secure-setup
```

## Sensitive Files

### Files That Are NEVER Committed

These files are in `.gitignore` and exist only on your local machine:

| File | Purpose | Permissions | Created By |
|------|---------|-------------|------------|
| `.vault_pass` | Ansible vault password | 600 | `secure-setup.sh` |
| `group_vars/all/vault.yml` | Encrypted secrets (unencrypted copy) | 600 | Manual/Script |
| `files/home/.ssh/config` | SSH config with sensitive hosts | 600 | Optional |
| `files/home/.ssh/*` | SSH private keys | 600 | Ansible |

### Files That ARE Committed (Safely)

| File | Purpose | Status |
|------|---------|--------|
| `group_vars/all/vault.yml.example` | Template for vault | Unencrypted example |
| `.gitignore` | Protects sensitive files | Safe patterns |

**Note**: The actual `vault.yml` can be committed ONLY when encrypted. However, it's safer to never commit it and only commit the `.example` version.

## Vault Password Options

The secure setup script offers three options for vault password:

### Option 1: Manual Entry
- You enter password twice to confirm
- Most control, but you must remember it
- **Store in password manager!**

### Option 2: Auto-Generate (Recommended)
- Generates cryptographically secure random password
- Script displays password for you to save
- **Save to 1Password/Bitwarden immediately!**

### Option 3: 1Password Integration
- Retrieves existing password from 1Password
- Requires 1Password CLI installed
- Seamless integration

## Security Commands

### Check Security Status

```bash
# Run all security checks
just check-secrets

# Check for sensitive files in git
just check-git

# Fix file permissions
just fix-permissions
```

### Before Every Git Commit

**ALWAYS** run before committing:

```bash
just check-git
```

This verifies:
- ✅ No `.vault_pass` file staged
- ✅ No unencrypted `vault.yml` staged
- ✅ No files with `password`, `secret`, `token` in name
- ✅ No `.key`, `.pem` files staged

### Git Hooks (Recommended)

Create a pre-commit hook:

```bash
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
echo "Running security checks..."
just check-git || exit 1
EOF

chmod +x .git/hooks/pre-commit
```

Now git will automatically check before every commit!

## What Goes in vault.yml?

Store these in encrypted `vault.yml`:

### ✅ DO Store
- Passwords (user, database, service)
- API tokens and keys
- SSH private keys
- GPG private keys
- Credentials (WiFi passwords, etc.)
- Sensitive configuration values

### ❌ DON'T Store
- Public information (hostnames, usernames)
- Non-sensitive configuration
- File paths
- Package names
- Repository URLs

## Example vault.yml Structure

```yaml
---
# This entire file is encrypted with ansible-vault

# === Vault Password (for .vault_pass file) ===
vault_password: "your-secure-password-here"

# === User Credentials ===
vault_user_password: "user-password"

# === SSH Keys ===
vault_ssh_private_keys:
  github: |
    -----BEGIN OPENSSH PRIVATE KEY-----
    ...actual key...
    -----END OPENSSH PRIVATE KEY-----

# === API Tokens ===
vault_api_tokens:
  github: "ghp_..."
  tailscale: "tskey_..."

# === Service Credentials ===
vault_credentials:
  wifi_password: "password"
  backup_key: "encryption-key"
```

## Editing Encrypted Files

### Edit vault.yml

```bash
# Opens vault.yml decrypted in your editor
just vault-edit

# Or manually
ansible-vault edit group_vars/all/vault.yml
```

### View vault.yml (Read-Only)

```bash
just vault-view
```

### Change Vault Password

```bash
just vault-rekey
```

## Security Best Practices

### 1. File Permissions

Always maintain strict permissions:

```bash
# Automatically fix permissions
just fix-permissions

# Manual verification
ls -la .vault_pass  # Should show -rw-------
ls -la group_vars/all/vault.yml  # Should show -rw-------
```

### 2. Vault Password Management

- ✅ **DO**: Store in 1Password/Bitwarden
- ✅ **DO**: Use unique password per project
- ✅ **DO**: Share via secure channel (1Password shared vault)
- ❌ **DON'T**: Email vault password
- ❌ **DON'T**: Store in Slack/Discord
- ❌ **DON'T**: Write on paper

### 3. Version Control

- ✅ **DO**: Commit `vault.yml.example`
- ✅ **DO**: Run `just check-git` before commits
- ✅ **DO**: Use pre-commit hooks
- ❌ **DON'T**: Ever commit `.vault_pass`
- ❌ **DON'T**: Commit unencrypted `vault.yml`
- ❌ **DON'T**: Disable .gitignore rules

### 4. Team Collaboration

When sharing this repo with team members:

1. Share vault password securely (1Password shared vault)
2. Each team member runs `just secure-setup`
3. Team members enter the shared vault password
4. Everyone can now decrypt `vault.yml.example` or shared encrypted vault

### 5. Secret Rotation

Periodically rotate secrets:

```bash
# 1. Edit vault with new secrets
just vault-edit

# 2. Update vault password
just vault-rekey

# 3. Share new password securely
# 4. Apply changes to hosts
just all
```

## Emergency Procedures

### Lost Vault Password

If you lose the vault password:

1. **Check 1Password/Bitwarden** first
2. If truly lost, secrets in `vault.yml` are **unrecoverable**
3. Must recreate all secrets:
   ```bash
   # Remove old vault
   rm group_vars/all/vault.yml

   # Start fresh
   just secure-setup

   # Recreate all secrets manually
   just vault-edit
   ```

### Accidentally Committed Secret

If you accidentally commit a secret file:

```bash
# 1. Remove from current commit
git reset HEAD <file>

# 2. If already pushed, remove from history (DANGEROUS)
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch <file>" \
  --prune-empty --tag-name-filter cat -- --all

# 3. Force push (WARNING: affects all clones)
git push origin --force --all

# 4. Rotate all affected secrets immediately!
```

**Better**: Prevent this with pre-commit hooks!

### Compromised Secrets

If secrets are exposed:

1. **Immediately rotate** all affected secrets
2. Update `vault.yml` with new values
3. Apply changes to all hosts:
   ```bash
   just push-all
   ```
4. Audit access logs if available

## Security Checklist

Before going to production:

- [ ] `.vault_pass` exists with 600 permissions
- [ ] `vault.yml` is encrypted (check with `head -1 group_vars/all/vault.yml`)
- [ ] `vault.yml` has 600 permissions
- [ ] Vault password stored in password manager
- [ ] Pre-commit git hook installed
- [ ] Run `just check-secrets` successfully
- [ ] Run `just check-git` successfully
- [ ] All team members have vault password
- [ ] Documented secret rotation procedure
- [ ] Tested vault.yml decryption
- [ ] Reviewed .gitignore patterns

## Troubleshooting

### "no vault secrets found"

**Cause**: Missing `.vault_pass`

**Solution**:
```bash
just secure-setup
```

### "vault.yml is not encrypted"

**Cause**: File exists but not encrypted

**Solution**:
```bash
ansible-vault encrypt group_vars/all/vault.yml
chmod 600 group_vars/all/vault.yml
```

### "wrong permissions" errors

**Cause**: Files have overly permissive permissions

**Solution**:
```bash
just fix-permissions
```

### Can't edit vault.yml

**Cause**: Multiple possible issues

**Solution**:
```bash
# Check if encrypted
head -1 group_vars/all/vault.yml

# Check permissions
ls -la group_vars/all/vault.yml

# Check .vault_pass exists
ls -la .vault_pass

# Try manual edit
ansible-vault edit group_vars/all/vault.yml --vault-password-file=.vault_pass
```

## Additional Resources

- [Ansible Vault Documentation](https://docs.ansible.com/ansible/latest/vault_guide/index.html)
- [Git Ignore Patterns](https://git-scm.com/docs/gitignore)
- [File Permissions Guide](https://www.redhat.com/sysadmin/linux-file-permissions-explained)
