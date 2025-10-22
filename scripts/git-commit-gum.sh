#!/usr/bin/env bash

# git-commit-gum - Interactive git commit with gum
# Creates conventional commits with emoji support
#
# This script uses gum to provide an interactive commit experience
# following the conventional commits specification with emoji prefixes.

set -euo pipefail

# Emoji mapping for commit types
declare -A EMOJIS=(
    ["fix"]="🐛"
    ["feat"]="✨"
    ["docs"]="📝"
    ["style"]="💄"
    ["refactor"]="♻️"
    ["test"]="✅"
    ["chore"]="🔧"
    ["revert"]="⏪"
    ["perf"]="⚡"
    ["build"]="👷"
    ["ci"]="💚"
)

# Check if gum is installed
if ! command -v gum &> /dev/null; then
    echo "Error: gum is not installed. Install it from https://github.com/charmbracelet/gum"
    exit 1
fi

# Choose commit type
TYPE=$(gum choose "fix" "feat" "docs" "style" "refactor" "test" "chore" "revert" "perf" "build" "ci")

# Get the emoji for this type
EMOJI="${EMOJIS[$TYPE]}"

# Get scope (optional)
SCOPE=$(gum input --placeholder "scope (optional, press enter to skip)")

# Build the prefix
if [ -n "$SCOPE" ]; then
    PREFIX="$TYPE($SCOPE)"
else
    PREFIX="$TYPE"
fi

# Pre-populate the input with emoji and type
SUMMARY=$(gum input --value "$EMOJI $PREFIX: " --placeholder "Summary of this change" --width 80)

# Get detailed description (optional)
DESCRIPTION=$(gum write --placeholder "Details of this change (optional, Ctrl+D to finish)" --width 80 --height 10)

# Show preview
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Commit Preview:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "$SUMMARY"
if [ -n "$DESCRIPTION" ]; then
    echo ""
    echo "$DESCRIPTION"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Confirm and commit
if gum confirm "Commit these changes?"; then
    if [ -n "$DESCRIPTION" ]; then
        git commit -m "$SUMMARY" -m "$DESCRIPTION"
    else
        git commit -m "$SUMMARY"
    fi
    echo "✓ Commit created successfully!"
else
    echo "Commit cancelled."
    exit 1
fi
