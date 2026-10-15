# Release procedure / 发布流程

Build the first-release arm64 artifacts on an Apple Silicon Mac with macOS 13+ with Swift 5.9+ Command Line Tools. Full Xcode is optional. Normal users need neither.
Version and build number are in `Resources/Info.plist`; the first published version is 1.0.0 (build 1). See [release handoff](release-handoff.md) for its immutable accepted asset hashes. Do not rebuild or replace the published 1.0.0 artifacts for documentation-only updates.

1. Run `swift run LumaRecChecks` and the localization check in CI. Review capture/recovery changes.
2. Commit the source first. Build from a clean checkout with `./scripts/build-app.sh --archive --native`.
   The qualified first-release outputs are arm64 DMG, ZIP, build metadata and SHA-256 checksums.
   Without --native the script can produce a universal development build; do not publish that as first-release Intel support. The app embeds the source SHA and marks dirty builds.
3. Run `scripts/verify-package.sh` on **both** final DMG and ZIP, with a fresh evidence directory each time.
   It verifies signatures, library closure, metadata, and executes the extracted app's real native exporter
   under `env -i` with system PATH. It also renders English and Chinese windows. Preserve logs and synthetic
   samples. No Homebrew executable or environment override is involved. This does not prove a clean OS install.
4. Complete the [hardware/first-open acceptance checklist](acceptance-checklist.md). Test a downloaded,
   quarantined app through Finder, including normal per-app Open Anyway approval when unnotarized.
   Test macOS 13 and a current macOS on Apple Silicon; document any untested OS version. Intel is deferred.
   Hardware media remains private; only sanitized results and synthetic samples belong in release assets.
5. Recheck all final asset hashes. Create a **draft** GitHub release; never overwrite an existing release/tag.
   Publish stable (not prerelease) only when core recording and normal installation are accepted. Missing
   Apple notarization alone does not prohibit a clearly labeled stable community release.

```sh
./scripts/verify-package.sh "$PWD/dist/LumaRec-1.0.0-macOS-arm64.dmg" "$PWD/work/dmg-final"
./scripts/verify-package.sh "$PWD/dist/LumaRec-1.0.0-macOS-arm64.zip" "$PWD/work/zip-final"
# Use the reviewed release notes, target the exact clean source commit, and do not replace existing assets.
gh release create v1.0.0 --repo kangaroo-demo/LumaRec --draft \
  --target <reviewed-source-sha> --title 'LumaRec 1.0.0' \
  --notes-file docs/releases/1.0.0.md dist/LumaRec-1.0.0-macOS-arm64.* \
  dist/LumaRec-1.0.0-macOS-arm64-build.txt dist/LumaRec-1.0.0-macOS-arm64-SHA256SUMS.txt
# After acceptance, update release notes to the final status, then publish the draft:
# gh release edit v1.0.0 --repo kangaroo-demo/LumaRec --draft=false --prerelease=false
```

## Optional Developer ID and notarization

The current owner does not have a paid Apple Developer account. Do not wait indefinitely for one or
represent ad hoc signatures as Developer ID. For future enrolled maintainers, install a Developer ID
Application identity using Apple's normal secure process and create a named notarytool Keychain profile.
Never commit certificates, private keys, passwords, API keys, or credential dumps.

```sh
SIGNING_IDENTITY='Developer ID Application: Your organization (TEAMID)' \
NOTARY_PROFILE='your-existing-keychain-profile-name' ./scripts/build-app.sh --notarize --native
```

This signs with hardened runtime and camera/audio entitlements, submits the app ZIP, staples and validates
the app, then packages and notarizes/staples the DMG. It checks Gatekeeper acceptance and regenerates
checksums after stapling. Review notarytool diagnostics; only Accepted + successful staple/assessment
counts. Do not distribute a rejected build or silently downgrade a notarization request.

## Community distribution without notarization

Use the ad hoc build and clearly state that macOS can block first launch. Users may approve that one app
through System Settings → Privacy & Security → Open Anyway if macOS and their management policy allow it.
Do not instruct users to run xattr, disable Gatekeeper or SIP, or install a runtime. Record real download/UI
acceptance; direct command-line execution of an unquarantined app does not validate Gatekeeper first-open.

更新版本、提交、arm64 打包、最终 DMG/ZIP 解包验证、硬件与首次打开验收，再发布。无付费 Apple 账号时可交付明确说明未公证的社区稳定版；不能把临时签名说成首次双击无提示，也不能以此无限期拒绝交付。尚未验证的关键用户流程要保留为具体阻塞，先提供完整候选包与草稿。
