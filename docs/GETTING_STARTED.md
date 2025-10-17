# Getting Started with Desktop Operator

## Two Scenarios

### Scenario A: First-Time Setup (Fresh Repo)

You're setting up Desktop Operator for the first time.

```bash
# 1. Clone the repo
git clone https://github.com/bashfulrobot/desktoperator.git
cd desktoperator

# 2. Install just (if not installed)
curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to ~/bin

# 3. Run secure setup
just secure-setup
# - Choose vault password option (manual/generate/1Password)
# - Edit vault.yml with your actual secrets
# - Script encrypts vault.yml automatically

# 4. Review and customize settings
vim group_vars/all/settings.yml
vim inventory/hosts.yml

# 5. Commit encrypted vault (this is safe!)
just commit

# 6. Bootstrap current machine
just bootstrap-ask $(hostname)  # Use -ask if no NOPASSWD sudo yet

# 7. Apply full configuration
just all

# Done! Now iterate and commit with `just commit`
```

### Scenario B: New Machine (Repo Already Setup)

You already have Desktop Operator configured, and want to set up a new machine.

**On the new machine:**

```bash
# 1. Download bootstrap script
curl -O https://raw.githubusercontent.com/bashfulrobot/desktoperator/main/scripts/bootstrap.sh
chmod +x bootstrap.sh

# 2. Run bootstrap (installs Ansible, clones repo, gets vault password)
# Default location: ~/dev/iac/desktoperator
# To customize: export DESKTOPERATOR_DIR=/path/to/repo
./bootstrap.sh
# - Installs Ansible and dependencies
# - Installs 1Password CLI
# - Clones your repo (with encrypted vault.yml)
# - Authenticates to 1Password
# - Retrieves vault password → creates .vault_pass
# - Now Ansible can decrypt vault.yml

# 3. Change to repo directory
cd ~/dev/iac/desktoperator

# 4. Install just (if not installed)
curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to ~/bin
export PATH="$HOME/bin:$PATH"

# 5. Review inventory (add this host if needed)
vim inventory/hosts.yml
# Add your new machine to the inventory

# 6. Bootstrap this machine
just bootstrap-ask $(hostname)  # First time needs -ask for sudo password

# 7. Apply full configuration
just all

# Done! This machine is now fully configured
```

## Quick Reference

### First Machine (One-Time Setup)
```bash
git clone ...
just secure-setup    # Create secrets
just commit          # Commit encrypted vault
just bootstrap-ask   # Setup machine
just all            # Apply config
```

### Additional Machines
```bash
./bootstrap.sh       # Download and run from GitHub
cd ~/dev/iac/desktoperator
just bootstrap-ask   # Setup machine
just all            # Apply config
```

### Daily Workflow (Any Machine)
```bash
vim group_vars/all/settings.yml  # Make changes
just check                        # Dry run
just host <hostname>              # Test on one host
just commit                       # Safe commit with encryption check
```

## Verification Steps

### After Bootstrap

```bash
# Check Ansible works
ansible --version

# Check vault password
ls -la .vault_pass  # Should be 600 permissions

# Check vault is encrypted
head -1 group_vars/all/vault.yml  # Should show $ANSIBLE_VAULT

# Check inventory
just hosts

# Test connectivity
just ping
```

### After Configuration

```bash
# Verify no secrets leaked
just check-git

# Check all hosts are reachable
just ping

# Run syntax check
just syntax
```

## Troubleshooting

### "vault.yml doesn't exist"

**On first machine:**
```bash
just secure-setup  # Creates and encrypts vault.yml
```

**On additional machines:**
```bash
# Should not happen - bootstrap.sh clones repo with vault.yml
# If it does:
git pull origin main  # Get latest including vault.yml
```

### "no vault secrets found"

**Cause**: Missing `.vault_pass` file

**Solution:**
```bash
# Option 1: From 1Password
eval $(op signin)
op read "op://Private/Ansible Vault/password" > .vault_pass
chmod 600 .vault_pass

# Option 2: Re-run setup
just secure-setup
```

### "sudo password required"

**Cause**: NOPASSWD sudo not configured yet

**Solution**: Use `-ask` variant:
```bash
just bootstrap-ask $(hostname)
```

### "Can't decrypt vault.yml"

**Cause**: Wrong vault password in `.vault_pass`

**Solution:**
```bash
# Get correct password from 1Password
rm .vault_pass
just secure-setup  # Option 3: Retrieve from 1Password
```

## Next Steps

After setup:

1. **Customize for your needs**:
   - Edit `group_vars/all/settings.yml`
   - Add host-specific config in `host_vars/`
   - Create roles for your applications

2. **Add your first application**:
   - Create `roles/apps/myapp/tasks/main.yml`
   - Add to enabled apps in settings
   - Run `just app myapp`

3. **Read the docs**:
   - `docs/SECURITY.md` - Security best practices
   - `docs/PASSWORD_HANDLING.md` - Password management
   - `README.md` - Complete feature documentation

## Common First Tasks

### Add a New Application

```bash
# 1. Create role structure
mkdir -p roles/apps/myapp/{tasks,templates,files}

# 2. Create main tasks file
cat > roles/apps/myapp/tasks/main.yml << 'EOF'
---
- name: Install myapp
  apt:
    name: myapp
    state: present
EOF

# 3. Add to settings
vim group_vars/all/settings.yml
# Add 'myapp' to common_apps list

# 4. Test
just app myapp

# 5. Commit
just commit
```

### Add a New Host

```bash
# 1. Add to inventory
vim inventory/hosts.yml
# Add host under appropriate group

# 2. Create host vars (optional)
vim inventory/host_vars/newhost.yml

# 3. Test connectivity
just ping-host newhost

# 4. Bootstrap it
just bootstrap newhost

# 5. Apply config
just host newhost

# 6. Commit changes
just commit
```

### Update Secrets

```bash
# 1. Edit vault
just vault-edit

# 2. Make changes to secrets

# 3. Save and exit (ansible-vault encrypts automatically)

# 4. Apply to hosts
just all

# 5. Commit
just commit
```

## Important Files

| File | Purpose | Committed? |
|------|---------|-----------|
| `.vault_pass` | Vault password (plaintext) | ❌ Never |
| `group_vars/all/vault.yml` | Secrets (encrypted) | ✅ Yes (encrypted) |
| `group_vars/all/vault.yml.example` | Template (dummy data) | ✅ Yes |
| `group_vars/all/settings.yml` | Non-secret config | ✅ Yes |
| `inventory/hosts.yml` | Host inventory | ✅ Yes |

## Success Indicators

You know setup worked when:

- ✅ `ansible --version` shows version
- ✅ `just --version` works
- ✅ `.vault_pass` exists with 600 permissions
- ✅ `just vault-view` shows your secrets
- ✅ `just ping` reaches all hosts
- ✅ `just check-git` passes
- ✅ `just check` runs without errors

Now you're ready to manage your infrastructure! 🚀
