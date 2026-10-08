#!/bin/bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
cd "$project_dir"

if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "LumaRec requires macOS 13 or later." >&2
    exit 1
fi

if [[ "${1:-}" != "" && "${1:-}" != "--archive" ]] || [[ $# -gt 1 ]]; then
    echo "Usage: ./scripts/build-app.sh [--archive]" >&2
    exit 1
fi

swift build -c release --product LumaRec
bin_dir="$(swift build -c release --show-bin-path)"
app_dir="$project_dir/dist/LumaRec.app"
mkdir -p "$app_dir/Contents/MacOS" "$app_dir/Contents/Resources"
cp "$bin_dir/LumaRec" "$app_dir/Contents/MacOS/LumaRec"
cp Resources/Info.plist "$app_dir/Contents/Info.plist"
cp Resources/LumaRecIcon.icns "$app_dir/Contents/Resources/"
# Keep resources inside Contents so the app remains a valid signed bundle.
rm -rf "$app_dir/LumaRec_LumaRec.bundle" "$app_dir/LumaRec_LumaRecCore.bundle"
rm -rf "$app_dir/Contents/Resources/LumaRec_LumaRecCore.bundle"
cp -R "$bin_dir/LumaRec_LumaRecCore.bundle" "$app_dir/Contents/Resources/"
mkdir -p "$app_dir/Contents/Resources/en.lproj" "$app_dir/Contents/Resources/zh-Hans.lproj"
cp Sources/LumaRecCore/Resources/en.lproj/InfoPlist.strings "$app_dir/Contents/Resources/en.lproj/"
cp Sources/LumaRecCore/Resources/zh-Hans.lproj/InfoPlist.strings "$app_dir/Contents/Resources/zh-Hans.lproj/"
cp LICENSE "$app_dir/Contents/Resources/LICENSE"
plutil -lint "$app_dir/Contents/Info.plist"
codesign --force --sign - "$app_dir"
codesign --verify --strict "$app_dir"
echo "Built: $app_dir"

if [[ "${1:-}" == "--archive" ]]; then
    archive_path="$project_dir/dist/LumaRec-macOS-$(uname -m).zip"
    ditto -c -k --sequesterRsrc --keepParent "$app_dir" "$archive_path"
    echo "Archive: $archive_path"
fi
