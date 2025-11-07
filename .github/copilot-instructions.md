# Copilot Instructions for Desktop Operator

This repository is an Ansible-based configuration management system for Ubuntu desktop systems. It automates desktop setup with a focus on security, modularity, and the COSMIC desktop environment.

## Project Overview

**Purpose:** Automate Ubuntu desktop configuration with secure secrets management, multi-host support, and COSMIC desktop integration.

**Tech Stack:**
- Ansible (configuration management)
- Just (command runner - 3-tier system: justfile, justfiles/*, jsys)
- Python (Ansible dependencies)
- YAML (configuration files)
- Jinja2 (templates)

**Key Features:**
- Secure secrets via Ansible Vault + 1Password integration
- Multi-host with host-specific overrides
- Smart package management (.deb → Flatpak → Snap priority)
- Tag-based selective execution
- Full COSMIC desktop management
- Theme generation from COSMIC colors

## Directory Structure

Follow the official Ansible best practices:

```
.
├── inventory/              # Inventory configuration
│   ├── hosts.yml          # Host and group definitions
│   ├── group_vars/all/    # Variables for all hosts
│   │   ├── settings.yml   # Non-sensitive settings (reusable variables only)
│   │   ├── vault.yml      # Encrypted secrets (Ansible Vault)
│   │   └── versions.yml   # Version pinning
│   └── host_vars/         # Host-specific variables
├── roles/                 # Ansible roles
│   ├── system/           # Core system configuration
│   ├── desktop/          # Desktop environment
│   ├── apps/             # Application management (nested roles)
│   │   ├── 1password/   # Individual app sub-roles
│   │   ├── restic/
│   │   └── ...
│   └── bootstrap/        # Initial system setup
├── site.yml              # Master playbook
├── bootstrap.yml         # Bootstrap playbook
├── maintenance.yml       # Maintenance tasks
├── security-check.yml    # Security validation
├── justfile              # Bootstrap & repository tasks
├── justfiles/            # Specialized task definitions
│   ├── maintenance
│   ├── security
│   └── git
├── scripts/              # Utility scripts
└── docs/                 # Documentation
```

## Coding Standards

### Ansible Playbooks and Roles

**YAML Formatting:**
- Use 2 spaces for indentation
- Always start files with `---`
- Use `snake_case` for variable names
- Quote strings containing special characters
- Use `|` for multi-line strings, `>` for folded strings

**Variable Naming:**
- Personal info: `personal.name`, `personal.email`, `personal.github_username`
- User settings: `user.name`, `user.home`, `user.shell`
- Application states: `app_states.<appname>` (e.g., `app_states.helix`)
- Role-specific config lives in `roles/<role>/defaults/main.yml`

**Role Structure:**
Every role should have:
- `tasks/main.yml` - Main task file
- `defaults/main.yml` - Default variables
- `templates/` - Jinja2 templates (if needed)
- `handlers/main.yml` - Handlers (if needed)

**Nested Roles:**
- Use `include_role` for nested roles (e.g., `apps/restic/`), NOT `import_tasks`
- This ensures proper template resolution and role context

**Task Patterns:**
```yaml
# Support both install and uninstall
- name: Install package
  apt:
    name: package-name
    state: "{{ app_states.appname | default('present') }}"
  become: true
  when: app_states.appname | default('present') == 'present'

# Always include appropriate tags
- name: Configure application
  template:
    src: config.j2
    dest: "{{ user.home }}/.config/app/config"
    owner: "{{ user.name }}"
    mode: '0644'
  when: app_states.appname | default('present') == 'present'
  tags: [appname, config]
```

**Security Requirements:**
- NEVER commit unencrypted secrets
- Use Ansible Vault for all sensitive data
- Store secrets in `inventory/group_vars/all/vault.yml`
- Set file permissions to 600 for sensitive files
- Use `.vault_pass` file for vault password (gitignored)

### Justfile Commands

**Structure:**
- `justfile` - Bootstrap and repository operations
- `justfiles/maintenance` - Ansible maintenance tasks
- `justfiles/security` - Vault operations, security checks
- `justfiles/git` - Advanced git operations
- System command: `jsys` (installed system-wide) for daily operations

**Style:**
- Use descriptive recipe names
- Include helpful comments
- Use shell functions for complex logic
- Set `shell := ["bash", "-uc"]` for consistency

### Templates

**Jinja2 Templates:**
- Use `.j2` extension
- Reference variables from role defaults or group_vars
- Use conditionals for optional features
- Add comments explaining complex logic

**Example:**
```jinja2
# {{ ansible_managed }}
# Application configuration

[settings]
username = {{ personal.name }}
email = {{ personal.email }}

{% if feature_enabled | default(false) %}
# Optional feature enabled
feature_config = value
{% endif %}
```

## Tagging Strategy

All roles and tasks must include appropriate tags:

**Common Tags:**
- `system` - System configuration
- `desktop` - Desktop environment
- `apps` - Application installation
- `config` - Configuration tasks
- `security` - Security-related tasks
- `backup` - Backup configuration

**Application Tags:**
- Each app role should have its own tag (e.g., `helix`, `vivaldi`, `1password`)
- Use tags for selective execution: `just tag <tagname>`

## Testing and Quality

**Linting:**
- Run `ansible-lint` before committing changes
- Configuration in `.ansible-lint`
- Use `production` profile
- Fix issues or add to `skip_list` with justification

**Dry Run:**
- Always test with `just check` (dry run) before applying
- Verify changes with `--check` and `--diff` flags

**Security Validation:**
- Run `just -f justfiles/security check` before commits
- Verify no sensitive files are staged with `just -f justfiles/security git-status`

## Documentation Requirements

When adding or modifying features:

1. **Update README.md** if:
   - Adding major features
   - Changing setup/bootstrap process
   - Modifying command structure

2. **Update role documentation:**
   - Add README.md to new roles explaining purpose and variables
   - Document any special requirements or dependencies

3. **Update STRUCTURE.md** if:
   - Changing directory layout
   - Adding new playbooks
   - Modifying role organization

4. **Update TODO.md** for:
   - Deferred enhancements
   - Known issues
   - Future improvements

## Common Patterns

### Adding a New Application Role

1. Create role structure:
   ```bash
   mkdir -p roles/apps/newapp/{tasks,defaults,templates}
   ```

2. Create `defaults/main.yml`:
   ```yaml
   ---
   # Newapp default variables
   newapp_state: present
   newapp_config:
     option1: value1
   ```

3. Create `tasks/main.yml`:
   ```yaml
   ---
   # Newapp installation and configuration

   - name: Install newapp
     apt:
       name: newapp
       state: "{{ app_states.newapp | default('present') }}"
     become: true

   - name: Configure newapp
     template:
       src: config.j2
       dest: "{{ user.home }}/.config/newapp/config"
       owner: "{{ user.name }}"
       mode: '0644'
     when: app_states.newapp | default('present') == 'present'

   - name: Remove config when absent
     file:
       path: "{{ user.home }}/.config/newapp"
       state: absent
     when: app_states.newapp | default('present') == 'absent'
   ```

4. Add to parent role:
   ```yaml
   # In roles/apps/tasks/main.yml
   - name: Include newapp role
     include_role:
       name: apps/newapp
     tags: [newapp, apps]
   ```

### Working with Secrets

1. Edit vault:
   ```bash
   just -f justfiles/security edit-vault
   ```

2. Add secret to `vault.yml`:
   ```yaml
   vault_newapp_api_key: "secret-key-here"
   ```

3. Reference in templates:
   ```jinja2
   api_key: {{ vault_newapp_api_key }}
   ```

### Package Installation Priority

Follow this order:
1. Native .deb packages (via APT) - preferred
2. Flatpak packages - second choice
3. Snap packages - last resort
4. Manual installation - only if no package available

## Common Mistakes to Avoid

❌ **Don't:**
- Use `import_tasks` for nested roles (use `include_role` instead)
- Hardcode user paths (use `{{ user.home }}` variable)
- Commit unencrypted secrets or `.vault_pass` file
- Mix configuration into `settings.yml` (put in role defaults)
- Forget to add tags to tasks
- Skip `when` conditions for state-based tasks

✅ **Do:**
- Follow Ansible best practices
- Use variables from defaults and group_vars
- Support both install and uninstall states
- Include proper tags for selective execution
- Test with dry-run before applying
- Run security checks before commits
- Document complex logic with comments
- Keep settings.yml minimal (only reusable personal/user variables)

## Build and Test Commands

**Bootstrap (first-time setup):**
```bash
just bootstrap          # Install Ansible and dependencies
just run               # Apply initial configuration
```

**Daily Operations (via jsys):**
```bash
jsys update-all        # System updates
jsys update-ansible    # Re-apply Ansible configuration
jsys cosmic-capture    # Save COSMIC settings
jsys cosmic-apply      # Apply COSMIC settings
```

**Development:**
```bash
just check             # Dry run (preview changes)
just run               # Apply configuration
just tag <tagname>     # Run specific tag
ansible-lint           # Lint playbooks and roles
```

**Security:**
```bash
just -f justfiles/security check       # Pre-commit security check
just -f justfiles/security edit-vault  # Edit encrypted vault
just -f justfiles/security git-status  # Check for staged secrets
```

## References

- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)
- [Ansible Variable Precedence](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_variables.html#variable-precedence-where-should-i-put-a-variable)
- [Just Command Runner](https://just.systems/)
- Repository Documentation in `docs/` directory

## Contributing Guidelines

When contributing:
1. Follow existing patterns and conventions
2. Support `state` parameter (install/uninstall) in all roles
3. Add appropriate tags for selective execution
4. Test with `just check` before running
5. Run `ansible-lint` to verify code quality
6. Document in role's README.md or docs/ as appropriate
7. Run security checks before committing
8. Keep changes minimal and focused
