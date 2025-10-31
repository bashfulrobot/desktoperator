#!/bin/bash
set -e

# Script to build lswt as a .deb package
# Usage: ./build-lswt-deb.sh

PACKAGE_NAME="lswt"
VERSION="1.0.0"

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROLE_FILES_DIR="${SCRIPT_DIR}/files"

# Create temporary build directory
BUILD_DIR=$(mktemp -d -t lswt-build-XXXXXX)
PACKAGE_DIR="${BUILD_DIR}/${PACKAGE_NAME}_${VERSION}"

# Cleanup function to ensure temp directory is removed
cleanup() {
    echo "Cleaning up build directory..."
    rm -rf "${BUILD_DIR}"
}
trap cleanup EXIT

echo "Building ${PACKAGE_NAME} v${VERSION} .deb package..."
echo "Build directory: ${BUILD_DIR}"

cd "${BUILD_DIR}"

# Install build dependencies
echo "Installing build dependencies..."
sudo apt update
sudo apt install -y git build-essential libwayland-dev wayland-protocols pkg-config

# Clone the repository
echo "Cloning repository..."
git clone https://git.sr.ht/~leon_plickat/lswt
cd lswt
git checkout toplevel-info

# Build the binary
echo "Building lswt..."
make

# Create package directory structure
echo "Creating .deb package structure..."
mkdir -p "${PACKAGE_DIR}/usr/local/bin"
mkdir -p "${PACKAGE_DIR}/usr/share/man/man1"
mkdir -p "${PACKAGE_DIR}/usr/share/bash-completion/completions"
mkdir -p "${PACKAGE_DIR}/DEBIAN"

# Install files
cp lswt "${PACKAGE_DIR}/usr/local/bin/"
cp lswt.1 "${PACKAGE_DIR}/usr/share/man/man1/"
gzip "${PACKAGE_DIR}/usr/share/man/man1/lswt.1"
cp bash-completion "${PACKAGE_DIR}/usr/share/bash-completion/completions/lswt"

# Create DEBIAN/control file
cat > "${PACKAGE_DIR}/DEBIAN/control" << EOF
Package: ${PACKAGE_NAME}
Version: ${VERSION}
Section: utils
Priority: optional
Architecture: amd64
Depends: libwayland-client0
Maintainer: Local Build <build@localhost>
Description: List Wayland toplevels
 A tool to list Wayland windows (toplevels) with their properties.
 Requires the foreign-toplevel-management-unstable-v1 protocol extension.
Homepage: https://git.sr.ht/~leon_plickat/lswt
EOF

# Build the .deb package
echo "Building .deb package..."
cd "${BUILD_DIR}"
dpkg-deb --build "${PACKAGE_NAME}_${VERSION}"

# Copy the .deb to the role files directory
DEB_FILE="${PACKAGE_NAME}_${VERSION}.deb"
echo "Copying ${DEB_FILE} to ${ROLE_FILES_DIR}/"
mkdir -p "${ROLE_FILES_DIR}"
cp "${DEB_FILE}" "${ROLE_FILES_DIR}/"

echo ""
echo "✓ Successfully built: ${ROLE_FILES_DIR}/${DEB_FILE}"
echo ""

# Ask user if they want to install the package
read -p "Install the package now? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Installing package..."
    sudo dpkg -i "${ROLE_FILES_DIR}/${DEB_FILE}"
    echo ""
    echo "✓ Successfully installed ${PACKAGE_NAME}"
else
    echo "Skipping installation. To install later, run:"
    echo "  sudo dpkg -i ${ROLE_FILES_DIR}/${DEB_FILE}"
fi

echo ""
echo "To remove build dependencies (optional):"
echo "  sudo apt remove --autoremove build-essential libwayland-dev wayland-protocols pkg-config"
echo ""

# cleanup() will be called automatically via trap EXIT
