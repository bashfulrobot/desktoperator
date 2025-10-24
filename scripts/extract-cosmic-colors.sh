#!/usr/bin/env bash
set -euo pipefail

# Extract COSMIC theme colors and convert to multiple color formats
# Parses RON format from ~/.config/cosmic/com.system76.CosmicTheme.{Dark,Light}/v1/
# Outputs JSON with colors in hex, rgb, rgba, hsl, hsv, and cmyk formats

COSMIC_CONFIG="${HOME}/.config/cosmic"

# Check for jq dependency
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed" >&2
    echo "Install with: sudo apt install jq" >&2
    exit 1
fi

# Get active theme mode (Dark or Light)
get_active_mode() {
    local mode_file="${COSMIC_CONFIG}/com.system76.CosmicTheme.Mode/v1/is_dark"

    if [[ -f "$mode_file" ]] && grep -q "true" "$mode_file"; then
        echo "Dark"
    else
        echo "Light"
    fi
}

# Extract RGBA values from RON file (gets first/base color only)
# Returns: "r g b a" as floats (0.0-1.0)
extract_rgba_floats() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        echo "0.0 0.0 0.0 1.0"
        return
    fi

    local content
    content=$(cat "$file")

    # Extract first occurrence of each component
    local red
    red=$(echo "$content" | grep -m1 -oP 'red:\s*\K[0-9.]+' || echo "0.0")
    local green
    green=$(echo "$content" | grep -m1 -oP 'green:\s*\K[0-9.]+' || echo "0.0")
    local blue
    blue=$(echo "$content" | grep -m1 -oP 'blue:\s*\K[0-9.]+' || echo "0.0")
    local alpha
    alpha=$(echo "$content" | grep -m1 -oP 'alpha:\s*\K[0-9.]+' || echo "1.0")

    echo "$red $green $blue $alpha"
}

# Convert RGBA floats to RGB integers (0-255)
# Input: r g b a (floats)
# Output: r g b (integers)
rgba_to_rgb() {
    local r
    r=$(awk "BEGIN {printf \"%.0f\", $1 * 255}")
    local g
    g=$(awk "BEGIN {printf \"%.0f\", $2 * 255}")
    local b
    b=$(awk "BEGIN {printf \"%.0f\", $3 * 255}")
    echo "$r $g $b"
}

# Convert RGB (0-255) to Hex
rgb_to_hex() {
    printf "#%02x%02x%02x" "$1" "$2" "$3"
}

# Convert RGB (0-255) to HSL
# Returns: "h s l" where h is 0-360, s and l are 0-100
rgb_to_hsl() {
    awk -v r="$1" -v g="$2" -v b="$3" 'BEGIN {
        r = r / 255.0; g = g / 255.0; b = b / 255.0

        max = r; if (g > max) max = g; if (b > max) max = b
        min = r; if (g < min) min = g; if (b < min) min = b

        l = (max + min) / 2.0

        if (max == min) {
            h = 0; s = 0
        } else {
            d = max - min
            s = l > 0.5 ? d / (2.0 - max - min) : d / (max + min)

            if (max == r) {
                h = ((g - b) / d + (g < b ? 6 : 0)) / 6.0
            } else if (max == g) {
                h = ((b - r) / d + 2) / 6.0
            } else {
                h = ((r - g) / d + 4) / 6.0
            }
        }

        printf "%.0f %.0f %.0f", h * 360, s * 100, l * 100
    }'
}

# Convert RGB (0-255) to HSV
# Returns: "h s v" where h is 0-360, s and v are 0-100
rgb_to_hsv() {
    awk -v r="$1" -v g="$2" -v b="$3" 'BEGIN {
        r = r / 255.0; g = g / 255.0; b = b / 255.0

        max = r; if (g > max) max = g; if (b > max) max = b
        min = r; if (g < min) min = g; if (b < min) min = b

        v = max
        d = max - min
        s = max == 0 ? 0 : d / max

        if (max == min) {
            h = 0
        } else {
            if (max == r) {
                h = ((g - b) / d + (g < b ? 6 : 0)) / 6.0
            } else if (max == g) {
                h = ((b - r) / d + 2) / 6.0
            } else {
                h = ((r - g) / d + 4) / 6.0
            }
        }

        printf "%.0f %.0f %.0f", h * 360, s * 100, v * 100
    }'
}

# Convert RGB (0-255) to CMYK
# Returns: "c m y k" as percentages 0-100
rgb_to_cmyk() {
    awk -v r="$1" -v g="$2" -v b="$3" 'BEGIN {
        r = r / 255.0; g = g / 255.0; b = b / 255.0

        k = 1.0 - (r > g ? (r > b ? r : b) : (g > b ? g : b))

        if (k == 1.0) {
            c = 0; m = 0; y = 0
        } else {
            c = (1.0 - r - k) / (1.0 - k)
            m = (1.0 - g - k) / (1.0 - k)
            y = (1.0 - b - k) / (1.0 - k)
        }

        printf "%.0f %.0f %.0f %.0f", c * 100, m * 100, y * 100, k * 100
    }'
}

# Build complete color object with all formats
# Input: "r g b a" as floats
build_color_json() {
    local rgba_floats="$1"
    local rf gf bf af
    read -r rf gf bf af <<< "$rgba_floats"

    # Convert to RGB integers
    local rgb_ints
    rgb_ints=$(rgba_to_rgb "$rf" "$gf" "$bf" "$af")
    local r g b
    read -r r g b <<< "$rgb_ints"

    # Generate all formats
    local hex
    hex=$(rgb_to_hex "$r" "$g" "$b")
    local hsl
    hsl=$(rgb_to_hsl "$r" "$g" "$b")
    local h s l
    read -r h s l <<< "$hsl"
    local hsv
    hsv=$(rgb_to_hsv "$r" "$g" "$b")
    local hv sv vv
    read -r hv sv vv <<< "$hsv"
    local cmyk
    cmyk=$(rgb_to_cmyk "$r" "$g" "$b")
    local c m y k
    read -r c m y k <<< "$cmyk"

    # Build JSON object
    jq -n \
        --arg hex "$hex" \
        --arg rgb "rgb($r, $g, $b)" \
        --arg rgba "rgba($r, $g, $b, $af)" \
        --arg hsl "hsl($h, $s%, $l%)" \
        --arg hsv "hsv($hv, $sv%, $vv%)" \
        --arg cmyk "cmyk($c%, $m%, $y%, $k%)" \
        --argjson r "$r" \
        --argjson g "$g" \
        --argjson b "$b" \
        --argjson a "$af" \
        --argjson h "$h" \
        --argjson sl "$s" \
        --argjson ll "$l" \
        --argjson c "$c" \
        --argjson m "$m" \
        --argjson y "$y" \
        --argjson k "$k" \
        '{
            hex: $hex,
            rgb: {
                string: $rgb,
                r: $r,
                g: $g,
                b: $b
            },
            rgba: {
                string: $rgba,
                r: $r,
                g: $g,
                b: $b,
                a: $a
            },
            hsl: {
                string: $hsl,
                h: $h,
                s: $sl,
                l: $ll
            },
            hsv: {
                string: $hsv,
                h: $h,
                s: $sl,
                v: $ll
            },
            cmyk: {
                string: $cmyk,
                c: $c,
                m: $m,
                y: $y,
                k: $k
            }
        }'
}

main() {
    local force_mode="${1:-}"  # Optional argument: "Dark" or "Light"

    if [[ ! -d "$COSMIC_CONFIG" ]]; then
        echo "Error: COSMIC config directory not found at $COSMIC_CONFIG" >&2
        exit 1
    fi

    # Determine theme mode
    local mode
    if [[ -n "$force_mode" ]]; then
        mode="$force_mode"
    else
        mode=$(get_active_mode)
    fi

    local theme_dir="${COSMIC_CONFIG}/com.system76.CosmicTheme.${mode}/v1"

    if [[ ! -d "$theme_dir" ]]; then
        echo "Error: Theme directory not found: $theme_dir" >&2
        exit 1
    fi

    # Extract colors from theme files
    local accent
    accent=$(extract_rgba_floats "$theme_dir/accent")
    local success
    success=$(extract_rgba_floats "$theme_dir/success")
    local warning
    warning=$(extract_rgba_floats "$theme_dir/warning")
    local destructive
    destructive=$(extract_rgba_floats "$theme_dir/destructive")
    local background
    background=$(extract_rgba_floats "$theme_dir/background")
    local primary
    primary=$(extract_rgba_floats "$theme_dir/primary")
    local secondary
    secondary=$(extract_rgba_floats "$theme_dir/secondary")

    # Build metadata
    local theme_name="cosmic-${mode,,}"
    local is_dark="false"
    [[ "$mode" == "Dark" ]] && is_dark="true"

    # Output JSON
    jq -n \
        --arg name "$theme_name" \
        --arg mode "$mode" \
        --argjson is_dark "$is_dark" \
        --argjson accent "$(build_color_json "$accent")" \
        --argjson success "$(build_color_json "$success")" \
        --argjson warning "$(build_color_json "$warning")" \
        --argjson destructive "$(build_color_json "$destructive")" \
        --argjson background "$(build_color_json "$background")" \
        --argjson primary "$(build_color_json "$primary")" \
        --argjson secondary "$(build_color_json "$secondary")" \
        '{
            metadata: {
                name: $name,
                mode: $mode,
                is_dark: $is_dark,
                generated: (now | strftime("%Y-%m-%d %H:%M:%S"))
            },
            colors: {
                accent: $accent,
                success: $success,
                warning: $warning,
                destructive: $destructive,
                background: $background,
                primary: $primary,
                secondary: $secondary
            }
        }'
}

main "$@"
