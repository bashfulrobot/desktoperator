# Vault Key Management

This guide shows how to add multiple SSH and GPG keys to your encrypted `vault.yml` file.

## Adding SSH Keys

### Step 1: List Your SSH Keys

```bash
# List all SSH keys
ls -la ~/.ssh/

# Common key files:
# id_ed25519, id_ed25519.pub
# id_rsa, id_rsa.pub
# github, github.pub
# etc.
```

### Step 2: Get Key Contents

```bash
# Private keys (one at a time)
cat ~/.ssh/id_ed25519
cat ~/.ssh/id_rsa
cat ~/.ssh/github

# Public keys (one at a time)
cat ~/.ssh/id_ed25519.pub
cat ~/.ssh/id_rsa.pub
cat ~/.ssh/github.pub
```

### Step 3: Add to vault.yml

```bash
# Edit the encrypted vault
ansible-vault edit group_vars/all/vault.yml
```

```yaml
# Add each key with a descriptive name
ssh_private_keys:
  id_ed25519: |
    -----BEGIN OPENSSH PRIVATE KEY-----
    [paste output from: cat ~/.ssh/id_ed25519]
    -----END OPENSSH PRIVATE KEY-----

  id_rsa: |
    -----BEGIN RSA PRIVATE KEY-----
    [paste output from: cat ~/.ssh/id_rsa]
    -----END RSA PRIVATE KEY-----

  github: |
    -----BEGIN OPENSSH PRIVATE KEY-----
    [paste output from: cat ~/.ssh/github]
    -----END OPENSSH PRIVATE KEY-----

ssh_public_keys:
  id_ed25519: "[paste from: cat ~/.ssh/id_ed25519.pub]"
  id_rsa: "[paste from: cat ~/.ssh/id_rsa.pub]"
  github: "[paste from: cat ~/.ssh/github.pub]"
```

**Result:** Keys will be deployed to `~/.ssh/id_ed25519`, `~/.ssh/id_rsa`, `~/.ssh/github`, etc.

## Adding GPG Keys

### Step 1: List Your GPG Keys

```bash
# List all GPG keys with their IDs
gpg --list-secret-keys --keyid-format=long

# Example output:
# sec   rsa4096/ABCD1234EFGH5678 2024-01-01 [SC]
# uid                 [ultimate] Your Name <you@example.com>
# ssb   rsa4096/1234ABCD5678EFGH 2024-01-01 [E]
```

### Step 2: Export Each Key

```bash
# Export each key by its ID (from the sec line above)
gpg --armor --export-secret-keys ABCD1234EFGH5678
gpg --armor --export-secret-keys ANOTHER_KEY_ID
```

### Step 3: Add to vault.yml

```bash
# Edit the encrypted vault
ansible-vault edit group_vars/all/vault.yml
```

```yaml
# Add each GPG key with a descriptive name
gpg_private_keys:
  signing: |
    -----BEGIN PGP PRIVATE KEY BLOCK-----
    [paste output from: gpg --armor --export-secret-keys ABCD1234EFGH5678]
    -----END PGP PRIVATE KEY BLOCK-----

  encryption: |
    -----BEGIN PGP PRIVATE KEY BLOCK-----
    [paste output from: gpg --armor --export-secret-keys ANOTHER_KEY_ID]
    -----END PGP PRIVATE KEY BLOCK-----

  work: |
    -----BEGIN PGP PRIVATE KEY BLOCK-----
    [paste output from: gpg --armor --export-secret-keys WORK_KEY_ID]
    -----END PGP PRIVATE KEY BLOCK-----
```

**Result:** All keys will be imported into your GPG keyring.

## Complete Example

Here's a complete `vault.yml` with multiple keys:

```yaml
---
# === Multiple SSH Keys ===
ssh_private_keys:
  id_ed25519: |
    -----BEGIN OPENSSH PRIVATE KEY-----
    b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
    ...your full key content...
    -----END OPENSSH PRIVATE KEY-----

  id_rsa: |
    -----BEGIN RSA PRIVATE KEY-----
    MIIEpAIBAAKCAQEA1234567890abcdef...
    ...your full key content...
    -----END RSA PRIVATE KEY-----

  github: |
    -----BEGIN OPENSSH PRIVATE KEY-----
    b3BlbnNzaC1rZXktdjEAAAAABG5vbmU...
    ...your full key content...
    -----END OPENSSH PRIVATE KEY-----

ssh_public_keys:
  id_ed25519: "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA... dustin@example.com"
  id_rsa: "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAB... dustin@example.com"
  github: "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA... dustin@github-key"

# === Multiple GPG Keys ===
gpg_private_keys:
  signing: |
    -----BEGIN PGP PRIVATE KEY BLOCK-----
    lQdGBGXExample1234567890abcdef...
    ...your full key content...
    -----END PGP PRIVATE KEY BLOCK-----

  encryption: |
    -----BEGIN PGP PRIVATE KEY BLOCK-----
    lQdGBGXAnother1234567890abcdef...
    ...your full key content...
    -----END PGP PRIVATE KEY BLOCK-----

# === Git SSH Signing ===
# Which SSH key to use for git commit signing
git_ssh_signing_key: "~/.ssh/id_ed25519"
git_ssh_signing_key_content: "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA... dustin@example.com"

# === Restic/B2 Credentials ===
b2_account_id: "your-b2-account-id"
b2_account_key: "your-b2-account-key"
b2_repository: "s3:s3.us-west-000.backblazeb2.com/your-bucket"
restic_password: "your-restic-password"
```

## Quick Commands Cheatsheet

```bash
# List all SSH keys
ls -la ~/.ssh/*.pub

# Get all SSH private keys at once
for key in ~/.ssh/id_*; do
  if [[ ! $key =~ \.pub$ ]]; then
    echo "=== $key ==="
    cat "$key"
    echo ""
  fi
done

# Get all SSH public keys at once
for key in ~/.ssh/*.pub; do
  echo "=== $key ==="
  cat "$key"
done

# List all GPG secret keys
gpg --list-secret-keys --keyid-format=long

# Export all GPG keys at once (run for each key ID)
gpg --armor --export-secret-keys KEY_ID_HERE

# Edit vault file
ansible-vault edit group_vars/all/vault.yml
```

## Notes

- **SSH Key Names:** The key name in `vault_ssh_private_keys` becomes the filename (e.g., `id_ed25519` → `~/.ssh/id_ed25519`)
- **GPG Key Names:** The key name is just for your organization (e.g., `signing`, `encryption`, `work`)
- **Git Signing:** Only one SSH key can be used for git signing (specified in `vault_git_ssh_signing_key`)
- **Ansible Deploys:** SSH keys are deployed to `~/.ssh/` and GPG keys are imported to your GPG keyring
- **Permissions:** SSH private keys are set to 600, public keys to 644 automatically
