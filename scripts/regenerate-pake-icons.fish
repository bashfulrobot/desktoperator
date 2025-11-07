#!/usr/bin/env fish
# Source the function definitions
source ~/.config/fish/conf.d/pake-wrapper.fish

# Regenerate all Pake desktop application icons
# This script re-fetches and processes all Pake app icons with the correct configurations

echo "Regenerating Pake application icons..."
echo ""

# Regular apps
echo "Regenerating regular app icons..."
generate-icon-set 'https://konghq.aha.io/products/AI/favicon.ico' aha
generate-icon-set 'https://app.asana.com/-/favicon.ico' asana --add-background
generate-icon-set 'https://avanti.letter.ai/favicon.ico' avanti
generate-icon-set 'https://github.githubassets.com/favicons/favicon.svg' github
generate-icon-set 'https://cloud.konghq.com/favicon.ico' konnect --add-background
generate-icon-set 'https://lucid.app/favicon.ico' lucid-chart
generate-icon-set 'https://www.salesforce.com/content/dam/sfdc-docs/www/resources/campaign-assets/images/salesforce-logo-avatar.png' sfdc

echo ""
echo "Regenerating Google-based app icons..."
# Google-based apps (using specific icon URL)
generate-icon-set 'https://cdn.brandfetch.io/id6O2oGzv-/theme/dark/idMX2_OMSc.svg?c=1bxid64Mup7aczewSAYMX&t=1755572706253' br-email
generate-icon-set 'https://cdn.brandfetch.io/id6O2oGzv-/theme/dark/idMX2_OMSc.svg?c=1bxid64Mup7aczewSAYMX&t=1755572706253' br-calendar
generate-icon-set 'https://cdn.brandfetch.io/id6O2oGzv-/theme/dark/idMX2_OMSc.svg?c=1bxid64Mup7aczewSAYMX&t=1755572706253' br-drive
generate-icon-set 'https://cdn.brandfetch.io/id6O2oGzv-/theme/dark/idMX2_OMSc.svg?c=1bxid64Mup7aczewSAYMX&t=1755572706253' kong-email
generate-icon-set 'https://cdn.brandfetch.io/id6O2oGzv-/theme/dark/idMX2_OMSc.svg?c=1bxid64Mup7aczewSAYMX&t=1755572706253' kong-calendar
generate-icon-set 'https://cdn.brandfetch.io/id6O2oGzv-/theme/dark/idMX2_OMSc.svg?c=1bxid64Mup7aczewSAYMX&t=1755572706253' kong-drive

echo ""
echo "Regenerating Workday and Kong Docs icons..."
generate-icon-set 'https://www.workday.com/content/dam/web/images/icons/wd-favicon.svg' workday
generate-icon-set 'https://docs.konghq.com/assets/images/favicon.png' kong-docs --add-background

echo ""
echo "✓ All Pake application icons regenerated successfully!"
echo ""
echo "Icons are now in:"
echo "  ~/dev/iac/desktoperator/roles/apps/<name>-pake/files/"
echo ""
echo "Next step: Deploy with ansible-playbook"
