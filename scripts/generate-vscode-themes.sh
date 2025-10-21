#!/usr/bin/env bash
set -euo pipefail

# Generate VSCode COSMIC theme VSIX files
# Run this after changing COSMIC theme colors

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

echo "→ Generating VSCode COSMIC themes..."

# Run Ansible playbook to generate themes
ansible-playbook -i localhost, -c local /dev/stdin <<EOF
---
- hosts: localhost
  gather_facts: no
  vars_files:
    - "$REPO_ROOT/group_vars/all/auto-colors.yml"
  vars:
    repo_root: "$REPO_ROOT"
  tasks:
    # Install vsce if needed
    - name: Check if vsce is installed
      command: which vsce
      register: vsce_check
      failed_when: false
      changed_when: false

    - name: Install vsce globally via npm
      shell: npm install -g @vscode/vsce
      become: yes
      when: vsce_check.rc != 0

    # Dark Theme
    - name: Create COSMIC Dark theme build directory
      file:
        path: "{{ repo_root }}/extras/themes/vscode/cosmic-theme-dark"
        state: directory
        mode: '0755'

    - name: Create COSMIC Dark theme themes subdirectory
      file:
        path: "{{ repo_root }}/extras/themes/vscode/cosmic-theme-dark/themes"
        state: directory
        mode: '0755'

    - name: Deploy COSMIC Dark theme package.json
      template:
        src: "{{ repo_root }}/roles/apps/vscode/templates/package.json.j2"
        dest: "{{ repo_root }}/extras/themes/vscode/cosmic-theme-dark/package.json"
        mode: '0644'
      vars:
        mode: "Dark"
        is_dark: true

    - name: Deploy COSMIC Dark theme JSON
      template:
        src: "{{ repo_root }}/roles/apps/vscode/templates/cosmic-theme.json.j2"
        dest: "{{ repo_root }}/extras/themes/vscode/cosmic-theme-dark/themes/cosmic-dark.json"
        mode: '0644'
      vars:
        mode: "Dark"
        is_dark: true
        colors: "{{ theme_colors_dark.colors }}"

    - name: Deploy COSMIC Dark theme .vscodeignore
      template:
        src: "{{ repo_root }}/roles/apps/vscode/templates/vscodeignore.j2"
        dest: "{{ repo_root }}/extras/themes/vscode/cosmic-theme-dark/.vscodeignore"
        mode: '0644'

    # Light Theme
    - name: Create COSMIC Light theme build directory
      file:
        path: "{{ repo_root }}/extras/themes/vscode/cosmic-theme-light"
        state: directory
        mode: '0755'

    - name: Create COSMIC Light theme themes subdirectory
      file:
        path: "{{ repo_root }}/extras/themes/vscode/cosmic-theme-light/themes"
        state: directory
        mode: '0755'

    - name: Deploy COSMIC Light theme package.json
      template:
        src: "{{ repo_root }}/roles/apps/vscode/templates/package.json.j2"
        dest: "{{ repo_root }}/extras/themes/vscode/cosmic-theme-light/package.json"
        mode: '0644'
      vars:
        mode: "Light"
        is_dark: false

    - name: Deploy COSMIC Light theme JSON
      template:
        src: "{{ repo_root }}/roles/apps/vscode/templates/cosmic-theme.json.j2"
        dest: "{{ repo_root }}/extras/themes/vscode/cosmic-theme-light/themes/cosmic-light.json"
        mode: '0644'
      vars:
        mode: "Light"
        is_dark: false
        colors: "{{ theme_colors_light.colors }}"

    - name: Deploy COSMIC Light theme .vscodeignore
      template:
        src: "{{ repo_root }}/roles/apps/vscode/templates/vscodeignore.j2"
        dest: "{{ repo_root }}/extras/themes/vscode/cosmic-theme-light/.vscodeignore"
        mode: '0644'

    # Package as VSIX
    - name: Package COSMIC Dark theme as VSIX
      shell: |
        cd "{{ repo_root }}/extras/themes/vscode/cosmic-theme-dark"
        vsce package --out "{{ repo_root }}/extras/themes/vscode/cosmic-theme-dark.vsix" --allow-missing-repository
      register: dark_vsix_package
      failed_when: dark_vsix_package.rc != 0

    - name: Package COSMIC Light theme as VSIX
      shell: |
        cd "{{ repo_root }}/extras/themes/vscode/cosmic-theme-light"
        vsce package --out "{{ repo_root }}/extras/themes/vscode/cosmic-theme-light.vsix" --allow-missing-repository
      register: light_vsix_package
      failed_when: light_vsix_package.rc != 0

    # Clean up build directories
    - name: Remove COSMIC Dark theme build directory
      file:
        path: "{{ repo_root }}/extras/themes/vscode/cosmic-theme-dark"
        state: absent

    - name: Remove COSMIC Light theme build directory
      file:
        path: "{{ repo_root }}/extras/themes/vscode/cosmic-theme-light"
        state: absent
EOF

echo "✓ VSCode themes generated:"
echo "  - extras/themes/vscode/cosmic-theme-dark.vsix"
echo "  - extras/themes/vscode/cosmic-theme-light.vsix"
