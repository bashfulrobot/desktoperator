#!/usr/bin/env bash
set -euo pipefail

# Generate Ansible color variables from COSMIC themes
# Extracts both Dark and Light themes and creates auto-colors.yml for Ansible

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_FILE="${REPO_ROOT}/group_vars/all/auto-colors.yml"
COSMIC_CONFIG="${HOME}/.config/cosmic"

# Source the extraction functions from extract-cosmic-colors.sh
# shellcheck source=extract-cosmic-colors.sh
source "${SCRIPT_DIR}/extract-cosmic-colors.sh"

# Generate YAML for a single theme mode
# shellcheck disable=SC2034  # Variables used via indirect expansion ${!color_name}
generate_theme_yaml() {
    local mode="$1"  # "Dark" or "Light"
    local theme_dir="${COSMIC_CONFIG}/com.system76.CosmicTheme.${mode}/v1"

    if [[ ! -d "$theme_dir" ]]; then
        echo "Error: Theme directory not found: $theme_dir" >&2
        return 1
    fi

    # Extract colors from theme files
    # NOTE: For light theme, we use the dark theme's accent to maintain consistency
    # across light/dark modes (matching the window border accent color)
    # These variables are used via indirect expansion ${!color_name} in the loop below
    local accent success warning destructive background primary secondary
    if [[ "$mode" == "Light" ]]; then
        local dark_accent_path="${COSMIC_CONFIG}/com.system76.CosmicTheme.Dark/v1/accent"
        accent=$(extract_rgba_floats "$dark_accent_path")
    else
        accent=$(extract_rgba_floats "$theme_dir/accent")
    fi
    success=$(extract_rgba_floats "$theme_dir/success")
    warning=$(extract_rgba_floats "$theme_dir/warning")
    destructive=$(extract_rgba_floats "$theme_dir/destructive")
    background=$(extract_rgba_floats "$theme_dir/background")
    primary=$(extract_rgba_floats "$theme_dir/primary")
    secondary=$(extract_rgba_floats "$theme_dir/secondary")

    # Derive text colors with proper contrast
    # These variables are used via indirect expansion ${!color_name} in the loop below
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
        local rf gf bf af
        read -r rf gf bf af <<< "$rgba_floats"

        local rgb_ints
        rgb_ints=$(rgba_to_rgb "$rf" "$gf" "$bf" "$af")
        local r g b
        read -r r g b <<< "$rgb_ints"

        local hex
        hex=$(rgb_to_hex "$r" "$g" "$b")

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
# DO NOT EDIT MANUALLY - Run 'just generate-cosmic-colors' to regenerate

EOF

    # Generate Dark theme colors
    {
        generate_theme_yaml "Dark"
        echo ""
        # Generate Light theme colors
        generate_theme_yaml "Light"
    } >> "$OUTPUT_FILE"

    echo "✓ Generated color variables: $OUTPUT_FILE"
}

# Only run main if not being sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
