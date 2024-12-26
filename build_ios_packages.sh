#!/bin/bash
set -ex  # Add -x for verbose output

# Build Python for iOS (only iphoneos.arm64)
TARGETS="iphoneos.arm64" make support/3.9/iOS/Python.xcframework/Info.plist

# Install third-party packages for iphoneos.arm64
echo "Building packages for iphoneos.arm64..."

# Set up build environment
export IPHONEOS_DEPLOYMENT_TARGET=13.0
PYTHON_ROOT="$(pwd)/install/iOS/iphoneos.arm64/python-3.9.21"
export PYTHONPATH="$PYTHON_ROOT/lib/python3.9"
SITE_PACKAGES="$PYTHONPATH/site-packages"

echo "Python root: $PYTHON_ROOT"
echo "Site packages directory: $SITE_PACKAGES"

# Create site-packages if it doesn't exist
mkdir -p "$SITE_PACKAGES"

# Download and extract packages manually
TEMP_DIR="build/temp_packages"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

# Download packages using curl
echo "Downloading packages..."
curl -L -o fonttools-4.55.0.tar.gz https://files.pythonhosted.org/packages/source/f/fonttools/fonttools-4.55.0.tar.gz
curl -L -o PyMuPDF-1.24.14.tar.gz https://files.pythonhosted.org/packages/source/P/PyMuPDF/PyMuPDF-1.24.14.tar.gz
curl -L -o pdf2docx-0.5.7.tar.gz https://files.pythonhosted.org/packages/source/p/pdf2docx/pdf2docx-0.5.7.tar.gz

# Extract and install packages
echo "Installing PyMuPDF-1.24.14.tar.gz..."
tar xzf PyMuPDF-1.24.14.tar.gz
mkdir -p "$SITE_PACKAGES/fitz"
cp PyMuPDF-1.24.14/src/* "$SITE_PACKAGES/fitz/"
mv "$SITE_PACKAGES/fitz/fitz___init__.py" "$SITE_PACKAGES/fitz/__init__.py"

echo "Installing fonttools-4.55.0.tar.gz..."
tar xzf fonttools-4.55.0.tar.gz
cp -r fonttools-4.55.0/fontTools "$SITE_PACKAGES/"

echo "Installing pdf2docx-0.5.7.tar.gz..."
tar xzf pdf2docx-0.5.7.tar.gz
cp -r pdf2docx-0.5.7/pdf2docx "$SITE_PACKAGES/"

cd ..

# Create XCFramework for iOS (device only)
echo "Creating XCFramework (device only)..."
mkdir -p support/3.9/iOS/

# Create XCFramework for device only
xcodebuild -create-xcframework \
  -framework "$PYTHON_ROOT/Python.framework" \
  -output support/3.9/iOS/Python.xcframework

# Install PYTHONHOME for iOS
cp -r "$PYTHON_ROOT/include" support/3.9/iOS/Python.xcframework/ios-arm64
cp -r "$PYTHON_ROOT/bin" support/3.9/iOS/Python.xcframework/ios-arm64
cp -r "$PYTHON_ROOT/lib" support/3.9/iOS/Python.xcframework/ios-arm64

# Create helper links in XCframework for iOS
ln -si ios-arm64 support/3.9/iOS/Python.xcframework/iphoneos

# Create final distribution artefact for iOS
mkdir -p dist
# Build a distributable tarball
tar zcvf dist/Python-3.9-iOS-support.custom.tar.gz -X patch/Python/release.iOS.exclude -C support/3.9/iOS `ls -A support/3.9/iOS/`

echo "Final XCFramework contents:"
ls -la support/3.9/iOS/Python.xcframework/ios-arm64/lib/python3.9/site-packages/

echo "Build complete!"
