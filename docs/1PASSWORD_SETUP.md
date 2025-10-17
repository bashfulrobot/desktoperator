# 1Password Setup for Desktop Operator

This document describes the 1Password vault structure required for bootstrap and Ansible operations.

## Required 1Password Item

**Item Name:** `desktoperator-bootstrap`
**Vault:** `Personal`
**Item Path:** `op://Personal/desktoperator-bootstrap`

## Required Fields

Create a single 1Password item with the following fields:

| Field Name | Description | Example | Used By |
|------------|-------------|---------|---------|
| `ansible-vault` | Ansible vault password | `your-secure-vault-password` | Bootstrap |
| `b2_account_id` | Backblaze B2 account ID | `0012345abcdef` | Bootstrap (restic config) |
| `b2_account_key` | Backblaze B2 application key | `K001abc...` | Bootstrap (restic config) |
| `b2_repository` | Full S3 repository URL | `s3:s3.us-west-000.backblazeb2.com/ws-bups` | Bootstrap (restic config) |
| `restic_password` | Restic repository encryption password | `your-restic-password` | Bootstrap (restic config) |

**Note:** SSH keys, GPG keys, and git signing keys are NOT stored in 1Password. They're stored in `vault.yml` (encrypted with ansible-vault) and deployed by Ansible.

## Usage

### Bootstrap Script

The bootstrap script (`scripts/bootstrap.sh`) automatically retrieves values from this item:

```bash
./bootstrap.sh
# Will prompt for 1Password authentication
# Then retrieves all fields automatically
```

### Manual Retrieval

```bash
# Sign in to 1Password CLI
eval $(op signin)

# Read specific field
op read "op://Personal/desktoperator-bootstrap/ansible-vault"
op read "op://Personal/desktoperator-bootstrap/b2_account_id"
```

## Ansible Vault Population

After bootstrap, you'll need to manually populate `group_vars/all/vault.yml` with secrets.

### Step 1: Gather Your Keys from Current System

```bash
# SSH private key (for GitHub, GitLab, etc.)
cat ~/.ssh/id_ed25519

# SSH public key
cat ~/.ssh/id_ed25519.pub

# GPG private key (export your signing key)
gpg --list-secret-keys --keyid-format=long  # Find your key ID
gpg --armor --export-secret-keys YOUR_KEY_ID

# Git signing key path (usually your SSH key)
echo ~/.ssh/id_ed25519

# Git signing key content (the public key for allowed_signers)
cat ~/.ssh/id_ed25519.pub
```

### Step 2: Edit Vault File

```bash
# Edit the encrypted vault file
ansible-vault edit group_vars/all/vault.yml
```

### Step 3: Add Values to Vault

```yaml
---
# Restic/B2 credentials (from 1Password)
b2_account_id: "your-b2-account-id"
b2_account_key: "your-b2-account-key"
b2_repository: "s3:s3.us-west-000.backblazeb2.com/your-bucket"
restic_password: "your-restic-password"

# SSH Keys (paste from commands above)
ssh_private_keys:
  id_ed25519: |
    -----BEGIN OPENSSH PRIVATE KEY-----
    [paste output from: cat ~/.ssh/id_ed25519]
    -----END OPENSSH PRIVATE KEY-----

ssh_public_keys:
  id_ed25519: "[paste output from: cat ~/.ssh/id_ed25519.pub]"

# GPG Keys (paste from commands above)
gpg_private_keys:
  signing: |
    -----BEGIN PGP PRIVATE KEY BLOCK-----
    [paste output from: gpg --armor --export-secret-keys YOUR_KEY_ID]
    -----END PGP PRIVATE KEY BLOCK-----

# Git SSH Signing (uses same SSH key)
git_ssh_signing_key: "~/.ssh/id_ed25519"
git_ssh_signing_key_content: "[paste output from: cat ~/.ssh/id_ed25519.pub]"
```

**Tip:** You can use 1Password CLI to help populate B2/restic values:
```bash
op read "op://Personal/desktoperator-bootstrap/b2_account_id"
op read "op://Personal/desktoperator-bootstrap/b2_account_key"
op read "op://Personal/desktoperator-bootstrap/b2_repository"
op read "op://Personal/desktoperator-bootstrap/restic_password"
```

## Security Notes

- ✅ All fields are stored encrypted in 1Password
- ✅ Bootstrap script only creates temporary files (`.vault_pass`, `autorestic.yml`)
- ✅ `.vault_pass` is in `.gitignore` and never committed
- ✅ `vault.yml` is encrypted with ansible-vault before committing
- ✅ Bootstrap config files are overwritten by Ansible on first run

## Troubleshooting

### "Item not found" error

Verify the item exists:
```bash
op item get desktoperator-bootstrap --vault Personal
```

### "Field not found" error

List all fields in the item:
```bash
op item get desktoperator-bootstrap --vault Personal --format json | jq '.fields'
```

### Wrong vault

Ensure you're using the "Personal" vault, not "Private":
```bash
op vault list
```
