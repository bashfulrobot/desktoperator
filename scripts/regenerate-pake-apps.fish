#!/usr/bin/env fish
# Source the function definitions
source ~/.config/fish/conf.d/pake-wrapper.fish

# Regenerate all Pake desktop applications (complete rebuild)
# This script rebuilds all Pake apps AND icons with the correct configurations
#
# IMPORTANT: Icons must be generated BEFORE building apps

echo "Regenerating Pake applications (icons + apps)..."
echo ""

# Regular apps
echo "==> Building regular apps..."
echo ""

echo "→ aha"
generate-icon-set 'https://konghq.aha.io/products/AI/favicon.ico' aha
create-web-app https://konghq.aha.io/products/AI/feature_cards aha

echo ""
echo "→ asana"
generate-icon-set 'https://app.asana.com/-/favicon.ico' asana --add-background
create-web-app https://app.asana.com/1/536788629240466/project/1211778559292700/list/1211778559292717 asana

echo ""
echo "→ avanti"
generate-icon-set 'https://avanti.letter.ai/favicon.ico' avanti
create-web-app https://avanti.letter.ai/ avanti

echo ""
echo "→ github"
generate-icon-set 'https://github.githubassets.com/favicons/favicon.svg' github
create-web-app https://github.com/bashfulrobot github

echo ""
echo "→ konnect"
generate-icon-set 'https://cloud.konghq.com/favicon.ico' konnect --add-background
create-web-app https://cloud.konghq.com/us/overview/ konnect

echo ""
echo "→ lucid-chart"
generate-icon-set 'https://lucid.app/favicon.ico' lucid-chart
create-web-app https://lucid.app/documents#/home lucid-chart

echo ""
echo "→ sfdc"
generate-icon-set 'https://www.salesforce.com/content/dam/sfdc-docs/www/resources/campaign-assets/images/salesforce-logo-avatar.png' sfdc
create-web-app https://kong.lightning.force.com/lightning/page/home sfdc

echo ""
echo "==> Building Google-based apps..."
echo ""

set -l google_icon 'https://cdn.brandfetch.io/id6O2oGzv-/theme/dark/idMX2_OMSc.svg?c=1bxid64Mup7aczewSAYMX&t=1755572706253'

echo "→ br-email"
generate-icon-set $google_icon br-email
create-web-app https://mail.google.com/mail/u/0/#search/is%3Aunread+AND+label%3Anoffin.com+OR+in%3Ainbox br-email

echo ""
echo "→ br-calendar"
generate-icon-set $google_icon br-calendar
create-web-app https://calendar.google.com/calendar/u/0/r br-calendar

echo ""
echo "→ br-drive"
generate-icon-set $google_icon br-drive
create-web-app https://drive.google.com/drive/u/0/my-drive br-drive

echo ""
echo "→ kong-email"
generate-icon-set $google_icon kong-email
create-web-app https://mail.google.com/mail/u/1/#search/is%3Aunread+in%3Ainbox kong-email

echo ""
echo "→ kong-calendar"
generate-icon-set $google_icon kong-calendar
create-web-app https://calendar.google.com/calendar/u/1/r kong-calendar

echo ""
echo "→ kong-drive"
generate-icon-set $google_icon kong-drive
create-web-app https://drive.google.com/drive/u/1/my-drive kong-drive

echo ""
echo "==> Building Workday and Kong Docs apps..."
echo ""

echo "→ workday"
generate-icon-set 'https://www.workday.com/content/dam/web/images/icons/wd-favicon.svg' workday
create-web-app https://wd12.myworkday.com/kong/d/home.htmld workday

echo ""
echo "→ kong-docs"
generate-icon-set 'https://docs.konghq.com/assets/images/favicon.png' kong-docs --add-background
create-web-app https://developer.konghq.com/ kong-docs

echo ""
echo "✓ All Pake applications and icons regenerated successfully!"
echo ""
echo "Next step: Deploy with ansible-playbook site.yml --tags pake-apps"
