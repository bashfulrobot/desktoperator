# Desktop Operator

Modern Ansible-based configuration management for Ubuntu desktop systems.

## What is This?

Desktop Operator automates the setup and configuration of Ubuntu desktop systems using Ansible. Define your system configuration once in YAML, then apply it consistently across all your machines.

**Key Features:**
- 🔒 Secure secrets management (Ansible Vault + 1Password)
- 🖥️  Multi-host support with host-specific overrides
- 📦 Smart package management (.deb → Flatpak → Snap)
- ⚡ Fast targeted execution via tags
- 🚀 Simple bootstrap for fresh systems

**→ See [Getting Started Guide](docs/GETTING_STARTED.md) for detailed setup instructions**

## Quick Start Cheatsheet

### 🚀 Fresh Ubuntu System → Fully Configured

**Step 1: Run Bootstrap Script**
```bash
# Download and run bootstrap
curl -O https://raw.githubusercontent.com/bashfulrobot/desktoperator/main/scripts/bootstrap.sh
chmod +x bootstrap.sh
./bootstrap.sh
```

**What happens during bootstrap:**
```
Desktop Operator Bootstrap
==========================

Updating package list...
Installing minimal dependencies...
Installing Ansible...
Installing 1Password CLI...
Installing restic and autorestic...

Cloning desktoperator repository to ~/dev/iac/desktoperator...

Retrieving vault password from 1Password...
You will need to authenticate to 1Password CLI.

[PROMPT] Enter your 1Password account: you@example.com
[PROMPT] Enter your password: ********
[PROMPT] Enter your secret key: XX-XXXXXX-XXXXXX-XXXXX-XXXXX-XXXXX-XXXXX

✓ Vault password saved to .vault_pass (permissions: 600)

Restic/Autorestic Configuration
================================
Would you like to configure restic backup now?
This will create the autorestic configuration file.
You can also do this later with Ansible.

[PROMPT] Configure restic now? [y/N]: y

Retrieving B2 credentials from 1Password...
✓ Autorestic configuration created

Next steps for restic:
  1. Initialize repository: autorestic exec -a -- init
  2. Create first backup: autorestic backup -a
  3. Ansible will manage the configuration going forward

Creating initial vault file...
Please edit group_vars/all/vault.yml with your actual secrets, then we'll encrypt it.
[PROMPT] Press Enter when you've added your secrets to vault.yml...

[PROMPT] New Vault password: ********
[PROMPT] Confirm New Vault password: ********
Encryption successful
✓ Vault file encrypted and secured (permissions: 600)

Checking for accidentally staged sensitive files...
✓ No sensitive files detected in git staging

==================================
Bootstrap Complete!
==================================

Security Checklist:
✓ .vault_pass created (600 permissions)
✓ vault.yml encrypted (600 permissions)
✓ Sensitive files protected by .gitignore

Next steps:
1. Review inventory/hosts.yml
2. Run: just run
```

**Step 2: Navigate to Repo**
```bash
cd ~/dev/iac/desktoperator
```

**Step 3: Review Configuration (First Time Only)**
```bash
# Check your hostname
hostname

# Verify your host exists in inventory
cat inventory/hosts.yml

# Review central settings
less group_vars/all/settings.yml

# Review host-specific settings
less inventory/host_vars/$(hostname).yml
```

**Step 4: First Ansible Run**
```bash
# Full configuration (all roles, all tasks)
just run
```

**What happens during `just run`:**
```
PLAY [all] *********************************************************************

TASK [Gathering Facts] *********************************************************
ok: [poptop]

TASK [system : Create user] ****************************************************
changed: [poptop]

TASK [system : Add user to groups] *********************************************
changed: [poptop]

TASK [system : Configure NOPASSWD sudo] ****************************************
changed: [poptop]

TASK [system : Install fish shell] *********************************************
changed: [poptop]

TASK [system : Deploy fish config] *********************************************
changed: [poptop]

TASK [system : Set fish as default shell] **************************************
changed: [poptop]

TASK [system : Deploy SSH keys] ************************************************
changed: [poptop]

TASK [system : Import GPG keys] ************************************************
changed: [poptop]

TASK [apps : Install 1Password] ************************************************
changed: [poptop]

TASK [apps : Install Firefox] **************************************************
changed: [poptop]

TASK [apps : Install restic] ***************************************************
changed: [poptop]

TASK [apps : Deploy autorestic config] *****************************************
changed: [poptop]

TASK [apps : Deploy restic scripts] ********************************************
changed: [poptop]

TASK [apps : Enable autorestic timer] ******************************************
changed: [poptop]

TASK [apps : Install zellij] ***************************************************
changed: [poptop]

TASK [apps : Deploy zellij config] *********************************************
changed: [poptop]

PLAY RECAP *********************************************************************
poptop                     : ok=17   changed=16   unreachable=0    failed=0
```

**Summary of changes:**
- ✓ User configured with groups (sudo, docker, audio, video, plugdev)
- ✓ NOPASSWD sudo enabled
- ✓ Fish shell installed and configured
- ✓ SSH and GPG keys deployed
- ✓ Firewall configured
- ✓ Applications installed: 1Password, Firefox, Restic, Zellij
- ✓ All configs deployed
- ✓ Systemd timer enabled (restic backup at 2 AM)

**Step 5: Post-Setup Tasks**
```bash
# Initialize restic backup (first time only)
restic-init

# Create first backup
restic-backup quick

# Check backup status
restic-status

# Verify systemd timer is running
systemctl --user status autorestic-backup.timer
```

**Done!** 🎉 Your system is now fully configured and will automatically backup nightly.

---

### 📋 Subsequent Ansible Runs

After the initial setup, use targeted commands for faster runs:

```bash
# Full run (use sparingly - takes longer)
just run

# Targeted runs (much faster)
just system          # Only system config (users, shell, ssh, gpg)
just apps            # Only applications
just app firefox     # Single application

# Check what would change (dry run)
just check
```

---

### 🔄 Making Configuration Changes

```bash
# 1. Edit settings
vim group_vars/all/settings.yml

# 2. Test changes (dry run)
just check

# 3. Apply changes
just run    # or targeted: just system, just apps, etc.

# 4. Commit safely (encrypts vaults, runs security checks)
just commit

# 5. Pull changes on other hosts
# (Run on each host to pull latest config and apply)
just pull
```

---

## Common Commands

**Day-to-day operations:**
```bash
just run              # Apply full configuration
just check            # Dry run preview
just system           # Only system config
just apps             # Only applications
just install firefox  # Install single app
just commit           # Safe commit with security checks
just pull             # Pull and apply latest config
```

**Run `just` to see all available commands**

**Periodic tasks:**
```bash
just -f justfiles/maintenance run           # System updates
just -f justfiles/security vault-edit       # Edit secrets
just -f justfiles/git status                # Git status with vault info
```

**→ See [Common Tasks Reference](docs/GETTING_STARTED.md#common-tasks) for complete command list**

## Documentation

For detailed information on specific topics, see the documentation in the `docs/` directory:

### Setup & Configuration
- **[Getting Started Guide](docs/GETTING_STARTED.md)** - Complete setup instructions for first-time and additional machines
- **[1Password Setup](docs/1PASSWORD_SETUP.md)** - Configuring 1Password integration for secrets management

### Security & Secrets
- **[Security Best Practices](docs/SECURITY.md)** - Security guidelines and threat model
- **[Password Handling](docs/PASSWORD_HANDLING.md)** - How passwords and credentials are managed
- **[Secrets Comparison](docs/SECRETS_COMPARISON.md)** - Comparison of different secret management approaches
- **[Vault Key Management](docs/VAULT_KEY_MANAGEMENT.md)** - Managing Ansible Vault encryption keys
- **[Key Management](docs/KEY_MANAGEMENT.md)** - SSH and GPG key management
- **[Key Restore Strategy](docs/KEY_RESTORE_STRATEGY.md)** - How to recover keys in disaster scenarios

### Other
- **[Nix to Ansible Mapping](docs/NIX_TO_ANSIBLE_MAPPING.md)** - Translation guide for Nix users migrating to Ansible
- **[Zen Browser Cosmic Integration](docs/ZEN_BROWSER_COSMIC_INTEGRATION.md)** - Zen Browser configuration for COSMIC desktop

## Contributing

When adding new roles or applications:

1. Create role structure following existing patterns
2. Include both install and config in the role
3. Support `state` parameter for install/uninstall
4. Add appropriate tags
5. Document in role's README.md
6. Update main playbook if needed

## License

See LICENSE file.

## Support

For issues or questions, open an issue in the GitHub repository.
