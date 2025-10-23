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

**→ See [Getting Started Guide](extras/docs/getting-started.md) for complete instructions**

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

**Getting Started & Architecture:**
- [Getting Started Guide](extras/docs/getting-started.md) - Complete setup walkthrough
- [Ansible Architecture](extras/docs/ansible-architecture.md) - Role and inventory layout
- [Scripts Reference](extras/docs/scripts.md) - All utility scripts explained

**Desktop & Themes:**
- [COSMIC Desktop Management](extras/docs/cosmic-desktop.md) - Managing COSMIC configuration
- [Theme Generation](extras/docs/theme-generation.md) - Auto-generate app themes from COSMIC

**Security & Secrets:**
- [Security Best Practices](extras/docs/security.md) - Security guidelines
- [1Password Setup](extras/docs/1password-setup.md) - 1Password integration
- [Password Handling](extras/docs/password-handling.md) - Credential management
- [Vault Key Management](extras/docs/vault-key-management.md) - Ansible Vault encryption

**Operations & Reference:**
- [Version Management](extras/docs/version-management.md) - Application versions

## Contributing

When adding roles/apps:
1. Follow existing patterns
2. Support `state` parameter (install/uninstall)
3. Add appropriate tags
4. Document in role's README.md

## License

See LICENSE file.
