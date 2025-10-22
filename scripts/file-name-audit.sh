#!/usr/bin/env bash

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Dependency check function
check_dependencies() {
    local missing_deps=()

    for cmd in gum bat fd rg; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done

    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo -e "${RED}ERROR: Missing required dependencies:${NC}"
        for dep in "${missing_deps[@]}"; do
            echo -e "  ${YELLOW}•${NC} $dep"
        done
        echo ""
        echo "Please install missing dependencies:"
        echo "  • gum: https://github.com/charmbracelet/gum"
        echo "  • bat: https://github.com/sharkdp/bat"
        echo "  • fd: https://github.com/sharkdp/fd"
        echo "  • ripgrep (rg): https://github.com/BurntSushi/ripgrep"
        exit 1
    fi
}

# Check if path is inside a git repository
is_in_git_repo() {
    local path="$1"
    local check_path

    if [ -f "$path" ]; then
        check_path=$(dirname "$path")
    else
        check_path="$path"
    fi

    # Check if the path or any parent directory contains .git
    (cd "$check_path" && git rev-parse --git-dir &>/dev/null)
}

# Check if file is a code file based on extension
is_code_file() {
    local file="$1"
    local extension="${file##*.}"

    # Return false if no extension
    if [ "$extension" = "$file" ]; then
        return 1
    fi

    # Convert extension to lowercase for comparison
    extension=$(echo "$extension" | tr '[:upper:]' '[:lower:]')

    # List of code file extensions
    local code_extensions=(
        # Programming languages
        "sh" "bash" "zsh" "fish"
        "py" "pyc" "pyw" "pyx" "pyi"
        "js" "jsx" "ts" "tsx" "mjs" "cjs"
        "java" "class" "jar"
        "c" "h" "cpp" "hpp" "cc" "cxx" "hxx"
        "cs" "vb" "fs" "fsx"
        "go" "rs" "swift" "kt" "kts" "scala"
        "rb" "erb" "php" "pl" "pm" "lua" "r"
        "m" "mm" "dart" "elm" "ex" "exs" "eex"
        "clj" "cljs" "edn" "zig" "nim" "v"
        # Web
        "html" "htm" "css" "scss" "sass" "less" "styl"
        "vue" "svelte" "astro" "mdx"
        # Config/Data formats
        "json" "json5" "jsonc"
        "yaml" "yml"
        "toml"
        "xml" "xsl" "xslt"
        "ini" "conf" "cfg" "config"
        "env" "envrc" "environment"
        "properties" "props"
        "nix"
        "tf" "tfvars" "hcl"
        "graphql" "gql"
        # Markdown/Documentation
        "md" "markdown" "rst" "adoc" "asciidoc"
        # Build/Package/Lock files
        "makefile" "mk" "cmake" "gradle" "maven" "ant"
        "lock" "sum" "shrinkwrap"
        "cabal" "opam"
        # Scripts/Shell
        "ps1" "psm1" "psd1" "bat" "cmd"
        # Database
        "sql" "psql" "mysql" "db" "sqlite" "sqlite3"
        # Version control/Git
        "gitignore" "gitattributes" "gitmodules" "gitconfig"
        "dockerignore" "editorconfig" "eslintrc" "prettierrc"
        "hgignore" "bzrignore"
        # Docker/Container
        "dockerfile" "containerfile"
        # CI/CD
        "travis" "jenkinsfile" "circleci"
        # Package managers
        "npmrc" "yarnrc" "gemfile" "podfile" "cartfile"
        "requirements" "pipfile"
        # Misc config
        "vimrc" "nvimrc" "bashrc" "zshrc" "tmux"
    )

    for ext in "${code_extensions[@]}"; do
        if [ "$extension" = "$ext" ]; then
            return 0
        fi
    done

    return 1
}

# Convert string to Word-word-word format
# First word capitalized, rest lowercase, separated by hyphens
# Preserves existing number sequences and date formats
to_standardized_format() {
    local input="$1"
    local output

    # Remove leading/trailing whitespace
    output=$(echo "$input" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

    # Remove special Unicode control/invisible characters (don't convert to hyphen, just delete)
    # Includes: zero-width spaces, object replacement char, etc.
    # Use LC_ALL=C to handle as bytes, then remove specific problematic UTF-8 sequences
    output=$(echo "$output" | LC_ALL=C sed -e 's/\xEF\xBF\xBC//g' -e 's/\xE2\x80\x8B//g' -e 's/\xE2\x80\x8C//g' -e 's/\xE2\x80\x8D//g')

    # Handle camelCase by inserting hyphens before uppercase letters
    # This catches: fileFolder -> file-Folder, myBigFile -> my-Big-File
    output=$(echo "$output" | sed -e 's/\([a-z]\)\([A-Z]\)/\1-\2/g')

    # Insert hyphen between number and letter: 20251001MyFolder -> 20251001-MyFolder
    output=$(echo "$output" | sed -e 's/\([0-9]\)\([A-Za-z]\)/\1-\2/g')

    # Insert hyphen between letter and number (but preserve existing date formats)
    output=$(echo "$output" | sed -e 's/\([A-Za-z]\)\([0-9]\)/\1-\2/g')

    # Replace spaces, underscores, and dots with hyphens
    output=$(echo "$output" | sed -e 's/[[:space:]_.]\+/-/g')

    # Remove remaining special characters except hyphens and alphanumerics (convert to hyphen)
    output=$(echo "$output" | sed -e 's/[^a-zA-Z0-9-]/-/g')

    # Replace multiple hyphens with single hyphen
    output=$(echo "$output" | sed -e 's/-\+/-/g')

    # Remove leading/trailing hyphens
    output=$(echo "$output" | sed -e 's/^-*//' -e 's/-*$//')

    # Convert to lowercase
    output=$(echo "$output" | tr '[:upper:]' '[:lower:]')

    # Capitalize ONLY the first character (if it's a letter)
    output=$(echo "$output" | sed -e 's/^\([a-z]\)/\U\1/')

    echo "$output"
}

# Get new name for file or directory
get_new_name() {
    local path="$1"
    local basename
    local dirname
    local extension=""
    local name_without_ext
    local new_name

    basename=$(basename "$path")
    dirname=$(dirname "$path")

    # Check if it's a file with extension
    if [[ -f "$path" && "$basename" == *.* ]]; then
        extension="${basename##*.}"
        name_without_ext="${basename%.*}"
        # Convert extension to lowercase
        extension=$(echo "$extension" | tr '[:upper:]' '[:lower:]')
        new_name="$(to_standardized_format "$name_without_ext").$extension"
    else
        new_name="$(to_standardized_format "$basename")"
    fi

    echo "$dirname/$new_name"
}

# Preview rename operation
preview_rename() {
    local old_path="$1"
    local new_path="$2"
    local old_basename
    local new_basename

    old_basename=$(basename "$old_path")
    new_basename=$(basename "$new_path")

    if [ "$old_basename" = "$new_basename" ]; then
        return 1  # No change needed
    fi

    gum style \
        --border rounded \
        --border-foreground 33 \
        --padding "1 2" \
        --margin "1 0" \
        "$(gum style --foreground 196 "OLD: $old_basename")" \
        "$(gum style --foreground 82 "NEW: $new_basename")" \
        "" \
        "$(gum style --foreground 240 "Full path: $(dirname "$old_path")/")"

    return 0
}

# Safely rename file or directory
safe_rename() {
    local old_path="$1"
    local new_path="$2"
    local old_basename
    local new_basename
    local temp_path

    old_basename=$(basename "$old_path")
    new_basename=$(basename "$new_path")

    # Handle case-only changes on case-sensitive filesystems
    # We need to check if the paths differ only in case
    if [ "$old_path" != "$new_path" ] && [ "$(echo "$old_basename" | tr '[:upper:]' '[:lower:]')" = "$(echo "$new_basename" | tr '[:upper:]' '[:lower:]')" ]; then
        # Case-only change detected - use temporary name to avoid conflicts
        temp_path="${old_path}.tmp.$$"

        gum style --foreground 240 "Case-only change detected, using temporary rename..."

        # First rename to temp
        if ! mv -n -- "$old_path" "$temp_path" 2>/dev/null; then
            gum style --foreground 196 "✗ Failed to rename to temporary path"
            return 1
        fi

        # Then rename temp to final
        if ! mv -n -- "$temp_path" "$new_path" 2>/dev/null; then
            gum style --foreground 196 "✗ Failed to rename from temporary path"
            # Try to restore original
            mv -n -- "$temp_path" "$old_path" 2>/dev/null || true
            return 1
        fi

        gum style --foreground 82 "✓ Renamed successfully (case-only change)"
        return 0
    fi

    # Check if target already exists (and it's not just a case difference)
    if [ -e "$new_path" ] && [ "$old_path" != "$new_path" ]; then
        gum style \
            --foreground 196 \
            --bold \
            "⚠️  TARGET ALREADY EXISTS: $new_path"
        gum style --foreground 240 "Skipping to avoid overwrite..."
        return 1
    fi

    # Perform rename (normal case)
    if mv -n -- "$old_path" "$new_path" 2>/dev/null; then
        gum style --foreground 82 "✓ Renamed successfully"
        return 0
    else
        gum style --foreground 196 "✗ Failed to rename"
        return 1
    fi
}

# Process directory (non-recursive for this level)
process_directory() {
    local dir="$1"
    local depth="$2"

    gum style \
        --border double \
        --border-foreground 214 \
        --padding "1 2" \
        --margin "1 0" \
        --bold \
        "Processing directory: $dir" \
        "Depth: $depth"

    # Get all items in directory, sorted by type (directories first, then files)
    local items=()

    # Get directories first (excluding hidden unless they contain non-hidden items)
    while IFS= read -r -d '' item; do
        # Clean up fd output: remove ./ prefix and trailing /
        item="${item#./}"
        item="${item%/}"
        items+=("$item")
    done < <(fd -d 1 -t d -0 --base-directory "$dir" 2>/dev/null | sort -z)

    # Then get files
    while IFS= read -r -d '' item; do
        # Clean up fd output: remove ./ prefix
        item="${item#./}"
        items+=("$item")
    done < <(fd -d 1 -t f -0 --base-directory "$dir" 2>/dev/null | sort -z)

    if [ ${#items[@]} -eq 0 ]; then
        gum style --foreground 240 "No items found in directory"
        return
    fi

    # Process each item
    for item in "${items[@]}"; do
        local full_path="$dir/$item"
        local new_path

        # Skip files without extensions (likely code/scripts) - fast check, no file I/O
        if [ -f "$full_path" ] && [[ "$item" != *.* ]]; then
            gum style --foreground 240 "⊘ Skipped - file without extension: $item"
            continue
        fi

        # Skip code files (only checked if it has an extension)
        if [ -f "$full_path" ] && is_code_file "$full_path"; then
            gum style --foreground 240 "⊘ Skipped - code file: $item"
            continue
        fi

        # Skip if inside git repo
        if is_in_git_repo "$full_path"; then
            gum style --foreground 240 "⊘ Skipped - inside git repository: $item"
            continue
        fi

        new_path=$(get_new_name "$full_path")

        # Check if rename is needed
        local needs_rename=false
        if [ "$full_path" != "$new_path" ]; then
            needs_rename=true
        fi

        # If it's a file and doesn't need rename, skip it
        if [ -f "$full_path" ] && [ "$needs_rename" = false ]; then
            continue
        fi

        # If it's a directory and doesn't need rename, still offer to process contents
        if [ -d "$full_path" ] && [ "$needs_rename" = false ]; then
            if [ "$RECURSIVE" = true ]; then
                gum style --foreground 240 "Folder name already correct: $item"
                if confirm "Process contents of this folder recursively?"; then
                    process_directory "$full_path" $((depth + 1))
                fi
            fi
            echo ""
            continue
        fi

        # Preview the change (only if rename is needed)
        if ! preview_rename "$full_path" "$new_path"; then
            continue
        fi

        # Ask for confirmation
        if confirm "Rename this $([ -d "$full_path" ] && echo "folder" || echo "file")?"; then
            if safe_rename "$full_path" "$new_path"; then
                # If it was a directory and was renamed, process it recursively with new path (if recursive mode enabled)
                if [ -d "$new_path" ] && [ "$RECURSIVE" = true ]; then
                    if confirm "Process contents of this folder recursively?"; then
                        process_directory "$new_path" $((depth + 1))
                    fi
                fi
            fi
        else
            gum style --foreground 240 "Skipped"

            # Still offer to process directory contents even if not renaming (if recursive mode enabled)
            if [ -d "$full_path" ] && [ "$RECURSIVE" = true ]; then
                if confirm "Process contents of this folder recursively?"; then
                    process_directory "$full_path" $((depth + 1))
                fi
            fi
        fi

        echo ""
    done
}

# Process a single file
process_single_file() {
    local file_path="$1"
    local basename=$(basename "$file_path")
    local new_path

    # Skip files without extensions (likely code/scripts)
    if [[ "$basename" != *.* ]]; then
        gum style --foreground 240 "⊘ Skipped - file without extension"
        return 0
    fi

    # Check if it's a code file
    if is_code_file "$file_path"; then
        gum style --foreground 240 "⊘ Skipped - code file"
        return 0
    fi

    # Check if inside git repo
    if is_in_git_repo "$file_path"; then
        gum style --foreground 240 "⊘ Skipped - inside git repository"
        return 0
    fi

    new_path=$(get_new_name "$file_path")

    # Skip if no change needed
    if [ "$file_path" = "$new_path" ]; then
        gum style --foreground 240 "No changes needed - filename is already correct"
        return 0
    fi

    # Preview the change
    if ! preview_rename "$file_path" "$new_path"; then
        gum style --foreground 240 "No changes needed - filename is already correct"
        return 0
    fi

    # Ask for confirmation
    if confirm "Rename this file?"; then
        if safe_rename "$file_path" "$new_path"; then
            return 0
        else
            return 1
        fi
    else
        gum style --foreground 240 "Skipped"
        return 0
    fi
}

# Global variables
RECURSIVE=true
AUTO_CONFIRM=false

# Helper function for confirmations
confirm() {
    local message="$1"

    if [ "$AUTO_CONFIRM" = true ]; then
        return 0  # Always return success (yes)
    else
        gum confirm "$message"
    fi
}

# Main function
main() {
    local target=""
    local target_dir
    local target_file=""

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -n|--no-recursive)
                RECURSIVE=false
                shift
                ;;
            -y|--yes)
                AUTO_CONFIRM=true
                shift
                ;;
            -h|--help)
                echo "Usage: $0 [options] <target>"
                echo ""
                echo "Options:"
                echo "  -n, --no-recursive    Process only current directory (not subdirectories)"
                echo "  -y, --yes            Auto-confirm all changes (no prompts)"
                echo "  -h, --help           Show this help message"
                echo ""
                echo "Arguments:"
                echo "  target               File or directory to process (required)"
                exit 0
                ;;
            -*)
                echo "Unknown option: $1"
                echo "Use -h or --help for usage information"
                exit 1
                ;;
            *)
                target="$1"
                shift
                ;;
        esac
    done

    # Require target argument
    if [ -z "$target" ]; then
        echo "Error: Target path is required"
        echo ""
        echo "Usage: $0 [options] <target>"
        echo "Use -h or --help for more information"
        exit 1
    fi

    # Clean up target path: remove trailing slashes and dots
    # This handles paths like "folder/.", "folder/", "folder//", etc.
    while [[ "$target" == */ ]] || [[ "$target" == */. ]]; do
        target="${target%/}"
        target="${target%/.}"
    done

    # Check dependencies first
    check_dependencies

    # Check if target is a file or directory
    if [ -f "$target" ]; then
        # It's a file - process single file
        target_file=$(realpath "$target")
        target_dir=$(dirname "$target_file")

        # Show welcome message for single file
        gum style \
            --border thick \
            --border-foreground 213 \
            --padding "2 4" \
            --margin "2" \
            --bold \
            "FILE NAME AUDIT TOOL" \
            "" \
            "$(gum style --foreground 240 "Target file: $target_file")" \
            "" \
            "This tool will help you rename this file to Word-word-word format." \
            "$([ "$AUTO_CONFIRM" = true ] && echo "Auto-confirm mode: All changes will be applied automatically." || echo "You'll be asked to confirm the change.")"

        if ! confirm "Start processing?"; then
            gum style --foreground 240 "Cancelled by user"
            exit 0
        fi

        echo ""
        process_single_file "$target_file"

        # Show completion message
        echo ""
        gum style \
            --border rounded \
            --border-foreground 82 \
            --padding "1 2" \
            --margin "1 0" \
            --bold \
            "✓ Processing complete!"

        exit 0

    elif [ -d "$target" ]; then
        # It's a directory - resolve to absolute path
        target_dir=$(cd "$target" && pwd)

    else
        gum style \
            --foreground 196 \
            --bold \
            "ERROR: Target does not exist: $target"
        exit 1
    fi

    # Show welcome message for directory
    gum style \
        --border thick \
        --border-foreground 213 \
        --padding "2 4" \
        --margin "2" \
        --bold \
        "FILE NAME AUDIT TOOL" \
        "" \
        "$(gum style --foreground 240 "Target directory: $target_dir")" \
        "" \
        "This tool will help you rename files and folders to Word-word-word format." \
        "$([ "$AUTO_CONFIRM" = true ] && echo "Auto-confirm mode: All changes will be applied automatically." || echo "You'll be asked to confirm each change individually.")"

    if ! confirm "Start processing?"; then
        gum style --foreground 240 "Cancelled by user"
        exit 0
    fi

    echo ""

    # Start processing directory
    process_directory "$target_dir" 0

    # Show completion message
    echo ""
    gum style \
        --border rounded \
        --border-foreground 82 \
        --padding "1 2" \
        --margin "1 0" \
        --bold \
        "✓ Processing complete!"
}

# Script entry point
main "$@"

