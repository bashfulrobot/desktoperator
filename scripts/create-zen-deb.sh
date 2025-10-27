#!/bin/bash
set -euo pipefail

# === CONFIG ===
PACKAGE_NAME="zen-browser"
ARCH="amd64"
DISTRIBUTIONS=("noble" "jammy")
MAINTAINER="Dustin Krysak <dustin@bashfulrobot.com>"
PPA="ppa:bashfulrobot/zen-browser"
GITHUB_REPO="zen-browser/desktop"

# PPA Version Format: <upstream>-<debian>~<distro><distro-rev>
# Example: 1.17.3b-2~noble1
#   - upstream: 1.17.3b (from GitHub release tag)
#   - debian: 2 (packaging revision, auto-incremented for rebuilds)
#   - distro: noble (Ubuntu release codename)
#   - distro-rev: 1 (always 1, allows per-distro builds)
#
# The tilde (~) ensures PPA packages sort BEFORE official Ubuntu packages,
# so if Ubuntu ships zen-browser-1.17.3b-2ubuntu1, it supersedes our PPA.
#
# DEBIAN_REVISION is calculated dynamically by querying Launchpad:
#   - New upstream version → revision 1
#   - Forced rebuild of same version → increment revision

# === PARSE ARGUMENTS ===
FORCE_BUILD=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --force|-f)
            FORCE_BUILD=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Build and upload Zen Browser packages to PPA"
            echo ""
            echo "Options:"
            echo "  --force, -f    Force rebuild even if PPA has latest version"
            echo "  --help, -h     Show this help message"
            echo ""
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Run '$0 --help' for usage information"
            exit 1
            ;;
    esac
done

# === HELPER FUNCTIONS ===
header() {
    gum style \
        --foreground 212 \
        --border-foreground 212 \
        --border double \
        --align center \
        --width 60 \
        --margin "1 0" \
        --padding "1 2" \
        "$1"
}

success() {
    gum style --foreground 10 "✓ $1"
}

error() {
    gum style --foreground 9 "✗ $1"
    exit 1
}

info() {
    gum style --foreground 14 "→ $1"
}

section() {
    gum style \
        --foreground 14 \
        --bold \
        --margin "1 0 0 0" \
        "$1"
}

# Check for required tools and install if missing
MISSING_TOOLS=()
for tool in debuild dput gpg curl jq wget gum; do
  if ! command -v "$tool" &>/dev/null; then
    MISSING_TOOLS+=("$tool")
  fi
done

if [ ${#MISSING_TOOLS[@]} -gt 0 ]; then
    section "Missing Required Tools"
    info "The following tools are missing: ${MISSING_TOOLS[*]}"
    echo ""

    INSTALL_PACKAGES=()
    for tool in "${MISSING_TOOLS[@]}"; do
        case "$tool" in
            debuild|dput) INSTALL_PACKAGES+=("devscripts" "debhelper") ;;
            gpg) INSTALL_PACKAGES+=("gnupg") ;;
            gum) INSTALL_PACKAGES+=("gum") ;;
            *) INSTALL_PACKAGES+=("$tool") ;;
        esac
    done

    # Remove duplicates
    INSTALL_PACKAGES=($(echo "${INSTALL_PACKAGES[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))

    info "Installing: ${INSTALL_PACKAGES[*]}"
    echo ""

    gum spin --spinner dot --title "Updating package lists..." -- sudo apt update
    gum spin --spinner dot --title "Installing packages..." -- \
        sudo apt install -y "${INSTALL_PACKAGES[@]}"

    # Verify installation succeeded
    for tool in debuild dput gpg curl jq wget gum; do
        if ! command -v "$tool" &>/dev/null; then
            error "Failed to install '$tool'"
        fi
    done

    echo ""
    success "All required tools installed successfully"
    echo ""
fi

# Create temporary working directory
WORK_DIR=$(mktemp -d -t zen-build-XXXXXX)
header "🧘 Zen Browser DEB Package Builder"
info "Working directory: $WORK_DIR"
echo ""

# === FETCH LATEST RELEASE INFO FROM GITHUB ===
section "Fetching Latest Release"

GITHUB_API="https://api.github.com/repos/${GITHUB_REPO}/releases/latest"
RELEASE_JSON=$(gum spin --spinner dot --title "Querying GitHub API..." -- \
    curl -sL "$GITHUB_API")

# Extract version (tag_name)
VERSION=$(echo "$RELEASE_JSON" | jq -r '.tag_name')
if [ -z "$VERSION" ] || [ "$VERSION" = "null" ]; then
    error "Failed to fetch latest version from GitHub"
fi

# Find the Linux x86_64 tarball asset
TARBALL_URL=$(echo "$RELEASE_JSON" | jq -r '.assets[] | select(.name | contains("linux-x86_64") and endswith(".tar.xz")) | .browser_download_url')
TARBALL=$(basename "$TARBALL_URL")

if [ -z "$TARBALL_URL" ] || [ "$TARBALL_URL" = "null" ]; then
    error "Failed to find Linux x86_64 tarball in latest release"
fi

gum style \
    --border rounded \
    --border-foreground 14 \
    --padding "1 2" \
    --margin "1 0" \
    "$(gum style --foreground 11 --bold "Version:") $(gum style --foreground 15 "$VERSION")
$(gum style --foreground 11 --bold "Tarball:") $(gum style --foreground 15 "$TARBALL")
$(gum style --foreground 11 --bold "URL:") $(gum style --foreground 8 "$TARBALL_URL")"

# === CHECK PPA VERSION AND DETERMINE DEBIAN REVISION ===
section "Checking PPA Version"

PPA_API="https://api.launchpad.net/1.0/~bashfulrobot/+archive/ubuntu/zen-browser?ws.op=getPublishedSources"
PPA_JSON=$(gum spin --spinner dot --title "Querying Launchpad PPA API..." -- \
    curl -sL "$PPA_API" || echo '{}')

PPA_UPSTREAM_VERSION=""
PPA_DEBIAN_REVISION=""
PPA_FULL_VERSION=""

# Get the latest published version for our package
PPA_FULL_VERSION=$(echo "$PPA_JSON" | \
    jq -r --arg pkg "$PACKAGE_NAME" '.entries[]? | select(.source_package_name == $pkg and .status == "Published") | .source_package_version' | \
    head -1 || echo "")

if [ -n "$PPA_FULL_VERSION" ] && [ "$PPA_FULL_VERSION" != "null" ]; then
    # Extract upstream version (everything before first dash)
    PPA_UPSTREAM_VERSION=$(echo "$PPA_FULL_VERSION" | sed 's/-[0-9]*~.*$//')
    # Extract debian revision (number between dash and tilde)
    PPA_DEBIAN_REVISION=$(echo "$PPA_FULL_VERSION" | grep -oP '(?<=-)[0-9]+(?=~)' || echo "")

    success "Latest PPA version: $PPA_FULL_VERSION"
    info "  Upstream: $PPA_UPSTREAM_VERSION"
    info "  Debian revision: $PPA_DEBIAN_REVISION"
fi

# Compare versions and decide whether to proceed
echo ""
if [ -z "$PPA_UPSTREAM_VERSION" ]; then
    # First build ever - use revision 1
    DEBIAN_REVISION="1"
    gum style \
        --border rounded \
        --border-foreground 10 \
        --padding "1 2" \
        --margin "1 0" \
        "$(gum style --foreground 10 --bold "🆕 First build for this PPA")

$(gum style --foreground 11 "GitHub version:") $(gum style --foreground 15 "$VERSION")
$(gum style --foreground 11 "Package version:") $(gum style --foreground 15 "$VERSION-$DEBIAN_REVISION")"

elif [ "$PPA_UPSTREAM_VERSION" = "$VERSION" ]; then
    # Same upstream version exists
    if [ "$FORCE_BUILD" = true ]; then
        # Forced rebuild - increment Debian revision
        DEBIAN_REVISION=$((PPA_DEBIAN_REVISION + 1))
        gum style \
            --border rounded \
            --border-foreground 11 \
            --padding "1 2" \
            --margin "1 0" \
            "$(gum style --foreground 11 --bold "🔨 Force rebuild with new packaging")

$(gum style --foreground 11 "Upstream version:") $(gum style --foreground 15 "$VERSION")
$(gum style --foreground 11 "Previous package:") $(gum style --foreground 8 "$VERSION-$PPA_DEBIAN_REVISION")
$(gum style --foreground 11 "New package:") $(gum style --foreground 10 "$VERSION-$DEBIAN_REVISION")

$(gum style --foreground 8 "Rebuilding with incremented Debian revision...")"
    else
        # Same version, not forced - skip build
        gum style \
            --border rounded \
            --border-foreground 3 \
            --padding "1 2" \
            --margin "1 0" \
            "$(gum style --foreground 3 --bold "⏭  No update needed")

$(gum style --foreground 11 "GitHub version:") $(gum style --foreground 15 "$VERSION")
$(gum style --foreground 11 "PPA version:") $(gum style --foreground 15 "$PPA_FULL_VERSION")

$(gum style --foreground 8 "The PPA already has this upstream version.")
$(gum style --foreground 8 "Use --force to rebuild with new packaging revision.")"

        echo ""
        info "Cleaning up work directory: $WORK_DIR"
        rm -rf "$WORK_DIR"
        exit 0
    fi
else
    # New upstream version - always use revision 1
    DEBIAN_REVISION="1"
    gum style \
        --border rounded \
        --border-foreground 10 \
        --padding "1 2" \
        --margin "1 0" \
        "$(gum style --foreground 10 --bold "🆕 New upstream version available!")

$(gum style --foreground 11 "Current PPA:") $(gum style --foreground 8 "$PPA_UPSTREAM_VERSION")
$(gum style --foreground 11 "New GitHub:") $(gum style --foreground 10 "$VERSION")
$(gum style --foreground 11 "Package version:") $(gum style --foreground 15 "$VERSION-$DEBIAN_REVISION")"
fi

echo ""

# Change to working directory
cd "$WORK_DIR"

BUILD_DIR="${PACKAGE_NAME}_${VERSION}"
INSTALL_DIR="./$BUILD_DIR/opt/zen"
BIN_DIR="./$BUILD_DIR/usr/bin"
DESKTOP_DIR="./$BUILD_DIR/usr/share/applications"
ICON_BASE="./$BUILD_DIR/usr/share/icons/hicolor"

# === CLEAN UP OLD BUILDS ===
rm -rf "./$BUILD_DIR"
mkdir -p "$INSTALL_DIR" "$BIN_DIR" "$DESKTOP_DIR"

# === DOWNLOAD AND EXTRACT ===
section "Downloading and Extracting"
gum spin --spinner dot --title "Downloading $TARBALL..." -- \
    wget -q "$TARBALL_URL"
success "Downloaded $TARBALL"

gum spin --spinner dot --title "Extracting tarball..." -- \
    tar -xf "$TARBALL"
mv zen/* "$INSTALL_DIR"
success "Extracted files"

# === CREATE EXECUTABLE WRAPPER ===
section "Creating Package Files"
info "Creating wrapper script..."
cat <<EOF > "$BIN_DIR/zen"
#!/bin/bash
/opt/zen/zen "\$@"
EOF
chmod +x "$BIN_DIR/zen"

# === INSTALL ICONS ===
info "Copying icons..."
for size in 16 32 48 64 128; do
  mkdir -p "$ICON_BASE/${size}x${size}/apps"
  cp "$INSTALL_DIR/browser/chrome/icons/default/default${size}.png" \
     "$ICON_BASE/${size}x${size}/apps/zen.png"
done

# === CREATE .desktop FILE ===
info "Creating .desktop file..."
cat <<EOF > "$DESKTOP_DIR/zen.desktop"
[Desktop Entry]
Name=Zen Browser
Comment=Experience tranquillity while browsing the web without people tracking you!
Keywords=web;browser;internet
Exec=/opt/zen/zen %u
Icon=zen
Terminal=false
StartupNotify=true
StartupWMClass=zen
NoDisplay=false
Type=Application
MimeType=text/html;text/xml;application/xhtml+xml;application/vnd.mozilla.xul+xml;text/mml;x-scheme-handler/http;x-scheme-handler/https;
Categories=Network;WebBrowser;
Actions=new-window;new-private-window;profile-manager-window;

[Desktop Action new-window]
Name=Open a New Window
Exec=/opt/zen/zen --new-window %u

[Desktop Action new-private-window]
Name=Open a New Private Window
Exec=/opt/zen/zen --private-window %u

[Desktop Action profile-manager-window]
Name=Open the Profile Manager
Exec=/opt/zen/zen --ProfileManager
EOF

success "Application files created"

# === CREATE ORIGINAL TARBALL ===
section "Creating Source Package"
ORIG_TARBALL="${PACKAGE_NAME}_${VERSION}.orig.tar.xz"
info "Creating original tarball (upstream source only)..."
# Create tarball from BUILD_DIR but exclude debian/ directory (doesn't exist yet)
gum spin --spinner dot --title "Creating original tarball..." -- \
    tar -cJf "../$ORIG_TARBALL" -C "$BUILD_DIR" .
success "Original tarball created: $ORIG_TARBALL"

# === CREATE DEBIAN PACKAGE FILES ===
info "Creating debian package files..."
mkdir -p "$BUILD_DIR/debian"

# Create debian/control
cat <<EOF > "$BUILD_DIR/debian/control"
Source: $PACKAGE_NAME
Section: web
Priority: optional
Maintainer: $MAINTAINER
Build-Depends: debhelper-compat (= 13)
Standards-Version: 4.6.0
Homepage: https://zen-browser.app
Vcs-Git: https://github.com/zen-browser/desktop.git
Vcs-Browser: https://github.com/zen-browser/desktop

Package: $PACKAGE_NAME
Architecture: $ARCH
Depends: \${misc:Depends},
         libgtk-3-0,
         libdbus-glib-1-2,
         libasound2,
         libx11-xcb1,
         libxt6
Recommends: libavcodec-extra | libavcodec58 | libavcodec59 | libavcodec60
Description: privacy-focused Firefox-based web browser
 Zen Browser provides a tranquil browsing experience focused on user privacy
 and preventing tracking. Built on Firefox technology, it offers modern web
 standards support while prioritizing user control and data protection.
 .
 Key features include enhanced privacy controls, streamlined user interface,
 and integration with password managers including 1Password browser support.
EOF

# Create debian/rules
cat <<'EOF' > "$BUILD_DIR/debian/rules"
#!/usr/bin/make -f
%:
	dh $@

override_dh_auto_build:
	# Nothing to build, using pre-compiled binaries

override_dh_auto_install:
	# Manual installation of files
	mkdir -p debian/zen-browser/opt/zen
	mkdir -p debian/zen-browser/usr/bin
	mkdir -p debian/zen-browser/usr/share/applications
	mkdir -p debian/zen-browser/usr/share/icons/hicolor/16x16/apps
	mkdir -p debian/zen-browser/usr/share/icons/hicolor/32x32/apps
	mkdir -p debian/zen-browser/usr/share/icons/hicolor/48x48/apps
	mkdir -p debian/zen-browser/usr/share/icons/hicolor/64x64/apps
	mkdir -p debian/zen-browser/usr/share/icons/hicolor/128x128/apps

	cp -r opt/zen/* debian/zen-browser/opt/zen/
	cp usr/bin/zen debian/zen-browser/usr/bin/
	cp usr/share/applications/zen.desktop debian/zen-browser/usr/share/applications/
	cp usr/share/icons/hicolor/16x16/apps/zen.png debian/zen-browser/usr/share/icons/hicolor/16x16/apps/
	cp usr/share/icons/hicolor/32x32/apps/zen.png debian/zen-browser/usr/share/icons/hicolor/32x32/apps/
	cp usr/share/icons/hicolor/48x48/apps/zen.png debian/zen-browser/usr/share/icons/hicolor/48x48/apps/
	cp usr/share/icons/hicolor/64x64/apps/zen.png debian/zen-browser/usr/share/icons/hicolor/64x64/apps/
	cp usr/share/icons/hicolor/128x128/apps/zen.png debian/zen-browser/usr/share/icons/hicolor/128x128/apps/

override_dh_shlibdeps:
	# Skip dependency detection for pre-compiled binaries
	dh_shlibdeps --dpkg-shlibdeps-params=--ignore-missing-info || true

override_dh_strip:
	# Don't strip pre-compiled binaries
EOF
chmod +x "$BUILD_DIR/debian/rules"

# === POSTINST TO UPDATE ICON CACHE AND 1PASSWORD ===
cat <<'EOF' > "$BUILD_DIR/debian/postinst"
#!/bin/sh
set -e

# This script is idempotent and can be safely called multiple times

case "$1" in
    configure|reconfigure)
        # Update icon cache
        if command -v gtk-update-icon-cache > /dev/null 2>&1; then
            gtk-update-icon-cache -f /usr/share/icons/hicolor || true
        fi

        # Add zen browsers to 1Password allowed browsers
        ALLOWED_BROWSERS_FILE="/etc/1password/custom_allowed_browsers"

        # Create directory if it doesn't exist
        if [ ! -d "/etc/1password" ]; then
            mkdir -p /etc/1password
        fi

        # Create file if it doesn't exist
        if [ ! -f "$ALLOWED_BROWSERS_FILE" ]; then
            touch "$ALLOWED_BROWSERS_FILE"
        fi

        # Add entries if not already present (idempotent)
        grep -qxF "zen" "$ALLOWED_BROWSERS_FILE" || echo "zen" >> "$ALLOWED_BROWSERS_FILE"
        grep -qxF "zen-bin" "$ALLOWED_BROWSERS_FILE" || echo "zen-bin" >> "$ALLOWED_BROWSERS_FILE"

        # Set correct ownership and permissions for 1Password
        chown root:root "$ALLOWED_BROWSERS_FILE"
        chmod 755 "$ALLOWED_BROWSERS_FILE"
        ;;

    abort-upgrade|abort-remove|abort-deconfigure)
        ;;

    *)
        echo "postinst called with unknown argument \`$1'" >&2
        exit 1
        ;;
esac

#DEBHELPER#

exit 0
EOF
chmod +x "$BUILD_DIR/debian/postinst"

# === POSTRM TO CLEAN UP 1PASSWORD ENTRIES ===
cat <<'EOF' > "$BUILD_DIR/debian/postrm"
#!/bin/sh
set -e

case "$1" in
    purge)
        # Remove zen browsers from 1Password allowed browsers on purge
        ALLOWED_BROWSERS_FILE="/etc/1password/custom_allowed_browsers"
        if [ -f "$ALLOWED_BROWSERS_FILE" ]; then
            sed -i '/^zen$/d' "$ALLOWED_BROWSERS_FILE" || true
            sed -i '/^zen-bin$/d' "$ALLOWED_BROWSERS_FILE" || true

            # Remove file if empty
            if [ ! -s "$ALLOWED_BROWSERS_FILE" ]; then
                rm -f "$ALLOWED_BROWSERS_FILE"
            fi
        fi

        # Remove directory if empty
        if [ -d "/etc/1password" ]; then
            rmdir --ignore-fail-on-non-empty /etc/1password || true
        fi
        ;;

    remove|upgrade|failed-upgrade|abort-install|abort-upgrade|disappear)
        ;;

    *)
        echo "postrm called with unknown argument \`$1'" >&2
        exit 1
        ;;
esac

#DEBHELPER#

exit 0
EOF
chmod +x "$BUILD_DIR/debian/postrm"

success "Debian packaging files created"

# === BUILD AND UPLOAD FOR EACH DISTRIBUTION ===
section "Building and Uploading Packages"

for DISTRO in "${DISTRIBUTIONS[@]}"; do
  gum style \
      --foreground 13 \
      --bold \
      --margin "1 0" \
      "📦 Building for $DISTRO"

  # Create distribution-specific version
  DISTRO_VERSION="${VERSION}-${DEBIAN_REVISION}~${DISTRO}1"

  # Create debian/changelog for this distribution
  cat <<EOF > "$BUILD_DIR/debian/changelog"
$PACKAGE_NAME ($DISTRO_VERSION) $DISTRO; urgency=medium

  * New upstream release ${VERSION}
  * Repackaged pre-compiled binaries from upstream
  * Added 1Password browser integration via custom_allowed_browsers
  * Updated icon cache handling in postinst maintainer script

 -- $MAINTAINER  $(date -R)
EOF

  # Build source package
  info "Building source package..."
  cd "$BUILD_DIR"

  # Run debuild and capture output
  if gum spin --spinner dot --title "Running debuild..." -- \
      bash -c "debuild -S -sa -d > ../build-${DISTRO}.log 2>&1"; then
      success "Build completed"
  else
      echo ""
      error "debuild failed for $DISTRO"
      echo ""
      gum style --foreground 9 "Build log:"
      tail -50 ../build-${DISTRO}.log
      exit 1
  fi
  cd ..

  # Upload to PPA
  info "Uploading to PPA..."
  CHANGES_FILE="${PACKAGE_NAME}_${DISTRO_VERSION}_source.changes"

  if gum spin --spinner dot --title "Uploading ${DISTRO} package..." -- \
      dput "$PPA" "$CHANGES_FILE"; then
      success "Successfully uploaded $DISTRO package"
  else
      echo ""
      error "Failed to upload $DISTRO package to PPA"
      exit 1
  fi
  echo ""
done

# === SUCCESS SUMMARY ===
header "✨ Build Complete!"

gum style \
    --border rounded \
    --border-foreground 10 \
    --padding "1 2" \
    --margin "1 0" \
    "$(success "All packages built and uploaded successfully!")

$(gum style --foreground 11 --bold "PPA:") $(gum style --foreground 14 "https://launchpad.net/~bashfulrobot/+archive/ubuntu/zen-browser")
$(gum style --foreground 11 --bold "Version:") $(gum style --foreground 15 "$VERSION")
$(gum style --foreground 11 --bold "Distributions:") $(gum style --foreground 15 "${DISTRIBUTIONS[*]}")

$(gum style --foreground 8 --bold "Build Monitoring:")
$(gum style --foreground 11 "  • All builds:") $(gum style --foreground 14 "https://launchpad.net/~bashfulrobot/+archive/ubuntu/zen-browser/+builds?build_text=&build_state=all")
$(gum style --foreground 11 "  • Failed builds:") $(gum style --foreground 14 "https://launchpad.net/~bashfulrobot/+archive/ubuntu/zen-browser/+builds?build_text=&build_state=failed")"

echo ""
info "Build artifacts: $WORK_DIR"
info "Monitor build progress at the URLs above (builds take 5-15 minutes per distribution)"
echo ""

# === CLEANUP PROMPT ===
if gum confirm "Clean up the temporary build directory?"; then
    gum spin --spinner dot --title "Cleaning up..." -- \
        rm -rf "$WORK_DIR"
    success "Cleanup complete"
else
    info "Build artifacts preserved: $WORK_DIR"
    gum style --foreground 8 "  To clean up later: rm -rf $WORK_DIR"
fi

echo ""
