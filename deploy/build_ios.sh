#!/bin/bash
set -euo pipefail

# ─── iOS Ad-Hoc Build Script ────────────────────────────────────────────────
# Exports a release IPA to ios_exports/ without deploying to Firebase.
# Usage: ./deploy/build_ios.sh
# ─────────────────────────────────────────────────────────────────────────────

GODOT="/Applications/Godot.app/Contents/MacOS/Godot"

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
OUTPUT_DIR="$PROJECT_DIR/ios_exports"
GLOBALS_FILE="$PROJECT_DIR/scripts/Globals.gd"
EXPORT_PRESETS="$PROJECT_DIR/export_presets.cfg"
BUILD_NUMBER_FILE="$BUILD_DIR/.build_number"

# ─── Helpers ────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# ─── Release mode ───────────────────────────────────────────────────────────
enforce_release_mode() {
    ORIGINAL_DEBUG_LINE=$(grep 'const DEBUG_MODE' "$GLOBALS_FILE")
    ORIGINAL_EDITOR_LINE=$(grep 'const LEVEL_EDITOR_MODE' "$GLOBALS_FILE")
    sed -i '' 's/const DEBUG_MODE := true/const DEBUG_MODE := false/' "$GLOBALS_FILE"
    sed -i '' 's/const LEVEL_EDITOR_MODE := true/const LEVEL_EDITOR_MODE := false/' "$GLOBALS_FILE"
    info "DEBUG_MODE and LEVEL_EDITOR_MODE set to false"
}

restore_globals() {
    if [ -n "${ORIGINAL_DEBUG_LINE:-}" ]; then
        sed -i '' "s/const DEBUG_MODE := false/$ORIGINAL_DEBUG_LINE/" "$GLOBALS_FILE"
    fi
    if [ -n "${ORIGINAL_EDITOR_LINE:-}" ]; then
        sed -i '' "s/const LEVEL_EDITOR_MODE := false/$ORIGINAL_EDITOR_LINE/" "$GLOBALS_FILE"
    fi
    info "Globals restored"
}

trap restore_globals EXIT

increment_build_number() {
    if [ ! -f "$BUILD_NUMBER_FILE" ]; then
        echo "0" > "$BUILD_NUMBER_FILE"
    fi
    local current
    current=$(cat "$BUILD_NUMBER_FILE")
    BUILD_NUMBER=$((current + 1))
    echo "$BUILD_NUMBER" > "$BUILD_NUMBER_FILE"
    sed -i '' "s/application\/version=\"[0-9]*\"/application\/version=\"$BUILD_NUMBER\"/" "$EXPORT_PRESETS"
    info "Build number: $BUILD_NUMBER"
}

# ─── Checks ─────────────────────────────────────────────────────────────────
if [ ! -f "$GODOT" ]; then
    error "Godot not found at $GODOT"
fi
if ! command -v xcodebuild &> /dev/null; then
    error "xcodebuild not found — install Xcode and Command Line Tools"
fi

# ─── Build ──────────────────────────────────────────────────────────────────
enforce_release_mode
increment_build_number

info "Exporting Xcode project..."
mkdir -p "$BUILD_DIR/ios"

sed -i '' 's/application\/export_project_only=false/application\/export_project_only=true/' "$EXPORT_PRESETS"

"$GODOT" --headless --path "$PROJECT_DIR" --export-release "iOS" \
    "$BUILD_DIR/ios/daxtle.xcodeproj"

sed -i '' 's/application\/export_project_only=true/application\/export_project_only=false/' "$EXPORT_PRESETS"

if [ ! -d "$BUILD_DIR/ios/daxtle.xcodeproj" ]; then
    error "Xcode project export failed"
fi

# Patch launch screen — blank background only
info "Patching launch screen..."
STORYBOARD="$BUILD_DIR/ios/daxtle/Launch Screen.storyboard"
cat > "$STORYBOARD" << 'STORYBOARD_XML'
<?xml version="1.0" encoding="UTF-8"?>
<document type="com.apple.InterfaceBuilder3.CocoaTouch.Storyboard.XIB" version="3.0" toolsVersion="16097" targetRuntime="iOS.CocoaTouch" propertyAccessControl="none" useAutolayout="YES" launchScreen="YES" useTraitCollections="YES" useSafeAreas="YES" colorMatched="YES" initialViewController="01J-lp-oVM">
    <device id="retina6_1" orientation="portrait" appearance="light"/>
    <dependencies>
        <deployment identifier="iOS"/>
        <plugIn identifier="com.apple.InterfaceBuilder.IBCocoaTouchPlugin" version="16087"/>
        <capability name="Safe area layout guides" minToolsVersion="9.0"/>
        <capability name="documents saved in the Xcode 8 format" minToolsVersion="8.0"/>
    </dependencies>
    <scenes>
        <scene sceneID="EHf-IW-A2E">
            <objects>
                <viewController id="01J-lp-oVM" sceneMemberID="viewController">
                    <view key="view" contentMode="scaleToFill" id="Ze5-6b-2t3">
                        <rect key="frame" x="0.0" y="0.0" width="414" height="896"/>
                        <autoresizingMask key="autoresizingMask" widthSizable="YES" heightSizable="YES"/>
                        <color key="backgroundColor" red="0.96" green="0.94" blue="0.89" alpha="1.0" colorSpace="custom" customColorSpace="sRGB"/>
                        <viewLayoutGuide key="safeArea" id="Bcu-3y-fUS"/>
                    </view>
                </viewController>
                <placeholder placeholderIdentifier="IBFirstResponder" id="iYj-Kq-Ea1" userLabel="First Responder" sceneMemberID="firstResponder"/>
            </objects>
            <point key="canvasLocation" x="52.173913043478265" y="375"/>
        </scene>
    </scenes>
</document>
STORYBOARD_XML

# Manual signing for ad-hoc
sed -i '' 's/CODE_SIGN_STYLE = "Automatic"/CODE_SIGN_STYLE = "Manual"/' \
    "$BUILD_DIR/ios/daxtle.xcodeproj/project.pbxproj"
sed -i '' 's/CODE_SIGN_STYLE = Automatic/CODE_SIGN_STYLE = Manual/' \
    "$BUILD_DIR/ios/daxtle.xcodeproj/project.pbxproj"
sed -i '' 's/ProvisioningStyle = Automatic/ProvisioningStyle = Manual/' \
    "$BUILD_DIR/ios/daxtle.xcodeproj/project.pbxproj"

info "Archiving..."
xcodebuild -project "$BUILD_DIR/ios/daxtle.xcodeproj" \
    -scheme "daxtle" \
    -configuration Release \
    -archivePath "$BUILD_DIR/ios/daxtle.xcarchive" \
    -destination "generic/platform=iOS" \
    archive \
    CODE_SIGN_STYLE=Manual \
    CODE_SIGN_IDENTITY="Apple Distribution" \
    PROVISIONING_PROFILE_SPECIFIER="DaxtleAdHoc" \
    DEVELOPMENT_TEAM="35S9978Q2Z" \
    | tail -1

if [ ! -d "$BUILD_DIR/ios/daxtle.xcarchive" ]; then
    error "Archive failed"
fi

info "Exporting IPA..."
xcodebuild -exportArchive \
    -archivePath "$BUILD_DIR/ios/daxtle.xcarchive" \
    -exportPath "$BUILD_DIR/ios/output" \
    -exportOptionsPlist "$BUILD_DIR/ios/ExportOptions.plist" \
    | tail -1

IPA_PATH=$(find "$BUILD_DIR/ios/output" -name "*.ipa" -print -quit)
if [ -z "$IPA_PATH" ]; then
    error "IPA export failed"
fi

# ─── Copy to ios_exports ────────────────────────────────────────────────────
mkdir -p "$OUTPUT_DIR"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DEST="$OUTPUT_DIR/daxtle_b${BUILD_NUMBER}_${TIMESTAMP}.ipa"
cp "$IPA_PATH" "$DEST"

info "IPA saved to: $DEST"
