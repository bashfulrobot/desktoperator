# SSH & GPG Key Restoration from Restic Backup

## Strategy: Restore from Restic/Autorestic (Recommended)

You already have encrypted backups in B2 via restic/autorestic. This is the cleanest approach!

### Benefits
- ✅ Keys already backed up securely
- ✅ Encrypted at rest in B2
- ✅ No duplication (single source of truth)
- ✅ Works for ALL dotfiles and keys
- ✅ No manual key management
- ✅ Natural disaster recovery workflow

## Implementation

### Option 1: Manual Restore During Bootstrap (Simple)

**Bootstrap workflow:**
```bash
# 1. Run bootstrap.sh (installs Ansible, clones repo)
./scripts/bootstrap.sh

# 2. Install restic/autorestic
sudo apt install restic
# Or: just install-autorestic

# 3. Restore keys from backup
restic -r b2:your-bucket:/repo restore latest \
  --target / \
  --include /home/dustin/.ssh \
  --include /home/dustin/.gnupg

# 4. Fix permissions
chmod 700 ~/.ssh ~/.gnupg
chmod 600 ~/.ssh/* ~/.gnupg/*
chmod 644 ~/.ssh/*.pub

# 5. Continue with Ansible
just system
```

### Option 2: Ansible-Managed Restore (Automated)

Create an Ansible role that handles restoration:

**Role: roles/system/tasks/restore-keys.yml**
```yaml
---
# Restore SSH/GPG keys from restic backup

- name: Check if restic is installed
  command: which restic
  register: restic_check
  failed_when: false
  changed_when: false

- name: Install restic if not present
  apt:
    name: restic
    state: present
  become: true
  when: restic_check.rc != 0

- name: Check if keys already exist
  stat:
    path: "{{ user.home }}/.ssh/id_ed25519"
  register: ssh_key_exists

- name: Restore SSH keys from restic backup
  shell: |
    export RESTIC_PASSWORD="{{ vault_restic_password }}"
    export B2_ACCOUNT_ID="{{ vault_b2_account_id }}"
    export B2_ACCOUNT_KEY="{{ vault_b2_account_key }}"

    restic -r b2:{{ restic_backup.bucket }}:{{ restic_backup.repo }} restore latest \
      --target / \
      --include {{ user.home }}/.ssh
  become: true
  become_user: "{{ user.name }}"
  when:
    - not ssh_key_exists.stat.exists
    - restore_from_backup | default(false)
  no_log: true

- name: Restore GPG keys from restic backup
  shell: |
    export RESTIC_PASSWORD="{{ vault_restic_password }}"
    export B2_ACCOUNT_ID="{{ vault_b2_account_id }}"
    export B2_ACCOUNT_KEY="{{ vault_b2_account_key }}"

    restic -r b2:{{ restic_backup.bucket }}:{{ restic_backup.repo }} restore latest \
      --target / \
      --include {{ user.home }}/.gnupg
  become: true
  become_user: "{{ user.name }}"
  when:
    - restore_from_backup | default(false)
  no_log: true

- name: Fix SSH key permissions
  file:
    path: "{{ user.home }}/.ssh"
    state: directory
    owner: "{{ user.name }}"
    mode: '0700'
    recurse: yes
  become: true

- name: Fix SSH private key permissions
  shell: |
    chmod 600 {{ user.home }}/.ssh/id_* {{ user.home }}/.ssh/config 2>/dev/null || true
    chmod 644 {{ user.home }}/.ssh/*.pub 2>/dev/null || true
  become: true
  become_user: "{{ user.name }}"
  changed_when: false

- name: Fix GPG permissions
  file:
    path: "{{ user.home }}/.gnupg"
    state: directory
    owner: "{{ user.name }}"
    mode: '0700'
  become: true

- name: Fix GPG file permissions
  shell: |
    chmod 600 {{ user.home }}/.gnupg/* 2>/dev/null || true
  become: true
  become_user: "{{ user.name }}"
  changed_when: false
```

**Settings (group_vars/all/settings.yml):**
```yaml
# Restic backup configuration
restic_backup:
  bucket: "your-b2-bucket"
  repo: "your-repo-name"

# Whether to restore keys from backup during bootstrap
restore_from_backup: false  # Set to true to enable
```

**Secrets (group_vars/all/vault.yml):**
```yaml
# Restic backup credentials
vault_restic_password: "your-restic-password"
vault_b2_account_id: "your-b2-account-id"
vault_b2_account_key: "your-b2-account-key"
```

### Option 3: Just Command (Quick Access)

Add to justfile:

```justfile
# Restore SSH and GPG keys from restic backup
restore-keys:
    #!/usr/bin/env bash
    echo "Restoring keys from restic backup..."
    read -sp "Restic password: " RESTIC_PASSWORD
    echo ""
    export RESTIC_PASSWORD
    export B2_ACCOUNT_ID=$(op read "op://Private/B2/account_id")
    export B2_ACCOUNT_KEY=$(op read "op://Private/B2/account_key")

    restic -r b2:your-bucket:/repo restore latest \
      --target / \
      --include ~/.ssh \
      --include ~/.gnupg

    chmod 700 ~/.ssh ~/.gnupg
    chmod 600 ~/.ssh/* ~/.gnupg/*
    chmod 644 ~/.ssh/*.pub
    echo "✓ Keys restored and permissions fixed"

# Restore all dotfiles from backup
restore-dotfiles:
    #!/usr/bin/env bash
    echo "Restoring all dotfiles from restic backup..."
    read -sp "Restic password: " RESTIC_PASSWORD
    echo ""
    export RESTIC_PASSWORD
    export B2_ACCOUNT_ID=$(op read "op://Private/B2/account_id")
    export B2_ACCOUNT_KEY=$(op read "op://Private/B2/account_key")

    restic -r b2:your-bucket:/repo restore latest \
      --target / \
      --include ~/.ssh \
      --include ~/.gnupg \
      --include ~/.config \
      --include ~/.local

    echo "✓ Dotfiles restored"
    just fix-permissions
```

## Recommended Workflow

### Initial Setup (First Machine)
```bash
# 1. Setup normally, keys exist on this machine
# 2. Configure restic/autorestic backup
# 3. Backup includes ~/.ssh and ~/.gnupg
# 4. Keys are now safely backed up to B2
```

### New Machine Bootstrap
```bash
# Option A: Manual (simplest)
./bootstrap.sh
sudo apt install restic
# Enter B2 credentials manually
restic -r b2:bucket:/repo restore latest --target / --include ~/.ssh --include ~/.gnupg
chmod 700 ~/.ssh ~/.gnupg && chmod 600 ~/.ssh/* ~/.gnupg/*
just system

# Option B: With justfile
./bootstrap.sh
just restore-keys  # Prompts for restic password, uses 1Password for B2 creds
just system

# Option C: Fully automated
./bootstrap.sh
# Edit settings.yml: restore_from_backup: true
just system  # Ansible restores keys automatically
```

## Integration with Existing Backup

### If you already backup ~/.ssh and ~/.gnupg

**Nothing to change!** Just restore them:

```bash
# Restore specific snapshot
restic -r b2:bucket:/repo snapshots
restic -r b2:bucket:/repo restore <snapshot-id> \
  --target / \
  --include ~/.ssh \
  --include ~/.gnupg
```

### If you don't backup keys yet

**Add to autorestic config:**

```yaml
# .autorestic.yml
locations:
  home:
    from: /home/dustin
    to:
      - b2
    options:
      backup:
        exclude:
          # Exclude large files
          - '.cache'
          - 'Downloads'
        # Make sure these are included
        include:
          - '.ssh'
          - '.gnupg'
          - '.config'
```

## Security Considerations

### ✅ Benefits
- Keys encrypted at rest in B2
- Restic encryption layer
- No keys in git (even encrypted)
- Natural DR workflow
- Works for all secrets/dotfiles

### 🔒 Security
- Restic password needed to decrypt
- B2 credentials needed to access
- Both stored in 1Password
- Ansible can automate with vault credentials

## Enhanced Bootstrap Script

```bash
# scripts/bootstrap.sh (add section)

echo ""
echo "Key Restoration Options:"
echo "1) Restore from restic backup (recommended)"
echo "2) Skip (keys will be managed later)"
echo "3) Retrieve from 1Password"
read -p "Choice [1]: " key_choice
key_choice=${key_choice:-1}

case $key_choice in
    1)
        echo "Installing restic..."
        sudo apt install -y restic

        echo "Enter your B2 credentials:"
        read -p "B2 Account ID: " B2_ACCOUNT_ID
        read -sp "B2 Account Key: " B2_ACCOUNT_KEY
        echo ""
        read -sp "Restic Password: " RESTIC_PASSWORD
        echo ""
        read -p "B2 Bucket: " B2_BUCKET
        read -p "Repo Name: " REPO_NAME

        export RESTIC_PASSWORD B2_ACCOUNT_ID B2_ACCOUNT_KEY

        echo "Restoring keys from backup..."
        restic -r b2:$B2_BUCKET:/$REPO_NAME restore latest \
          --target / \
          --include $HOME/.ssh \
          --include $HOME/.gnupg

        echo "Fixing permissions..."
        chmod 700 ~/.ssh ~/.gnupg
        chmod 600 ~/.ssh/* ~/.gnupg/* 2>/dev/null || true
        chmod 644 ~/.ssh/*.pub 2>/dev/null || true

        echo "✓ Keys restored from backup"
        ;;
    2)
        echo "Skipping key restoration"
        ;;
    3)
        # Existing 1Password logic
        ;;
esac
```

## Comparison: Restic vs 1Password vs Ansible Vault

| Method | Pros | Cons | Best For |
|--------|------|------|----------|
| **Restic** | Already setup, encrypted, all dotfiles | Requires B2 credentials | You! (recommended) |
| **1Password** | Easy access, GUI, team sharing | Per-item management | Quick lookups |
| **Ansible Vault** | In git, version controlled | Key duplication | Config as code |

## Recommendation for You

**Use Restic as primary method:**

1. **Bootstrap**: Restore keys from restic backup
2. **Ongoing**: Let Ansible manage permissions/config
3. **Backup**: Autorestic handles ongoing backups
4. **Emergency**: 1Password as secondary backup

This leverages your existing infrastructure and keeps things simple!

Would you like me to implement the restic restoration approach?
