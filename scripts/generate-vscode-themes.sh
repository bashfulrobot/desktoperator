#!/usr/bin/env bash
set -euo pipefail

# Generate VSCode COSMIC theme VSIX file

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

echo "→ Generating VSCode COSMIC theme..."

BUILD_DIR="$REPO_ROOT/extras/themes/vscode/cosmic-theme"

# Run Ansible playbook to generate themes
ansible-playbook -i localhost, -c local /dev/stdin <<EOF
---
- hosts: localhost
  gather_facts: no
  vars_files:
    - "$REPO_ROOT/group_vars/all/auto-colors.yml"
  vars:
    repo_root: "$REPO_ROOT"
    build_dir: "$BUILD_DIR"
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

    # Create build directories
    - name: Create COSMIC theme build directory
      file:
        path: "{{ build_dir }}"
        state: directory
        mode: '0755'

    - name: Create COSMIC theme themes subdirectory
      file:
        path: "{{ build_dir }}/themes"
        state: directory
        mode: '0755'

    # Deploy templates
    - name: Deploy COSMIC theme package.json
      template:
        src: "{{ repo_root }}/roles/apps/vscode/templates/package.json.j2"
        dest: "{{ build_dir }}/package.json"
        mode: '0644'

    - name: Deploy COSMIC Dark theme JSON
      template:
        src: "{{ repo_root }}/roles/apps/vscode/templates/cosmic-dark.json.j2"
        dest: "{{ build_dir }}/themes/cosmic-dark.json"
        mode: '0644'

    - name: Deploy COSMIC Light theme JSON
      template:
        src: "{{ repo_root }}/roles/apps/vscode/templates/cosmic-light.json.j2"
        dest: "{{ build_dir }}/themes/cosmic-light.json"
        mode: '0644'

    - name: Deploy COSMIC theme .vscodeignore
      template:
        src: "{{ repo_root }}/roles/apps/vscode/templates/vscodeignore.j2"
        dest: "{{ build_dir }}/.vscodeignore"
        mode: '0644'

    # Package as VSIX
    - name: Package COSMIC theme as VSIX
      shell: |
        cd "{{ build_dir }}"
        vsce package --out "{{ repo_root }}/extras/themes/vscode/cosmic-theme.vsix" --allow-missing-repository
      register: vsix_package
      failed_when: vsix_package.rc != 0

    # Clean up build directory
    - name: Remove COSMIC theme build directory
      file:
        path: "{{ build_dir }}"
        state: absent
EOF

echo "✓ VSCode theme generated:"
echo "  - extras/themes/vscode/cosmic-theme.vsix"