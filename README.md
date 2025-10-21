# Desktop Operator

Ansible-based configuration management for Ubuntu desktop systems.

## What is This?

Automate your Ubuntu desktop setup. Define configuration once in YAML, apply consistently across all machines.

**Key Features:**
- 🔒 Secure secrets (Ansible Vault + 1Password)
- 🖥️ Multi-host with host-specific overrides
- 📦 Smart package management (.deb → Flatpak → Snap)
- ⚡ Fast targeted execution via tags
- 🚀 One-command bootstrap
- 🎨 Full COSMIC desktop management

## Quick Start

### Fresh System Setup

```bash
# 1. Run bootstrap
curl -O https://raw.githubusercontent.com/bashfulrobot/desktoperator/main/scripts/bootstrap.sh
chmod +x bootstrap.sh
./bootstrap.sh

# 2. Navigate to repo
cd ~/dev/iac/desktoperator

# 3. Apply configuration
just run
```

**→ See [Getting Started Guide](docs/GETTING_STARTED.md) for complete instructions**

### Daily Operations

After initial setup, use `jsys` for all management:

```bash
# System updates
jsys update-all

# Re-apply Ansible configuration
jsys update-ansible

# COSMIC desktop
jsys cosmic-capture          # Save current settings
jsys cosmic-apply            # Apply settings

# Theme generation
jsys generate-cosmic-colors  # Extract COSMIC colors
jsys generate-theme-files    # Generate VSCode/Vivaldi themes
jsys app vscode              # Deploy theme to VSCode
```

**→ See [Justfile Architecture](docs/justfile-architecture.md) for the three-tier command system**

### Making Changes

```bash
# 1. Edit settings
vim group_vars/all/settings.yml

# 2. Preview changes
just check

# 3. Apply
just run

# 4. Commit
just -f justfiles/git commit
```

### Repository Operations

```bash
# From the repository (bootstrap/dev only)
just --list                  # See all commands
just bootstrap               # Initial Ansible setup
just check                   # Dry run
just run                     # Apply configuration

# Specialized workflows
just -f justfiles/security --list
just -f justfiles/git --list
just -f justfiles/maintenance --list
```

## Documentation

**Getting Started:**
- [Getting Started Guide](docs/GETTING_STARTED.md) - Complete setup walkthrough
- [Scripts Reference](docs/SCRIPTS.md) - All utility scripts explained
- [Justfile Architecture](docs/justfile-architecture.md) - Command system structure

**Desktop & Themes:**
- [COSMIC Desktop Management](docs/COSMIC_DESKTOP.md) - Managing COSMIC configuration
- [Theme Generation](docs/THEME_GENERATION.md) - Auto-generate app themes from COSMIC

**Security:**
- [Security Best Practices](docs/SECURITY.md) - Security guidelines
- [1Password Setup](docs/1PASSWORD_SETUP.md) - 1Password integration
- [Password Handling](docs/PASSWORD_HANDLING.md) - Credential management
- [Vault Key Management](docs/VAULT_KEY_MANAGEMENT.md) - Ansible Vault encryption
- [Key Management](docs/KEY_MANAGEMENT.md) - SSH and GPG keys
- [Key Restore Strategy](docs/KEY_RESTORE_STRATEGY.md) - Disaster recovery

**System Architecture:**
- [Tagging](docs/tagging.md) - Selective execution with tags
- [Version Management](docs/version-management.md) - Application versions
- [Secrets Comparison](docs/SECRETS_COMPARISON.md) - Secret management approaches

**Other:**
- [TODO](TODO.md) - Planned enhancements
- [Directory Structure](STRUCTURE.md) - Project layout
- [Nix to Ansible Mapping](docs/NIX_TO_ANSIBLE_MAPPING.md) - For Nix users
- [Zen Browser Integration](docs/ZEN_BROWSER_COSMIC_INTEGRATION.md) - Zen Browser config

## Contributing

When adding roles/apps:
1. Follow existing patterns
2. Support `state` parameter (install/uninstall)
3. Add appropriate tags
4. Document in role's README.md

## License

See LICENSE file.
