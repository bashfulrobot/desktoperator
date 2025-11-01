# Pake Icon Selection Rollback Guide

## What Changed

**New logic (improved):**
- Prefers icon type over logo type
- Prefers light theme over dark theme
- Targets optimal size (400-1024px)
- Converts JPEG/WebP icons to PNG if needed

**Old logic (simple):**
- Just selects largest PNG by pixel area

## Scoring System

Icons are scored and the highest score wins:
- **Icon type:** +1000 points
- **Logo type:** +0 points
- **Light theme:** +100 points
- **Dark theme:** +50 points
- **No theme:** +75 points
- **Size 400-1024px:** +10 points
- **Size >1024px:** +5 points
- **Size 256-399px:** +3 points
- **Size <256px:** +1 point

## If Results Look Bad

### Quick Rollback (Restore Backup)

```bash
# Restore the backup
cp /home/dustin/dev/iac/desktoperator/roles/apps/pake/templates/pake-wrapper.fish.j2.backup \
   /home/dustin/dev/iac/desktoperator/roles/apps/pake/templates/pake-wrapper.fish.j2

# Redeploy
ansible-playbook site.yml --tags pake

# Restart terminal
```

### Verify Backup Exists

```bash
ls -lh /home/dustin/dev/iac/desktoperator/roles/apps/pake/templates/pake-wrapper.fish.j2.backup
```

## Testing New Logic

```bash
# Deploy new version
ansible-playbook site.yml --tags pake

# Restart terminal, then test
create-web-app https://app.asana.com/... asana
create-web-app https://github.com GitHub
create-web-app https://slack.com Slack
```

### What to Look For

**Good results:**
- Icons look clean and centered
- Appropriate size for desktop
- Transparent backgrounds work well

**Bad results:**
- Icons too small/blurry
- Wrong theme (dark icons on light background)
- Conversion artifacts from JPEG

## Keep Backup

The backup file will remain in place. You can delete it after confirming the new logic works:

```bash
rm /home/dustin/dev/iac/desktoperator/roles/apps/pake/templates/pake-wrapper.fish.j2.backup
```
