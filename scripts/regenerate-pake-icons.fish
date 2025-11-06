#!/usr/bin/env fish
# Source the function definitions
source ~/.config/fish/conf.d/pake-wrapper.fish

# Regenerate all Pake desktop application icons
# This script re-fetches and processes all Pake app icons with the correct configurations

echo "Regenerating Pake application icons..."
echo ""

# Regular apps
echo "Regenerating regular app icons..."
regenerate-pake-icons https://konghq.aha.io/products/AI/feature_cards aha
regenerate-pake-icons https://app.asana.com/1/536788629240466/project/1211778559292700/list/1211778559292717 asana --add-background
regenerate-pake-icons https://avanti.letter.ai/ avanti
regenerate-pake-icons https://github.com/bashfulrobot github
regenerate-pake-icons https://cloud.konghq.com/us/overview/ konnect --add-background
regenerate-pake-icons https://lucid.app/documents#/home lucid-chart
regenerate-pake-icons https://kong.lightning.force.com/lightning/page/home sfdc

echo ""
echo "Regenerating Google-based app icons (with subdomain for logo search)..."
# Google-based apps (with subdomain)
regenerate-pake-icons https://mail.google.com/mail/u/0/#search/is%3Aunread+AND+label%3Anoffin.com+OR+in%3Ainbox br-email gmail.com
regenerate-pake-icons https://calendar.google.com/calendar/u/0/r br-calendar --icon 'https://cdn.brandfetch.io/id6O2oGzv-/theme/dark/idMX2_OMSc.svg?c=1bxid64Mup7aczewSAYMX&t=1755572706253'
regenerate-pake-icons https://drive.google.com/drive/u/0/my-drive br-drive drive.google.com
regenerate-pake-icons https://mail.google.com/mail/u/1/#search/is%3Aunread+in%3Ainbox kong-email gmail.com
regenerate-pake-icons https://calendar.google.com/calendar/u/1/r kong-calendar --icon 'https://cdn.brandfetch.io/id6O2oGzv-/theme/dark/idMX2_OMSc.svg?c=1bxid64Mup7aczewSAYMX&t=1755572706253'
regenerate-pake-icons https://drive.google.com/drive/u/1/my-drive kong-drive drive.google.com

echo ""
echo "Regenerating Workday app icon (with custom domain)..."
# Workday (with custom domain)
regenerate-pake-icons https://wd12.myworkday.com/kong/d/home.htmld workday workday.com
regenerate-pake-icons https://developer.konghq.com/ kong-docs konghq.com --add-background

echo ""
echo "✓ All Pake application icons regenerated successfully!"
