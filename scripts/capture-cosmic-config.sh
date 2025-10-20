#!/usr/bin/env bash
# Script to capture current COSMIC configuration into the repository

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
COSMIC_CONFIG_DIR="$HOME/.config/cosmic"
DEST_DIR="$REPO_ROOT/cosmic-config"

if [[ ! -d "$COSMIC_CONFIG_DIR" ]]; then
    echo "Error: COSMIC config directory not found at $COSMIC_CONFIG_DIR"
    exit 1
fi

echo "Capturing COSMIC configuration from $COSMIC_CONFIG_DIR"
echo "Destination: $DEST_DIR"

# Create backup if cosmic-config already exists
if [[ -d "$DEST_DIR" ]]; then
    backup_dir="${DEST_DIR}.backup.$(date +%s)"
    echo "Backing up existing cosmic-config to $backup_dir"
    mv "$DEST_DIR" "$backup_dir"
fi

# Copy the entire cosmic config directory
cp -r "$COSMIC_CONFIG_DIR" "$DEST_DIR"

echo ""
echo "✓ COSMIC configuration captured successfully!"
echo ""
echo "Next steps:"
echo "  1. Review the captured configuration in cosmic-config/"
echo "  2. Remove any sensitive or machine-specific settings"
echo "  3. Commit the changes:"
echo "     git add cosmic-config/"
echo "     git commit -m 'feat(desktop): Add COSMIC configuration'"
echo ""
echo "To use this configuration, set in your inventory/vars:"
echo "  cosmic_sync_from_repo: true"
