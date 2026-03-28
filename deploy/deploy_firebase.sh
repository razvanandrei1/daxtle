#!/bin/bash
set -euo pipefail

# ─── Configuration ────────────────────────────────────────────────────────────
# Godot binary path (adjust if different)
GODOT="/Applications/Godot.app/Contents/MacOS/Godot"

# Project paths
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"

# Firebase App IDs — replace with your actual IDs from the Firebase console
FIREBASE_APP_ANDROID="1:302571734213:android:30df2af857608ab02d1cac"
FIREBASE_APP_IOS="1:302571734213:ios:bf09cabe96d3c5872d1cac"

# Comma-separated list of tester emails
TESTERS="you@example.com"

# ─── Helpers ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

usage() {
    echo "Usage: $0 [android|ios|all]"
    echo ""
    echo "  android   Build and deploy Android APK to Firebase App Distribution"
    echo "  ios       Build and deploy iOS IPA to Firebase App Distribution"
    echo "  all       Build and deploy both platforms (default)"
    exit 0
}

EXPORT_PRESETS="$PROJECT_DIR/export_presets.cfg"
BUILD_NUMBER_FILE="$BUILD_DIR/.build_number"

check_dependencies() {
    if [ ! -f "$GODOT" ]; then
        error "Godot not found at $GODOT — update the GODOT variable in this script"
    fi
    if ! command -v firebase &> /dev/null; then
        error "Firebase CLI not found. Install with: npm install -g firebase-tools"
    fi
}

increment_build_number() {
    # Read current build number, increment, and save
    if [ ! -f "$BUILD_NUMBER_FILE" ]; then
        echo "0" > "$BUILD_NUMBER_FILE"
    fi
    local current
    current=$(cat "$BUILD_NUMBER_FILE")
    BUILD_NUMBER=$((current + 1))
    echo "$BUILD_NUMBER" > "$BUILD_NUMBER_FILE"

    # Update Android version code
    sed -i '' "s/version\/code=[0-9]*/version\/code=$BUILD_NUMBER/" "$EXPORT_PRESETS"

    # Update iOS build version
    sed -i '' "s/application\/version=\"[0-9]*\"/application\/version=\"$BUILD_NUMBER\"/" "$EXPORT_PRESETS"

    info "Build number incremented to $BUILD_NUMBER"
}

# ─── Android ──────────────────────────────────────────────────────────────────
build_android() {
    info "Building Android APK..."
    mkdir -p "$BUILD_DIR/android"

    "$GODOT" --headless --path "$PROJECT_DIR" --export-release "Android" \
        "$BUILD_DIR/android/daxtle.apk"

    if [ ! -f "$BUILD_DIR/android/daxtle.apk" ]; then
        error "Android build failed — APK not found"
    fi
    info "Android APK built: $BUILD_DIR/android/daxtle.apk"
}

deploy_android() {
    info "Deploying Android to Firebase App Distribution..."
    firebase appdistribution:distribute "$BUILD_DIR/android/daxtle.apk" \
        --app "$FIREBASE_APP_ANDROID" \
        --testers "$TESTERS"
    info "Android deployed successfully"
}

# ─── iOS ──────────────────────────────────────────────────────────────────────
build_ios() {
    if ! command -v xcodebuild &> /dev/null; then
        error "xcodebuild not found — install Xcode and Command Line Tools"
    fi

    info "Exporting iOS Xcode project..."
    mkdir -p "$BUILD_DIR/ios"

    # Ensure Godot only exports the Xcode project (don't build/archive)
    sed -i '' 's/application\/export_project_only=false/application\/export_project_only=true/' "$EXPORT_PRESETS"

    "$GODOT" --headless --path "$PROJECT_DIR" --export-release "iOS" \
        "$BUILD_DIR/ios/daxtle.xcodeproj"

    # Restore so the editor isn't affected
    sed -i '' 's/application\/export_project_only=true/application\/export_project_only=false/' "$EXPORT_PRESETS"

    if [ ! -d "$BUILD_DIR/ios/daxtle.xcodeproj" ]; then
        error "iOS export failed — Xcode project not found"
    fi

    # ─── Regenerate app icon (single 1024px PNG) ──────────────────────────
    info "Generating app icon..."
    ICON_DIR="$BUILD_DIR/ios/daxtle/Images.xcassets/AppIcon.appiconset"
    mkdir -p "$ICON_DIR"
    cairosvg "$PROJECT_DIR/icon.svg" -o "$ICON_DIR/Icon-1024.png" -W 1024 -H 1024
    cat > "$ICON_DIR/Contents.json" << 'ICON_JSON'
{
  "images": [
    {
      "idiom": "universal",
      "platform": "ios",
      "size": "1024x1024",
      "filename": "Icon-1024.png"
    }
  ],
  "info": {
    "author": "xcode",
    "version": 1
  }
}
ICON_JSON
    info "App icon ready (single 1024x1024)"

    # Remove Godot splash from launch screen — show only background color
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

    # Switch from automatic to manual signing for ad-hoc distribution
    sed -i '' 's/CODE_SIGN_STYLE = "Automatic"/CODE_SIGN_STYLE = "Manual"/' \
        "$BUILD_DIR/ios/daxtle.xcodeproj/project.pbxproj"
    sed -i '' 's/CODE_SIGN_STYLE = Automatic/CODE_SIGN_STYLE = Manual/' \
        "$BUILD_DIR/ios/daxtle.xcodeproj/project.pbxproj"
    sed -i '' 's/ProvisioningStyle = Automatic/ProvisioningStyle = Manual/' \
        "$BUILD_DIR/ios/daxtle.xcodeproj/project.pbxproj"

    info "Building iOS archive..."
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
        error "iOS archive failed"
    fi

    info "Exporting IPA..."
    xcodebuild -exportArchive \
        -archivePath "$BUILD_DIR/ios/daxtle.xcarchive" \
        -exportPath "$BUILD_DIR/ios/output" \
        -exportOptionsPlist "$BUILD_DIR/ios/ExportOptions.plist" \
        | tail -1

    IPA_PATH=$(find "$BUILD_DIR/ios/output" -name "*.ipa" -print -quit)
    if [ -z "$IPA_PATH" ]; then
        error "iOS export failed — IPA not found"
    fi
    info "iOS IPA built: $IPA_PATH"
}

deploy_ios() {
    IPA_PATH=$(find "$BUILD_DIR/ios/output" -name "*.ipa" -print -quit)
    if [ -z "$IPA_PATH" ]; then
        error "No IPA found — run build first"
    fi

    info "Deploying iOS to Firebase App Distribution..."
    firebase appdistribution:distribute "$IPA_PATH" \
        --app "$FIREBASE_APP_IOS" \
        --testers "$TESTERS"
    info "iOS deployed successfully"
}

# ─── Main ─────────────────────────────────────────────────────────────────────
TARGET="${1:-all}"

case "$TARGET" in
    -h|--help) usage ;;
    android)
        check_dependencies
increment_build_number
        build_android
        deploy_android
        ;;
    ios)
        check_dependencies
increment_build_number
        build_ios
        deploy_ios
        ;;
    all)
        check_dependencies
increment_build_number
        build_android
        deploy_android
        build_ios
        deploy_ios
        ;;
    *)
        error "Unknown target: $TARGET. Use android, ios, or all."
        ;;
esac

info "Done!"
