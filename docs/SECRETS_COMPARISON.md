# Ansible Vault vs Git-Crypt: Which Should You Use?

## TL;DR Recommendation

**For this project: Start with Ansible Vault, consider Git-Crypt if you need transparent file access.**

## Quick Comparison

| Feature | Ansible Vault | Git-Crypt | Winner |
|---------|---------------|-----------|--------|
| Ansible Integration | ✅ Native | ⚠️ Manual | Ansible Vault |
| Transparent Encryption | ❌ No | ✅ Yes | Git-Crypt |
| File-Level Encryption | ❌ No (entire file) | ✅ Yes | Git-Crypt |
| Setup Complexity | ✅ Simple | ⚠️ Moderate | Ansible Vault |
| Team Onboarding | ✅ Easy | ⚠️ Complex | Ansible Vault |
| GPG Dependency | ❌ No | ✅ Yes | Ansible Vault |
| Selective Encryption | ✅ Per file | ✅ Per file | Tie |
| Commit Safety | ⚠️ Manual | ✅ Automatic | Git-Crypt |
| Portability | ✅ Python only | ⚠️ Needs GPG | Ansible Vault |

## Detailed Comparison

### Ansible Vault

**How it works:**
- Encrypts entire YAML files
- Uses symmetric encryption (single password)
- Files stored encrypted in git
- Ansible decrypts automatically during playbook runs
- Manual edit with `ansible-vault edit`

**Pros:**
- ✅ **Native Ansible integration** - works seamlessly
- ✅ **Simple setup** - just one password
- ✅ **No external dependencies** - pure Python
- ✅ **Easy team sharing** - single password in 1Password
- ✅ **Granular file encryption** - encrypt only what needs it
- ✅ **No GPG key management** - simpler workflow

**Cons:**
- ❌ **Not transparent** - need `ansible-vault edit` to view/edit
- ❌ **Entire file encrypted** - can't see structure
- ❌ **Git diffs useless** - just see encrypted blob changes
- ❌ **Risk of accidental commit** - could commit unencrypted
- ❌ **Manual encryption** - must remember to encrypt

**Best For:**
- Ansible-focused workflows
- Teams wanting simple setup
- Projects with few secrets
- When you don't need to frequently view secrets

### Git-Crypt

**How it works:**
- Transparent file encryption using GPG
- Files appear unencrypted in working directory
- Automatically encrypted on commit
- Automatically decrypted on checkout
- Uses `.gitattributes` to define what to encrypt

**Pros:**
- ✅ **Transparent** - files appear normal locally
- ✅ **Automatic encryption** - can't forget to encrypt
- ✅ **Git-aware** - proper diffs on encrypted content
- ✅ **File-level granularity** - encrypt individual files
- ✅ **Safety** - impossible to commit unencrypted
- ✅ **Any file type** - not just YAML

**Cons:**
- ❌ **GPG dependency** - more complex setup
- ❌ **Team complexity** - each person needs GPG key
- ❌ **Key management** - distributing/revoking keys harder
- ❌ **No Ansible integration** - Ansible doesn't know about it
- ❌ **Bootstrap complexity** - need GPG before cloning
- ❌ **Not portable** - requires git-crypt installed

**Best For:**
- Multiple secret files
- Teams comfortable with GPG
- Need transparent file access
- Want protection from accidental exposure

## Hybrid Approach

You can use BOTH! Here's how:

### Strategy

1. **Git-Crypt** for files you access frequently:
   - SSH configs
   - Environment files
   - Certificates

2. **Ansible Vault** for Ansible-specific secrets:
   - `group_vars/all/vault.yml`
   - Host-specific secrets
   - Passwords/tokens used by Ansible

### Setup

```bash
# 1. Install git-crypt
apt install git-crypt

# 2. Initialize git-crypt
cd /path/to/repo
git-crypt init

# 3. Export key for team
git-crypt export-key ~/.config/desktoperator-git-crypt.key

# 4. Define what to encrypt (.gitattributes)
cat >> .gitattributes << EOF
# Git-crypt patterns
files/home/.ssh/config filter=git-crypt diff=git-crypt
files/home/.ssh/id_* filter=git-crypt diff=git-crypt
*.env filter=git-crypt diff=git-crypt
*.pem filter=git-crypt diff=git-crypt

# Ansible Vault files (handled by ansible-vault, not git-crypt)
vault.yml !filter !diff
EOF

# 5. Add to git
git add .gitattributes
git commit -m "Setup git-crypt"
```

### Team Onboarding (Hybrid)

**New team member:**

```bash
# 1. Clone repo (files are encrypted)
git clone ...
cd desktoperator

# 2. Get git-crypt key from 1Password
op read "op://Private/Git-Crypt Key/file" > ~/.config/desktoperator-git-crypt.key

# 3. Unlock git-crypt
git-crypt unlock ~/.config/desktoperator-git-crypt.key

# 4. Setup Ansible vault
just secure-setup  # Enter vault password

# Now both git-crypt and ansible-vault files are accessible!
```

## Recommendation for Your Project

### Use Ansible Vault If:
- ✅ You're primarily doing Ansible automation
- ✅ You want simplest setup
- ✅ Team is comfortable with password management
- ✅ You don't need frequent manual file access
- ✅ You want minimal dependencies

**This is what we've implemented!**

### Use Git-Crypt If:
- ✅ You have many config files with secrets
- ✅ Team is comfortable with GPG
- ✅ You need transparent file access
- ✅ You want automatic encryption guarantees
- ✅ You access secrets outside Ansible often

### Use Both If:
- ✅ You want best of both worlds
- ✅ You have diverse secret types
- ✅ Team can handle slightly more complexity
- ✅ You want maximum protection

## Migration Path

If you decide to switch later:

### Ansible Vault → Git-Crypt

```bash
# 1. Decrypt ansible vault files
ansible-vault decrypt group_vars/all/vault.yml

# 2. Setup git-crypt
git-crypt init
cat >> .gitattributes << EOF
vault.yml filter=git-crypt diff=git-crypt
EOF

# 3. Commit (git-crypt encrypts automatically)
git add vault.yml .gitattributes
git commit -m "Switch to git-crypt"

# 4. Update justfile commands
# Replace ansible-vault commands with standard file operations
```

### Git-Crypt → Ansible Vault

```bash
# 1. Files are already plaintext (to you)
# 2. Remove from git-crypt
cat >> .gitattributes << EOF
vault.yml !filter !diff
EOF

# 3. Encrypt with ansible-vault
ansible-vault encrypt group_vars/all/vault.yml

# 4. Commit
git add vault.yml .gitattributes
git commit -m "Switch to ansible-vault"
```

## Security Considerations

### Ansible Vault Security

**Risks:**
- Accidental commit of unencrypted file
- Vault password in `.vault_pass` file
- Must remember to encrypt

**Mitigations:**
- Pre-commit hooks (`just check-git`)
- `.gitignore` protects `.vault_pass`
- Training/documentation

### Git-Crypt Security

**Risks:**
- GPG key compromise affects all repos
- More complex key distribution
- Team member leaving requires key rotation

**Mitigations:**
- Separate GPG key per project
- Store key in 1Password
- Regular key rotation policy

## My Recommendation

**For Desktop Operator: Keep Ansible Vault**

**Why:**
1. **Simplicity** - easier for you to manage alone or with small team
2. **Ansible-native** - perfect integration with your workflow
3. **Fewer dependencies** - no GPG setup needed
4. **Quick bootstrap** - 1Password integration works great
5. **Sufficient security** - with proper pre-commit hooks

**Consider adding Git-Crypt later if:**
- You add many non-Ansible secret files
- Team grows beyond 2-3 people
- You need transparent access to configs
- You're accessing secrets outside Ansible frequently

## Implementation Status

**Currently Implemented: Ansible Vault ✅**

If you want to add Git-Crypt, I can:
1. Install and configure git-crypt
2. Create `.gitattributes` patterns
3. Update documentation
4. Create hybrid workflow

**Would you like me to implement git-crypt as well, or are you happy with Ansible Vault?**
