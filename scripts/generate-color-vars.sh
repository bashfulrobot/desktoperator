#!/usr/bin/env bash
set -euo pipefail

# Generate Ansible color variables from COSMIC themes
# Extracts both Dark and Light themes and creates auto-colors.yml for Ansible

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_FILE="${REPO_ROOT}/group_vars/all/auto-colors.yml"
COSMIC_CONFIG="${HOME}/.config/cosmic"

# Source the extraction functions from extract-cosmic-colors.sh
source "${SCRIPT_DIR}/extract-cosmic-colors.sh"

# Generate YAML for a single theme mode
generate_theme_yaml() {
    local mode="$1"  # "Dark" or "Light"
    local theme_dir="${COSMIC_CONFIG}/com.system76.CosmicTheme.${mode}/v1"

    if [[ ! -d "$theme_dir" ]]; then
        echo "Error: Theme directory not found: $theme_dir" >&2
        return 1
    fi

    # Extract colors from theme files
    local accent=$(extract_rgba_floats "$theme_dir/accent")
    local success=$(extract_rgba_floats "$theme_dir/success")
    local warning=$(extract_rgba_floats "$theme_dir/warning")
    local destructive=$(extract_rgba_floats "$theme_dir/destructive")
    local background=$(extract_rgba_floats "$theme_dir/background")
    local primary=$(extract_rgba_floats "$theme_dir/primary")
    local secondary=$(extract_rgba_floats "$theme_dir/secondary")

    # Derive text colors with proper contrast
    local text_primary text_secondary text_tertiary
    if [[ "$mode" == "Dark" ]]; then
        text_primary="0.878 0.878 0.878 1.0"      # #e0e0e0 - main text
        text_secondary="0.565 0.565 0.565 1.0"    # #909090 - comments/muted
        text_tertiary="0.502 0.502 0.502 1.0"     # #808080 - inactive
    else
        text_primary="0.125 0.125 0.125 1.0"      # #202020 - main text
        text_secondary="0.314 0.314 0.314 1.0"    # #505050 - comments/muted
        text_tertiary="0.439 0.439 0.439 1.0"     # #707070 - inactive
    fi

    # Convert to RGB and hex for each color
    local colors=("accent" "success" "warning" "destructive" "background" "primary" "secondary" "text_primary" "text_secondary" "text_tertiary")

    # Build YAML output
    local yaml_key="theme_colors_${mode,,}"
    echo "${yaml_key}:"
    echo "  colors:"

    for color_name in "${colors[@]}"; do
        local rgba_floats="${!color_name}"
        read -r rf gf bf af <<< "$rgba_floats"

        local rgb_ints=$(rgba_to_rgb $rf $gf $bf $af)
        read -r r g b <<< "$rgb_ints"

        local hex=$(rgb_to_hex $r $g $b)

        echo "    ${color_name}:"
        echo "      hex: \"${hex}\""
        echo "      r: ${r}"
        echo "      g: ${g}"
        echo "      b: ${b}"
    done
}

main() {
    if [[ ! -d "$COSMIC_CONFIG" ]]; then
        echo "Error: COSMIC config directory not found at $COSMIC_CONFIG" >&2
        exit 1
    fi

    # Ensure output directory exists
    mkdir -p "$(dirname "$OUTPUT_FILE")"

    # Generate YAML header
    cat > "$OUTPUT_FILE" <<EOF
---
# Auto-generated COSMIC theme color variables
# Generated: $(date '+%Y-%m-%d %H:%M:%S')
# DO NOT EDIT MANUALLY - Run 'just colors' to regenerate

EOF

    # Generate Dark theme colors
    generate_theme_yaml "Dark" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"

    # Generate Light theme colors
    generate_theme_yaml "Light" >> "$OUTPUT_FILE"

    echo "✓ Generated color variables: $OUTPUT_FILE"
}

# Only run main if not being sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
