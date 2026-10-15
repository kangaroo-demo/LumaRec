#!/bin/bash
# Universal, Apple-framework-only build. No downloads and no package manager.
set -euo pipefail
project_dir="$(cd "$(dirname "$0")/.." && pwd)"
cd "$project_dir"
archive=false
notarize=false
universal=true
for option in "$@"; do
    case "$option" in
        --archive) archive=true ;;
        --native) universal=false ;;
        --notarize) notarize=true; archive=true ;;
        *) echo 'Usage: scripts/build-app.sh [--archive] [--native] [--notarize]' >&2; exit 1 ;;
    esac
done
[[ "$(uname -s)" == Darwin ]] || { echo 'macOS build host required.' >&2; exit 1; }
if $notarize; then
    [[ "${SIGNING_IDENTITY:-}" == 'Developer ID Application:'* && -n "${NOTARY_PROFILE:-}" ]] || {
        echo 'Notarization requires SIGNING_IDENTITY (Developer ID Application) and NOTARY_PROFILE (existing Keychain profile name).' >&2
        exit 1
    }
fi
# Building each triple separately works with Command Line Tools as well as full Xcode.
# SwiftPM's multi-arch xcbuild mode requires full Xcode; lipo does not.
if $universal; then
    for architecture in arm64 x86_64; do
        swift build -c release --triple "$architecture-apple-macosx13.0" --scratch-path ".build/$architecture" --product LumaRec
    done
    bin_dir="$(swift build -c release --triple arm64-apple-macosx13.0 --scratch-path .build/arm64 --show-bin-path)"
    intel_dir="$(swift build -c release --triple x86_64-apple-macosx13.0 --scratch-path .build/x86_64 --show-bin-path)"
else
    swift build -c release --product LumaRec
    bin_dir="$(swift build -c release --show-bin-path)"
fi
app_dir="$project_dir/dist/LumaRec.app"
# Only replace the generated app; never remove recordings or the entire dist directory.
rm -rf "$app_dir"
mkdir -p "$app_dir/Contents/MacOS" "$app_dir/Contents/Resources"
if $universal; then
    lipo -create "$bin_dir/LumaRec" "$intel_dir/LumaRec" -output "$app_dir/Contents/MacOS/LumaRec"
else
    cp "$bin_dir/LumaRec" "$app_dir/Contents/MacOS/LumaRec"
fi
cp Resources/Info.plist "$app_dir/Contents/Info.plist"
cp Resources/LumaRecIcon.icns "$app_dir/Contents/Resources/"
cp -R "$bin_dir/LumaRec_LumaRecCore.bundle" "$app_dir/Contents/Resources/"
for language in en zh-Hans; do
    mkdir -p "$app_dir/Contents/Resources/$language.lproj"
    cp "Sources/LumaRecCore/Resources/$language.lproj/InfoPlist.strings" "$app_dir/Contents/Resources/$language.lproj/"
done
cp LICENSE THIRD_PARTY_NOTICES.md "$app_dir/Contents/Resources/"
source_revision="$(git rev-parse HEAD)"
if [[ -n "$(git status --porcelain --untracked-files=normal)" ]]; then source_revision="$source_revision-dirty"; fi
/usr/libexec/PlistBuddy -c "Add :LumaRecSourceRevision string $source_revision" "$app_dir/Contents/Info.plist"
plutil -lint "$app_dir/Contents/Info.plist"
signing_identity="${SIGNING_IDENTITY:--}"
signing_options=(--force --options runtime --entitlements Resources/LumaRec.entitlements --sign "$signing_identity")
if [[ "$signing_identity" == 'Developer ID Application:'* ]]; then signing_options+=(--timestamp); fi
codesign "${signing_options[@]}" "$app_dir"
codesign --verify --deep --strict "$app_dir"
version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app_dir/Contents/Info.plist")"
arch_label=universal
if ! $universal; then arch_label="$(uname -m)"; fi
asset_base="LumaRec-$version-macOS-$arch_label"
if $notarize; then
    submission="$project_dir/dist/$asset_base-notary-submission.zip"
    ditto -c -k --keepParent "$app_dir" "$submission"
    xcrun notarytool submit "$submission" --keychain-profile "$NOTARY_PROFILE" --wait
    xcrun stapler staple "$app_dir"
    xcrun stapler validate "$app_dir"
    spctl --assess --type execute --verbose=2 "$app_dir"
    rm "$submission"
fi
if $archive; then
    staging="$(mktemp -d "$project_dir/dist/package.XXXXXX")"
    trap 'rm -rf "$staging"' EXIT
    ditto "$app_dir" "$staging/LumaRec.app"
    ln -s /Applications "$staging/Applications"
    cp docs/INSTALL.html "$staging/Install LumaRec.html"
    cp docs/INSTALL.md "$staging/Installation EN-ZH.txt"
    cp LICENSE THIRD_PARTY_NOTICES.md "$staging/"
    zip_path="$project_dir/dist/$asset_base.zip"
    dmg_path="$project_dir/dist/$asset_base.dmg"
    # ditto's ZIP includes the app, Applications shortcut and offline bilingual instructions.
    rm -f "$zip_path"
    ditto -c -k --sequesterRsrc "$staging" "$zip_path"
    hdiutil create -ov -volname "LumaRec $version" -srcfolder "$staging" -format UDZO "$dmg_path"
    if $notarize; then
        xcrun notarytool submit "$dmg_path" --keychain-profile "$NOTARY_PROFILE" --wait
        xcrun stapler staple "$dmg_path"
        xcrun stapler validate "$dmg_path"
        spctl --assess --type open --context context:primary-signature --verbose=2 "$dmg_path"
    fi
    {
        echo "Version: $version"
        echo "Source: $source_revision"
        echo "Architectures: $(lipo -archs "$app_dir/Contents/MacOS/LumaRec")"
        echo "Deployment target: macOS 13.0"
        echo "Runtime: Apple system frameworks only; no separately installed components"
        if [[ "$signing_identity" == - ]]; then echo 'Signature: ad hoc; not Apple Developer ID; not notarized';
        else echo "Signature identity: $signing_identity"; fi
        echo "Notarization requested and verified: $notarize"
    } > "dist/$asset_base-build.txt"
    (cd dist && shasum -a 256 "$asset_base.dmg" "$asset_base.zip" "$asset_base-build.txt" > "$asset_base-SHA256SUMS.txt")
    echo "Assets: $dmg_path, $zip_path"
fi
echo "Built: $app_dir"
