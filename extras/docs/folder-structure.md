# Directory Structure

This repository follows the official Ansible best practices for directory structure.

**Reference:** [Ansible Best Practices - Directory Layout](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html#directory-layout)

## Structure

```
.
├── inventory/              # Inventory configuration
│   ├── hosts.yml          # Host and group definitions
│   ├── group_vars/        # Variables for groups
│   │   └── all/           # Variables for all hosts
│   │       ├── settings.yml    # Non-sensitive settings
│   │       ├── vault.yml       # Encrypted secrets
│   │       └── versions.yml    # Version pinning
│   └── host_vars/         # Host-specific variables
│       ├── donkeykong.yml
│       └── qbert.yml
│
├── roles/                 # Ansible roles
│   ├── system/           # Core system configuration
│   ├── desktop/          # Desktop environment
│   ├── apps/             # Application management (parent role)
│   │   ├── 1password/   # Individual app sub-roles
│   │   ├── restic/
│   │   ├── helix/
│   │   ├── zellij/
│   │   └── zen-browser/
│   └── bootstrap/        # Initial system setup
│
├── site.yml              # Master playbook
├── bootstrap.yml         # Bootstrap playbook
├── maintenance.yml       # Maintenance tasks playbook
├── security-check.yml    # Security validation playbook
│
├── justfile              # Main task runner
├── justfiles/            # Additional task definitions
│   ├── maintenance       # Maintenance tasks
│   ├── security          # Security operations
│   └── git               # Git operations
│
├── ansible.cfg           # Ansible configuration
├── requirements.txt      # Python dependencies (reference only)
├── scripts/              # Utility scripts
│   └── bootstrap.sh      # System bootstrap script
│
└── docs/                 # Documentation
    ├── getting-started.md
    ├── security.md
    ├── investigations/   # Work-in-progress notes
    └── ...
```

## Key Principles

1. **Playbooks at Root:** Main playbooks (site.yml, bootstrap.yml) are at the repository root
2. **group_vars/host_vars in inventory/:** Variables are relative to the inventory file location
3. **Roles at Root:** Roles directory contains all role definitions
4. **Local Execution:** All hosts use `ansible_connection: local` for running Ansible locally
5. **Group-Based Variables:** Common settings in `group_vars/all/`, host-specific in `host_vars/`

## Variable Precedence

Ansible loads variables in this order (lowest to highest priority):

1. `inventory/group_vars/all/*.yml` - Applies to all hosts
2. `inventory/group_vars/<group>/*.yml` - Group-specific (e.g., desktops, laptops)
3. `inventory/host_vars/<hostname>.yml` - Host-specific overrides
4. `roles/<role>/defaults/main.yml` - Role defaults
5. `roles/<role>/vars/main.yml` - Role variables
6. Playbook vars_files and vars
7. Extra vars (`-e` on command line) - Highest priority

## Nested Role Structure

This project uses a nested role structure for applications (`apps/1password/`, `apps/restic/`, etc.) rather than top-level roles. This deviates from standard Ansible practices but provides better organization for this use case.

**Important:** When including nested roles, use `include_role` rather than `import_tasks`:

```yaml
# Correct - properly sets role context for templates
- name: Include restic installation
  include_role:
    name: apps/restic
  tags: [restic, backup]

# Incorrect - templates searched relative to parent role
# - name: Import restic installation
#   import_tasks: ../restic/tasks/main.yml
```

**Reference:** [Ansible Roles - Include vs Import](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_reuse_roles.html)

## Maintenance

When adding new hosts, playbooks, or roles:

1. Follow the structure shown above
2. Place playbooks at the root level
3. Place group variables in `inventory/group_vars/`
4. Place host variables in `inventory/host_vars/`
5. Keep roles in the `roles/` directory
6. For application roles, nest under `roles/apps/<app-name>/`
7. Use `include_role` to include nested roles, not `import_tasks`
8. Document changes in this file if structure changes

## References

- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)
- [Ansible Variable Precedence](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_variables.html#variable-precedence-where-should-i-put-a-variable)
- [Sample Directory Layout](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html#directory-layout)
