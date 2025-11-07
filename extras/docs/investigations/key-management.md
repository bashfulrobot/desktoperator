# SSH & GPG Key Management Strategy

## The Challenge

We need to:
- ✅ Deploy SSH/GPG keys to systems
- ✅ Keep keys secure (not leaked to git)
- ✅ Make bootstrap easy
- ✅ Support multiple machines

## Recommended Strategy: 1Password + Ansible Vault

### Option 1: Store Keys in 1Password (Recommended)

**Best for**: Personal systems, small teams, easy management

#### Setup

1. **Store keys in 1Password**
   - Create items for each key
   - Store private key content
   - Store public key content

2. **Bootstrap retrieves keys**
   ```bash
   # In bootstrap or initial setup
   op read "op://Private/SSH GitHub/private key" > ~/.ssh/github
   op read "op://Private/GPG Key/private key" | gpg --import
   ```

3. **Ansible manages ongoing updates**
   - Keys stored in encrypted `vault.yml`
   - Deployed via Ansible tasks

#### Implementation

**Store in vault.yml:**
```yaml
# group_vars/all/vault.yml (encrypted)
vault_ssh_keys:
  github:
    private: |
      -----BEGIN OPENSSH PRIVATE KEY-----
      ...
      -----END OPENSSH PRIVATE KEY-----
    public: "ssh-ed25519 AAAA... user@host"

  gitlab:
    private: |
      -----BEGIN OPENSSH PRIVATE KEY-----
      ...
      -----END OPENSSH PRIVATE KEY-----
    public: "ssh-ed25519 AAAA... user@host"

vault_gpg_key: |
  -----BEGIN PGP PRIVATE KEY BLOCK-----
  ...
  -----END PGP PRIVATE KEY BLOCK-----
```

**Deploy with Ansible:**
```yaml
# roles/system/tasks/ssh.yml
- name: Deploy SSH private keys
  copy:
    content: "{{ item.value.private }}"
    dest: "{{ user.home }}/.ssh/{{ item.key }}"
    owner: "{{ user.name }}"
    mode: '0600'
  loop: "{{ vault_ssh_keys | dict2items }}"
  no_log: true

- name: Deploy SSH public keys
  copy:
    content: "{{ item.value.public }}"
    dest: "{{ user.home }}/.ssh/{{ item.key }}.pub"
    owner: "{{ user.name }}"
    mode: '0644'
  loop: "{{ vault_ssh_keys | dict2items }}"
```

**Pros:**
- ✅ Keys encrypted in vault.yml (can be committed)
- ✅ 1Password as source of truth
- ✅ Easy to bootstrap new machines
- ✅ Centrally managed
- ✅ No manual file copying

**Cons:**
- ⚠️ Keys duplicated (1Password + vault.yml)
- ⚠️ Must manually update vault.yml when rotating keys

### Option 2: 1Password Only (No Vault Storage)

**Best for**: Maximum security, single user

#### Implementation

**Bootstrap script:**
```bash
# scripts/bootstrap.sh
echo "Retrieving SSH keys from 1Password..."
op read "op://Private/SSH GitHub/private key" > ~/.ssh/github
chmod 600 ~/.ssh/github

op read "op://Private/SSH GitHub/public key" > ~/.ssh/github.pub
chmod 644 ~/.ssh/github.pub

echo "Retrieving GPG key from 1Password..."
op read "op://Private/GPG Key/private key" | gpg --import
```

**Ansible role (one-time setup):**
```yaml
# roles/system/tasks/keys-from-1password.yml
- name: Check if 1Password CLI is available
  command: which op
  register: op_cli
  failed_when: false
  changed_when: false

- name: Retrieve SSH keys from 1Password
  shell: |
    op read "op://Private/SSH {{ item }}/private key" > {{ user.home }}/.ssh/{{ item }}
    chmod 600 {{ user.home }}/.ssh/{{ item }}
    op read "op://Private/SSH {{ item }}/public key" > {{ user.home }}/.ssh/{{ item }}.pub
    chmod 644 {{ user.home }}/.ssh/{{ item }}.pub
  loop:
    - github
    - gitlab
  when: op_cli.rc == 0
  become: true
  become_user: "{{ user.name }}"
```

**Pros:**
- ✅ Single source of truth (1Password only)
- ✅ No key duplication
- ✅ Keys never in git (even encrypted)
- ✅ Automatic key rotation sync

**Cons:**
- ⚠️ Requires 1Password CLI on all systems
- ⚠️ Requires auth to 1Password during Ansible runs
- ⚠️ Can't run Ansible offline

### Option 3: Hybrid Approach (Recommended for Teams)

**Best for**: Teams, multiple maintainers, mixed environments

Use **Option 1** (Ansible Vault) as primary, with **Option 2** (1Password) for bootstrap.

#### Workflow

**Initial Setup (maintainer):**
```bash
# 1. Generate or get keys
ssh-keygen -t ed25519 -f ~/.ssh/github

# 2. Store in 1Password
op item create \
  --category "Secure Note" \
  --title "SSH GitHub" \
  --vault "Private" \
  private_key="$(cat ~/.ssh/github)" \
  public_key="$(cat ~/.ssh/github.pub)"

# 3. Add to vault.yml
just vault-edit
# Paste keys into vault_ssh_keys

# 4. Commit encrypted vault
just commit
```

**Bootstrap New Machine:**
```bash
# 1. Run bootstrap (gets vault password from 1Password)
./bootstrap.sh

# 2. Ansible deploys keys from vault.yml
just system
```

**Key Rotation:**
```bash
# 1. Generate new key
ssh-keygen -t ed25519 -f ~/.ssh/github_new

# 2. Update 1Password
op item edit "SSH GitHub" private_key="$(cat ~/.ssh/github_new)"

# 3. Update vault.yml
just vault-edit
# Replace key

# 4. Deploy to all systems
just push-all
```

## Detailed Implementation

### 1. Update vault.yml.example

```yaml
# group_vars/all/vault.yml.example
vault_ssh_keys:
  github:
    private: |
      -----BEGIN OPENSSH PRIVATE KEY-----
      your-private-key-here
      -----END OPENSSH PRIVATE KEY-----
    public: "ssh-ed25519 AAAA... user@host"
    comment: "GitHub deployment key"

  personal:
    private: |
      -----BEGIN OPENSSH PRIVATE KEY-----
      your-private-key-here
      -----END OPENSSH PRIVATE KEY-----
    public: "ssh-ed25519 AAAA... user@host"
    comment: "Personal servers"

vault_gpg_key:
  private: |
    -----BEGIN PGP PRIVATE KEY BLOCK-----
    your-gpg-key-here
    -----END PGP PRIVATE KEY BLOCK-----
  public: |
    -----BEGIN PGP PUBLIC KEY BLOCK-----
    your-public-key-here
    -----END PGP PUBLIC KEY BLOCK-----
  fingerprint: "ABCD1234..."
```

### 2. Enhanced SSH Role

```yaml
# roles/system/tasks/ssh.yml
- name: Ensure .ssh directory exists
  file:
    path: "{{ user.home }}/.ssh"
    state: directory
    owner: "{{ user.name }}"
    mode: '0700'

- name: Deploy SSH private keys
  copy:
    content: "{{ item.value.private }}"
    dest: "{{ user.home }}/.ssh/{{ item.key }}"
    owner: "{{ user.name }}"
    mode: '0600'
  loop: "{{ vault_ssh_keys | dict2items }}"
  when: vault_ssh_keys is defined
  no_log: true

- name: Deploy SSH public keys
  copy:
    content: "{{ item.value.public }}"
    dest: "{{ user.home }}/.ssh/{{ item.key }}.pub"
    owner: "{{ user.name }}"
    mode: '0644'
  loop: "{{ vault_ssh_keys | dict2items }}"
  when: vault_ssh_keys is defined

- name: Deploy SSH config
  template:
    src: ssh_config.j2
    dest: "{{ user.home }}/.ssh/config"
    owner: "{{ user.name }}"
    mode: '0600'
```

### 3. SSH Config Template

```jinja2
# roles/system/templates/ssh_config.j2
# SSH Client Configuration
# Managed by Ansible

{% for key_name, key_data in vault_ssh_keys.items() %}
# {{ key_data.comment | default(key_name) }}
Host {{ key_name }}.com
    HostName {{ key_name }}.com
    User git
    IdentityFile {{ user.home }}/.ssh/{{ key_name }}
    IdentitiesOnly yes

{% endfor %}

# Default settings
Host *
    AddKeysToAgent yes
    UseKeychain yes
    ServerAliveInterval 60
    ServerAliveCountMax 3
```

### 4. Enhanced GPG Role

```yaml
# roles/system/tasks/gpg.yml
- name: Import GPG private key
  shell: |
    echo "{{ vault_gpg_key.private }}" | gpg --batch --import
  when: vault_gpg_key is defined
  become: true
  become_user: "{{ user.name }}"
  no_log: true
  register: gpg_import
  changed_when: "'imported' in gpg_import.stderr"

- name: Trust GPG key ultimately
  shell: |
    echo "{{ vault_gpg_key.fingerprint }}:6:" | gpg --import-ownertrust
  when: vault_gpg_key is defined and vault_gpg_key.fingerprint is defined
  become: true
  become_user: "{{ user.name }}"
  changed_when: false
```

### 5. Bootstrap Enhancement

```bash
# scripts/bootstrap.sh (add after vault password retrieval)

echo ""
echo "Setting up SSH and GPG keys..."
read -p "Retrieve keys from 1Password now? (Y/n): " setup_keys
if [[ ! "$setup_keys" =~ ^[Nn]$ ]]; then
    # SSH Keys
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh

    op read "op://Private/SSH GitHub/private key" > ~/.ssh/github 2>/dev/null && \
        chmod 600 ~/.ssh/github && \
        echo "✓ GitHub SSH key retrieved" || \
        echo "⚠️  GitHub SSH key not found in 1Password"

    # GPG Key
    op read "op://Private/GPG Key/private key" 2>/dev/null | gpg --batch --import && \
        echo "✓ GPG key imported" || \
        echo "⚠️  GPG key not found in 1Password"
else
    echo "Skipping key setup. Keys will be deployed by Ansible from vault.yml"
fi
```

## Security Best Practices

### DO:
- ✅ Use separate keys for different purposes (GitHub, GitLab, servers)
- ✅ Use ed25519 keys (modern, secure)
- ✅ Encrypt vault.yml before committing
- ✅ Set correct permissions (600 for private, 644 for public)
- ✅ Store keys in 1Password as backup
- ✅ Use `no_log: true` when handling keys in Ansible

### DON'T:
- ❌ Commit unencrypted keys
- ❌ Use same key everywhere
- ❌ Store keys in files/ directory
- ❌ Echo keys in scripts
- ❌ Use RSA keys (use ed25519 instead)

## Key Generation Commands

### SSH Key (Ed25519 - Recommended)
```bash
ssh-keygen -t ed25519 -C "your-email@example.com" -f ~/.ssh/keyname
```

### GPG Key
```bash
gpg --full-generate-key
# Export:
gpg --armor --export-secret-keys YOUR_KEY_ID > private.asc
gpg --armor --export YOUR_KEY_ID > public.asc
```

## Troubleshooting

### Keys not deploying
```bash
# Check vault is encrypted
head -1 group_vars/all/vault.yml

# Check vault contains keys
just vault-view | grep "vault_ssh_keys"

# Test deployment
just system --check
```

### Permission errors
```bash
# Fix SSH permissions
just fix-permissions

# Manual fix
chmod 700 ~/.ssh
chmod 600 ~/.ssh/*
chmod 644 ~/.ssh/*.pub
```

### GPG import issues
```bash
# Check GPG key format
gpg --import-options show-only --import < key.asc

# Test import
echo "key content" | gpg --batch --import
```

## Recommended: Use Option 3 (Hybrid)

For your use case, I recommend:

1. **Store keys in 1Password** (source of truth)
2. **Copy to vault.yml** (encrypted, in git)
3. **Bootstrap retrieves from 1Password** (quick setup)
4. **Ansible deploys from vault.yml** (normal operation)

This gives you:
- ✅ Easy bootstrap
- ✅ Version controlled (encrypted)
- ✅ No internet required after bootstrap
- ✅ 1Password as secure backup

Would you like me to implement this strategy?
