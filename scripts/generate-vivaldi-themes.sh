#!/usr/bin/env bash
set -euo pipefail

# Generate Vivaldi COSMIC theme ZIP files
# Run this after changing COSMIC theme colors

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

echo "→ Generating Vivaldi COSMIC themes..."

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
    # Create build directories
    - name: Ensure vivaldi theme directories exist
      file:
        path: "{{ item }}"
        state: directory
        mode: '0755'
      loop:
        - "{{ repo_root }}/extras/themes/vivaldi"
        - "{{ repo_root }}/extras/themes/vivaldi/cosmic-dark-build"
        - "{{ repo_root }}/extras/themes/vivaldi/cosmic-light-build"

    # Copy theme assets for Dark theme
    - name: Copy theme assets for Dark theme
      copy:
        src: "{{ repo_root }}/roles/apps/vivaldi/files/dark-icons/{{ item }}"
        dest: "{{ repo_root }}/extras/themes/vivaldi/cosmic-dark-build/{{ item }}"
        mode: '0644'
      loop:
        - Back.svg
        - BreakMode.svg
        - COMMAND_ckqjdk4o7000001l58zh17egm.svg
        - COMMAND_ckqjhvf430003c5429ni7i7bz.svg
        - COMMAND_ckqkoqycf0003wv4210uduu8n.svg
        - CalendarStatus.svg
        - CaptureImages.svg
        - Clock.svg
        - DownloadButton.svg
        - Extensions.svg
        - FastForward.svg
        - Forward.svg
        - Home.svg
        - ImagesToggle.svg
        - MailStatus.svg
        - PageActions.svg
        - PanelBookmarks.svg
        - PanelCalendar.svg
        - PanelContacts.svg
        - PanelDownloads.svg
        - PanelFeeds.svg
        - PanelHistory.svg
        - PanelMail.svg
        - PanelNotes.svg
        - PanelReadingList.svg
        - PanelSession.svg
        - PanelTasks.svg
        - PanelToggle.svg
        - PanelTranslate.svg
        - PanelWeb.svg
        - PanelWindow.svg
        - Proxy.svg
        - ReadingList.svg
        - Reload.svg
        - Rewind.svg
        - SearchField.svg
        - Settings.svg
        - Stop.svg
        - SyncStatus.svg
        - TilingToggle.svg
        - UpdateButton.svg
        - WorkspaceButton.svg

    # Copy theme assets for Light theme
    - name: Copy theme assets for Light theme
      copy:
        src: "{{ repo_root }}/roles/apps/vivaldi/files/light-icons/{{ item }}"
        dest: "{{ repo_root }}/extras/themes/vivaldi/cosmic-light-build/{{ item }}"
        mode: '0644'
      loop:
        - Back.svg
        - BreakMode.svg
        - COMMAND_ckqjdk4o7000001l58zh17egm.svg
        - COMMAND_ckqjhvf430003c5429ni7i7bz.svg
        - COMMAND_ckqkoqycf0003wv4210uduu8n.svg
        - CalendarStatus.svg
        - CaptureImages.svg
        - Clock.svg
        - DownloadButton.svg
        - Extensions.svg
        - FastForward.svg
        - Forward.svg
        - Home.svg
        - ImagesToggle.svg
        - MailStatus.svg
        - PageActions.svg
        - PanelBookmarks.svg
        - PanelCalendar.svg
        - PanelContacts.svg
        - PanelDownloads.svg
        - PanelFeeds.svg
        - PanelHistory.svg
        - PanelMail.svg
        - PanelNotes.svg
        - PanelReadingList.svg
        - PanelSession.svg
        - PanelTasks.svg
        - PanelToggle.svg
        - PanelTranslate.svg
        - PanelWeb.svg
        - PanelWindow.svg
        - Proxy.svg
        - ReadingList.svg
        - Reload.svg
        - Rewind.svg
        - SearchField.svg
        - Settings.svg
        - Stop.svg
        - SyncStatus.svg
        - TilingToggle.svg
        - UpdateButton.svg
        - WorkspaceButton.svg

    # Generate settings.json files
    - name: Generate Vivaldi Dark theme settings.json
      template:
        src: "{{ repo_root }}/roles/apps/vivaldi/templates/theme-settings-dark.json.j2"
        dest: "{{ repo_root }}/extras/themes/vivaldi/cosmic-dark-build/settings.json"
        mode: '0644'

    - name: Generate Vivaldi Light theme settings.json
      template:
        src: "{{ repo_root }}/roles/apps/vivaldi/templates/theme-settings-light.json.j2"
        dest: "{{ repo_root }}/extras/themes/vivaldi/cosmic-light-build/settings.json"
        mode: '0644'

    # Create ZIP files
    - name: Create Vivaldi Dark theme ZIP file
      community.general.archive:
        path: "{{ repo_root }}/extras/themes/vivaldi/cosmic-dark-build/*"
        dest: "{{ repo_root }}/extras/themes/vivaldi/cosmic-dark.zip"
        format: zip
        remove: false

    - name: Create Vivaldi Light theme ZIP file
      community.general.archive:
        path: "{{ repo_root }}/extras/themes/vivaldi/cosmic-light-build/*"
        dest: "{{ repo_root }}/extras/themes/vivaldi/cosmic-light.zip"
        format: zip
        remove: false

    # Clean up build directories
    - name: Remove Dark theme build directory
      file:
        path: "{{ repo_root }}/extras/themes/vivaldi/cosmic-dark-build"
        state: absent

    - name: Remove Light theme build directory
      file:
        path: "{{ repo_root }}/extras/themes/vivaldi/cosmic-light-build"
        state: absent
EOF

echo "✓ Vivaldi themes generated:"
echo "  - extras/themes/vivaldi/cosmic-dark.zip"
echo "  - extras/themes/vivaldi/cosmic-light.zip"
