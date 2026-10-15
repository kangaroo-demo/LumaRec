#!/bin/bash
# Exercise the export code INSIDE the extracted final app, with no user shell environment.
set -euo pipefail
[[ $# == 2 ]] || { echo 'Usage: scripts/verify-package.sh /absolute/artifact.dmg-or.zip /absolute/evidence-directory' >&2; exit 1; }
artifact="$1"
evidence="$2"
mkdir -p "$evidence"
work_dir="$(mktemp -d)"
mount_dir=''
cleanup() {
    if [[ -n "$mount_dir" ]]; then hdiutil detach "$mount_dir" -quiet || true; fi
    rm -rf "$work_dir"
}
trap cleanup EXIT
case "$artifact" in
    *.zip) ditto -x -k "$artifact" "$work_dir/extracted" ;;
    *.dmg)
        # Use an identical private copy, so another reviewer's mounted image does not lock this check.
        cp "$artifact" "$work_dir/package.dmg"
        hdiutil verify "$work_dir/package.dmg" > "$evidence/disk-image-integrity.txt"
        hdiutil attach -readonly -nobrowse -plist "$work_dir/package.dmg" > "$work_dir/mount.plist"
        mount_dir="$(/usr/bin/python3 -c 'import plistlib,sys; print(next(e["mount-point"] for e in plistlib.load(open(sys.argv[1],"rb"))["system-entities"] if "mount-point" in e))' "$work_dir/mount.plist")"
        ditto "$mount_dir/LumaRec.app" "$work_dir/extracted/LumaRec.app"
        ;;
    *) echo 'Expected DMG or ZIP.' >&2; exit 1 ;;
esac
app="$work_dir/extracted/LumaRec.app"
binary="$app/Contents/MacOS/LumaRec"
codesign --verify --deep --strict --verbose=2 "$app" > "$evidence/signature-verify.txt" 2>&1
codesign -dvv "$app" > "$evidence/signature-details.txt" 2>&1
lipo -archs "$binary" > "$evidence/architectures.txt"
otool -L "$binary" > "$evidence/dynamic-libraries.txt"
# Reject linked runtimes outside macOS. Swift runtime is provided by macOS 13+.
/usr/bin/python3 - "$evidence/dynamic-libraries.txt" <<'PY'
import sys
for line in open(sys.argv[1]):
    if 'compatibility version' not in line: continue
    dependency=line.strip().split(' (')[0]
    if not dependency.startswith(('/usr/lib/', '/System/Library/')):
        raise SystemExit('Non-system runtime dependency: '+dependency)
print('PASS: linked dynamic libraries are all supplied by macOS')
PY
plutil -p "$app/Contents/Info.plist" > "$evidence/bundle-metadata.txt"
/usr/bin/env -i HOME="$HOME" TMPDIR="$work_dir/" PATH=/usr/bin:/bin:/usr/sbin:/sbin LANG=en_US.UTF-8 \
    "$binary" --verify-export "$evidence/media" > "$evidence/native-export.txt" 2>&1
/usr/bin/env -i HOME="$HOME" TMPDIR="$work_dir/" PATH=/usr/bin:/bin:/usr/sbin:/sbin LANG=en_US.UTF-8 \
    "$binary" --language zh-Hans --screenshot "$evidence/zh-Hans.png" > "$evidence/ui-zh.txt" 2>&1
/usr/bin/env -i HOME="$HOME" TMPDIR="$work_dir/" PATH=/usr/bin:/bin:/usr/sbin:/sbin LANG=en_US.UTF-8 \
    "$binary" --language en --screenshot "$evidence/en.png" > "$evidence/ui-en.txt" 2>&1
if spctl --assess --type execute --verbose=2 "$app" > "$evidence/gatekeeper.txt" 2>&1; then
    echo 'Gatekeeper: accepted'
else
    echo 'Gatekeeper: rejected (see evidence; this is expected for a non-notarized candidate)'
fi
shasum -a 256 "$artifact" > "$evidence/artifact-SHA256.txt"
cat "$evidence/native-export.txt"
echo 'PASS: final extracted app, minimal system PATH, empty inherited environment, bundled English/Chinese UI'
echo 'No hardware capture or normal first-open UI approval is asserted by this check.'
