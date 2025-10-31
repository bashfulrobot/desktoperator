# Pake wrapper function that automatically converts icons to RGBA format
# This fixes Tauri's requirement for RGBA PNGs which Pake sometimes doesn't provide

function create-web-app --description 'Build desktop apps from websites using Pake (auto-fixes icon format)'
    # Get the pake binary path
    set -l pake_bin ~/.local/bin/pake

    # If pake isn't installed in the expected location, try to find it
    if not test -x $pake_bin
        set pake_bin (command -v pake)
        if test -z "$pake_bin"
            echo "Error: pake command not found. Install it first with: npm install -g pake-cli"
            return 1
        end
    end

    # Run pake with all arguments
    $pake_bin $argv
    set -l pake_result $status

    # Find and convert any non-RGBA PNG icons in pake's directory
    set -l pake_png_dir ~/.local/lib/node_modules/pake-cli/src-tauri/png
    if test -d $pake_png_dir
        for png in $pake_png_dir/*.png
            if test -f "$png"
                # Check if the PNG is not RGBA
                if file "$png" | grep -q "PNG image data" | grep -qv "RGBA"
                    echo "Converting $png to RGBA format..."
                    convert "$png" -alpha set "$png"
                end
            end
        end
    end

    # If pake failed due to icon format, try rebuilding
    if test $pake_result -ne 0
        # Check if there are any PNGs that needed conversion
        if test -d $pake_png_dir
            set -l converted 0
            for png in $pake_png_dir/*.png
                if test -f "$png"
                    # Ensure all PNGs are RGBA
                    if not file "$png" | grep -q "RGBA"
                        convert "$png" -alpha set "$png"
                        set converted 1
                    end
                end
            end

            # If we converted any icons, retry the build
            if test $converted -eq 1
                echo "Retrying build with converted RGBA icons..."
                cd ~/.local/lib/node_modules/pake-cli
                pnpm run build -c src-tauri/.pake/tauri.conf.json --features cli-build
                return $status
            end
        end
    end

    return $pake_result
end
