#!/usr/bin/env fish
# Regenerate all Pake desktop applications
# This script rebuilds all Pake apps with the correct configurations

echo "Regenerating Pake applications..."
echo ""

# Regular apps
echo "Building regular apps..."
create-web-app https://konghq.aha.io/products/AI/feature_cards aha
create-web-app https://app.asana.com/1/536788629240466/project/1211778559292700/list/1211778559292717 asana --add-background
create-web-app https://avanti.letter.ai/ avanti
create-web-app https://github.com/bashfulrobot github
create-web-app https://cloud.konghq.com/us/overview/ konnect --add-background
create-web-app https://lucid.app/documents#/home lucid-chart
create-web-app https://kong.lightning.force.com/lightning/page/home sfdc

echo ""
echo "Building Google-based apps (with subdomain for logo search)..."
# Google-based apps (with subdomain)
create-web-app https://mail.google.com/mail/u/0/#search/is%3Aunread+AND+label%3Anoffin.com+OR+in%3Ainbox br-email mail.google.com
create-web-app https://calendar.google.com/calendar/u/0/r br-calendar calendar.google.com
create-web-app https://drive.google.com/drive/u/0/my-drive br-drive drive.google.com
create-web-app https://mail.google.com/mail/u/1/#search/is%3Aunread+in%3Ainbox kong-email mail.google.com
create-web-app https://calendar.google.com/calendar/u/1/r kong-calendar calendar.google.com
create-web-app https://drive.google.com/drive/u/1/my-drive kong-drive drive.google.com

echo ""
echo "Building Workday app (with custom domain)..."
# Workday (with custom domain)
create-web-app https://wd12.myworkday.com/kong/d/home.htmld workday workday.com
create-web-app https://developer.konghq.com/ kong-docs konghq.com --add-background
create-web-app https://education.konghq.com/learner-dashboard kong-academy konghq.com --add-background


echo ""
echo "✓ All Pake applications regenerated successfully!"
echo ""
echo "Next steps:"
echo "  1. Run Ansible to deploy: uat <app-tags>"
echo "  2. Or deploy all Pake apps at once"
