#!/usr/bin/env fish
# Source the function definitions
source ~/.config/fish/conf.d/pake-wrapper.fish

# Regenerate all Pake desktop application icons
# This script re-fetches and processes all Pake app icons with the correct configurations

echo "Regenerating Pake application icons..."
echo ""

# Regular apps
echo "Regenerating regular app icons..."
generate-icon-set '/home/dustin/dev/iac/desktoperator/roles/apps/aha-pake/files/pake-aha-icon.png' aha --add-background
generate-icon-set '/home/dustin/dev/iac/desktoperator/roles/apps/avanti-pake/files/colour-kong.svg' avanti --add-background
generate-icon-set '/home/dustin/dev/iac/desktoperator/roles/apps/br-email-pake/files/gmail.svg' br-email --add-background
generate-icon-set '/home/dustin/dev/iac/desktoperator/roles/apps/br-calendar-pake/files/cal.svg' br-calendar
generate-icon-set '/home/dustin/dev/iac/desktoperator/roles/apps/br-drive-pake/files/drive.svg' br-drive
generate-icon-set '/home/dustin/dev/iac/desktoperator/roles/apps/github-pake/files/github.svg' github
generate-icon-set '/home/dustin/dev/iac/desktoperator/roles/apps/kong-email-pake/files/gmail.svg' kong-email
generate-icon-set '/home/dustin/dev/iac/desktoperator/roles/apps/kong-calendar-pake/files/cal.svg' kong-calendar
generate-icon-set '/home/dustin/dev/iac/desktoperator/roles/apps/kong-drive-pake/files/drive.svg' kong-drive
generate-icon-set '/home/dustin/dev/iac/desktoperator/roles/apps/konnect-pake/files/colour-kong.svg' konnect --add-background
generate-icon-set '/home/dustin/dev/iac/desktoperator/roles/apps/kong-docs-pake/files/white-kong.svg' kong-docs --add-background
generate-icon-set '/home/dustin/dev/iac/desktoperator/roles/apps/lucid-chart-pake/files/lucidchart.svg' lucid-chart
generate-icon-set '/home/dustin/dev/iac/desktoperator/roles/apps/omni-pake/files/sidero.svg' omni
generate-icon-set '/home/dustin/dev/iac/desktoperator/roles/apps/sfdc-pake/files/sfdc.svg' sfdc
generate-icon-set '/home/dustin/dev/iac/desktoperator/roles/apps/workday-pake/files/workday.svg' workday

echo ""
echo "✓ All Pake application icons regenerated successfully!"
echo ""
echo "Icons are now in:"
echo "  ~/dev/iac/desktoperator/roles/apps/<name>-pake/files/"
echo ""
echo "Next step: Deploy with ansible-playbook"
