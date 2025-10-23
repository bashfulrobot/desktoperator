#!/usr/bin/env bash
# Script to capture current COSMIC configuration into the repository

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
COSMIC_CONFIG_DIR="$HOME/.config/cosmic"
DEST_DIR="$REPO_ROOT/roles/desktop/cosmic/config"

if [[ ! -d "$COSMIC_CONFIG_DIR" ]]; then
    echo "Error: COSMIC config directory not found at $COSMIC_CONFIG_DIR"
    exit 1
fi

echo "Capturing COSMIC configuration from $COSMIC_CONFIG_DIR"
echo "Destination: $DEST_DIR"

# Clear existing config files (keep directory and .gitkeep)
if [[ -d "$DEST_DIR" ]]; then
    echo "Clearing existing config files"
    find "$DEST_DIR" -mindepth 1 ! -name '.gitkeep' -delete
fi

# Copy the cosmic config directory, excluding theme mode settings
# We exclude is_dark files since theme mode should be managed by the system, not Ansible
rsync -av \
    --exclude='com.system76.CosmicTheme.Dark/v1/is_dark' \
    --exclude='com.system76.CosmicTheme.Mode/v1/is_dark' \
    "$COSMIC_CONFIG_DIR/" "$DEST_DIR/"

echo ""
echo "✓ COSMIC configuration captured successfully!"
echo ""
echo "Next steps:"
echo "  1. Review the captured configuration in roles/desktop/cosmic/config/"
echo "  2. Remove any sensitive or machine-specific settings"
echo "  3. Commit the changes:"
echo "     git add roles/desktop/cosmic/config/"
echo "     git commit -m 'feat(desktop): Update COSMIC configuration'"
echo ""
echo "To apply this configuration to a system:"
echo "  jsys cosmic-apply"
