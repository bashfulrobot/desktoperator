#!/usr/bin/env fish
# Source the function definitions
source ~/.config/fish/conf.d/pake-wrapper.fish

# Regenerate all Pake desktop applications (complete rebuild)
# This script rebuilds all Pake apps AND icons with the correct configurations
#
# IMPORTANT: Icons must be generated BEFORE building apps

echo "Regenerating Pake applications (icons + apps)..."
echo ""

echo "→ aha"
create-web-app https://konghq.aha.io/products/AI/feature_cards aha

echo ""
echo "→ avanti"
create-web-app https://avanti.letter.ai/ avanti

echo ""
echo "→ br-calendar"
create-web-app https://calendar.google.com/calendar/u/0/r br-calendar

echo ""
echo "→ br-drive"
create-web-app https://drive.google.com/drive/u/0/my-drive br-drive

echo ""
echo "→ br-email"
create-web-app https://mail.google.com/mail/u/0/#search/is%3Aunread+AND+label%3Anoffin.com+OR+in%3Ainbox br-email

echo ""
echo "→ github"
create-web-app https://github.com/bashfulrobot github

echo ""
echo "→ kong-calendar"
create-web-app https://calendar.google.com/calendar/u/1/r kong-calendar

echo ""
echo "→ kong-docs"
create-web-app https://developer.konghq.com/ kong-docs

echo ""
echo "→ kong-drive"
create-web-app https://drive.google.com/drive/u/1/my-drive kong-drive

echo ""
echo "→ kong-email"
create-web-app https://mail.google.com/mail/u/1/#search/is%3Aunread+in%3Ainbox kong-email

echo ""
echo "→ konnect"
create-web-app https://cloud.konghq.com/us/overview/ konnect

echo ""
echo "→ lucid-chart"
create-web-app https://lucid.app/documents#/home lucid-chart

echo ""
echo "→ omni"
create-web-app https://bashfulrobot.omni.siderolabs.io/omni/ omni

echo ""
echo "→ sfdc"
create-web-app https://kong.lightning.force.com/lightning/page/home sfdc

echo ""
echo "==> Building Workday and Kong Docs apps..."
echo ""

echo "→ workday"
create-web-app https://wd12.myworkday.com/kong/d/home.htmld workday

echo ""
echo "✓ All Pake applications and icons regenerated successfully!"
echo ""
echo "Next step: Deploy with ansible-playbook site.yml --tags pake-apps"
