#!/usr/bin/env fish
# Convert all Pake apps to Brave web apps
# This script creates Brave equivalents of all existing Pake apps

echo "Converting Pake apps to Brave web apps..."
echo ""

# Apps with background-enhanced icons
set -l apps_with_bg aha avanti br-email konnect kong-docs

echo "→ aha"
create-brave-web-app https://konghq.aha.io/products/AI/feature_cards aha

echo ""
echo "→ avanti"
create-brave-web-app https://avanti.letter.ai/ avanti

echo ""
echo "→ br-calendar"
create-brave-web-app https://calendar.google.com/calendar/u/0/r br-calendar

echo ""
echo "→ br-drive"
create-brave-web-app https://drive.google.com/drive/u/0/my-drive br-drive

echo ""
echo "→ br-email"
create-brave-web-app 'https://mail.google.com/mail/u/0/#search/is%3Aunread+AND+label%3Anoffin.com+OR+in%3Ainbox' br-email

echo ""
echo "→ kong-calendar"
create-brave-web-app https://calendar.google.com/calendar/u/1/r kong-calendar

echo ""
echo "→ kong-docs"
create-brave-web-app https://developer.konghq.com/ kong-docs

echo ""
echo "→ kong-drive"
create-brave-web-app https://drive.google.com/drive/u/1/my-drive kong-drive

echo ""
echo "→ kong-email"
create-brave-web-app 'https://mail.google.com/mail/u/1/#search/is%3Aunread+in%3Ainbox' kong-email

echo ""
echo "→ konnect"
create-brave-web-app https://cloud.konghq.com/us/overview/ konnect

echo ""
echo "→ lucid-chart"
create-brave-web-app 'https://lucid.app/documents#/home' lucid-chart

echo ""
echo "→ omni"
create-brave-web-app https://bashfulrobot.omni.siderolabs.io/omni/ omni

echo ""
echo "→ sfdc"
create-brave-web-app https://kong.lightning.force.com/lightning/page/home sfdc

echo ""
echo "→ workday"
create-brave-web-app https://wd12.myworkday.com/kong/d/home.htmld workday

echo ""
echo "→ asana (if it exists)"
if test -d roles/apps/asana-pake
    create-brave-web-app https://app.asana.com asana
end

echo ""
echo "✅ All Brave web apps created!"
echo ""
echo "Next steps:"
echo "  1. Review the generated roles in roles/apps/*-brave/"
echo "  2. Add entries to roles/apps/defaults/main.yml"
echo "  3. Add import_role tasks to roles/apps/tasks/main.yml"
echo "  4. Set corresponding pake apps to 'absent' in defaults"
echo "  5. Deploy with: ansible-playbook site.yml --tags brave-web-apps"
echo ""
