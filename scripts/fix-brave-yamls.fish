#!/usr/bin/env fish

# Fix YAML files for brave apps by regenerating them with proper formatting
# Source the fixed function
source roles/apps/brave-web-apps/templates/brave-web-apps.fish.j2

set -l apps aha asana avanti br-calendar br-drive br-email codex kong-calendar kong-docs kong-drive kong-email konnect lucid-chart omni sfdc workday

for app in $apps
    set -l role_path "roles/apps/$app-brave"
    if test -d "$role_path"
        echo "Fixing $app-brave YAML files..."
        set -l display_name (string replace '-' ' ' $app)
        _brave_create_ansible_tasks $app $role_path "$display_name"
    end
end

echo ""
echo "✅ All YAML files fixed!"
