# LumaRec 1.0.0 release handoff

## Current delivery — published stable 1.0.0

Updated 2026-10-15 (Asia/Shanghai). **Stable 1.0.0 is publicly available and latest.** All earlier universal/7931d81 package hashes and paths below are historical and superseded. **User-facing scope: Apple Silicon (arm64) only**, macOS 13+ deployment target. Intel has no qualified first-release download.

- Version: **1.0.0**, build **1**.
- Clean package source and published tag `v1.0.0`: **`2f3a9ecdcb018a5181fa0a5cbe8014d34cb3a515`**. Metadata has no dirty marker. Subsequent documentation-only commits record verification; they do not change the packaged executable or bundled installer instructions.
- Public Release: https://github.com/kangaroo-demo/LumaRec/releases/tag/v1.0.0 . Release ID **413460221**, name **LumaRec 1.0.0**, `draft=false`, `prerelease=false`; unauthenticated `/releases/latest` resolves to this release.
- Published at **2026-10-15T06:11:23Z**, or **2026-10-15 14:11:23 +08:00 (Asia/Shanghai)**.
- Public installers: [DMG](https://github.com/kangaroo-demo/LumaRec/releases/download/v1.0.0/LumaRec-1.0.0-macOS-arm64.dmg) · [ZIP](https://github.com/kangaroo-demo/LumaRec/releases/download/v1.0.0/LumaRec-1.0.0-macOS-arm64.zip) · [SHA-256 checksums](https://github.com/kangaroo-demo/LumaRec/releases/download/v1.0.0/LumaRec-1.0.0-macOS-arm64-SHA256SUMS.txt).
- Runtime: Apple system frameworks and system Swift only. No Homebrew, FFmpeg, Xcode, PATH override, account, network or additional runtime required for camera + microphone recording/export.
- Signing: ad hoc + hardened runtime + Camera/Audio Input entitlements. **No Developer ID, notarization, ticket or staple.** Automatic Gatekeeper assessment rejects it, as expected. No security mechanism was disabled or quarantine removed.
- User acceptance and authorization on 2026-10-15: **“通过直接发布正式版本”**. This records the actual release decision without inventing a more specific manual test sequence. No paid Apple Developer account is available; that is a disclosed distribution limitation.

### Final assets and hashes

All installer assets are under `/Users/donie/onion_space/VobeCodingSpace/LumaRec/dist/` and attached to the public stable release. Only these arm64 installer names are eligible for website downloads. Publication did not rebuild, replace or re-upload the accepted assets.

| Asset | Architecture / role | SHA-256 |
| --- | --- | --- |
| `LumaRec-1.0.0-macOS-arm64.dmg` | arm64 installer, 612024 bytes | `ffa562c7dcaabf6a2295b18a5683e4de09aac73158dfa1a953104def735e3ee9` |
| `LumaRec-1.0.0-macOS-arm64.zip` | arm64 app + offline instructions, 357155 bytes | `4da2901bade5d96f24d78ea93ef5ede38bf5117503a448db58365ad01cb73872` |
| `LumaRec-1.0.0-macOS-arm64-build.txt` | source / architecture / signature metadata | `7dff7e196bc434e67a348cec5db74f2c963e8f8dc5e173551db8ab344162da1e` |
| `LumaRec-1.0.0-verification.zip` | sanitized logs, static UI screenshots and synthetic samples only | `1085612494e9be2d6a4ed23e617661f74fcf10b275996d2b5339a8cd46590c93` |

All six assets were downloaded again from public download URLs without GitHub credentials or cookies. Their asset IDs, sizes and remote digests match the pre-publication record; all downloaded SHA-256 hashes match the accepted artifacts. Also attached: `LumaRec-1.0.0-macOS-arm64-SHA256SUMS.txt` and `LumaRec-1.0.0-verification-SHA256.txt`. DMG/ZIP include an Applications shortcut and English/Chinese offline installation instructions. No private hardware recording is in the repository or release.

The published installers and verification ZIP remain byte-identical to the accepted candidate. Candidate/pending wording inside bundled guides or archived verification records is historical. This handoff, the current repository guides and the public Release page record the final stable status; documentation updates must not rebuild or replace 1.0.0 artifacts.

### Unauthenticated public verification

- Public release HTML, release-by-tag API, latest-release API and tag-reference API each returned HTTP 200. Release ID **413460221** is stable/latest and `v1.0.0` directly points to source **`2f3a9ecdcb018a5181fa0a5cbe8014d34cb3a515`**.
- All six public asset URLs returned HTTP 200 and downloaded files passed byte-size and SHA-256 checks. No Authorization header, GitHub session, cookies, netrc or CLI credentials were used. Direct GitHub connections were intermittent; individual requests used the existing local HTTP proxy at `127.0.0.1:7897` where needed. No global network settings changed.
- Durable sanitized results: [public-download-verification.json](evidence/2026-10-15-stable/public-download-verification.json). Raw public JSON/HTML, downloaded assets and checksum results remain under `/Users/donie/onion_space/VobeCodingSpace/LumaRec/work/public-release-verification/`. Pre-publication and publication responses remain at `work/release-before-publication.json` and `work/stable-publication-result.json`.

### Reproducible evidence — source, package and hardware are separate

- Source checks: `/Users/donie/onion_space/VobeCodingSpace/LumaRec/work/cfr-source-checks.txt`. Native synthetic generation/encoding/decoding, all quality levels, clockwise portrait pixels, mixed 440/880 Hz tones, silent video, all four corners filled for 4:3 input, deliberately dropped frames resampled to continuous 30 fps, required-audio failure, non-overwrite, invalid media, destination/free-space preflight, persistent rediscovery and recovery export all passed. 122 literal UI/export localization keys and format placeholders passed in both catalogs.
- **Final DMG extracted-app checks:** `/Users/donie/onion_space/VobeCodingSpace/LumaRec/work/delivery-dmg/`. Image integrity, ad hoc signature integrity, arm64 metadata, system dynamic-library closure, actual packaged native export, English and Chinese rendering all passed.
- **Final ZIP extracted-app checks:** `/Users/donie/onion_space/VobeCodingSpace/LumaRec/work/delivery-zip/`. Same packaged native export and UI checks passed. Each check starts the extracted binary under `env -i`, preserving the OS home/temp variables and using only `/usr/bin:/bin:/usr/sbin:/sbin` PATH; all user/provider/FFmpeg environment variables are absent. Homebrew may exist elsewhere on the test Mac, but there is no lookup, subprocess invocation or linked non-system library in the application. This is stronger than source tests, but is not a claim of testing an erased/fresh OS installation.
- Final package source **GitHub Actions passed on macOS 14 ARM**: https://github.com/kangaroo-demo/LumaRec/actions/runs/38689299177 . Includes source checks, localization, native arm64 packaging, and both extracted final installer checks on that runner. CI-generated package hashes are distinct builds; local delivery hashes above are the published assets.
- **Actual local hardware, same final ZIP:** `/Users/donie/onion_space/VobeCodingSpace/LumaRec/work/delivery-hardware/hardware-result.txt`. The app drove its normal UI actions/delegates with the built-in camera/microphone: record ~2 s, pause 2 s, resume ~2 s, stop and native export. Both track starts 0; output duration 4.350645833 s (callback/poll latency included); 131 decoded video frames; largest video PTS interval 33.333 ms; true missing audio time effectively 0; video/audio end difference **17.3125 ms**; decoded microphone RMS **0.008897905**. Pause was excluded from the output timeline. The final private clip and original remain only in this local directory. This proves hardware capture + nonzero decoded audio/timestamp behavior, **not human lip-sync or audible speech quality**.
- Private hardware samples from earlier diagnostic attempts remain under `work/hardware-verification`, `work/final-hardware`, and `work/arm64-hardware`; never upload them. Older failures and corrections are recorded below instead of being presented as passes.
- Public evidence directory before ZIP: `/Users/donie/onion_space/VobeCodingSpace/LumaRec/work/release-evidence/`. Its only media files are generated color-pattern/sine-tone MP4s; hardware evidence is a numeric text summary with no device IDs, personal paths or camera images.

### User acceptance and coverage limits

The earlier acceptance request covered normal downloaded-app first-open and playback. The user's actual response was **“通过直接发布正式版本”**, accepting the release and authorizing publication. This decision is recorded separately from the automated and hardware measurements above. It does not establish a detailed account of the user's installation path, speech recording or lip-sync review. A command-line launch of an unquarantined app also does not establish downloaded first-open behavior.

The stable community Release is published with the ad hoc signature/unnotarized limitation stated. Additional unexecuted physical tests remain coverage limits, not pending publication gates: macOS 13 hardware, permission-denial recovery, physical hot-unplug, stop while paused, long capture and controlled low-space volume. Automated preflight tests do not substitute for those physical cases. See `docs/acceptance-checklist.md`.

### Website facts

Current status: **“LumaRec 1.0.0 stable is publicly available for Apple Silicon.”** Use the public Release and arm64 DMG/ZIP URLs and hashes above. Disclose **not Developer ID signed / not notarized; normal first-open approval may be needed**. Intel has no qualified download.

Capabilities: local camera + microphone MP4, pause/resume, silent video, preview/meter, three quality settings, English/Chinese, no runtime setup. Preview and export use proportional center crop; edges may be cropped. The earlier large-black-border feedback is already covered by the accepted source. Any newly reproduced preview issue belongs to a subsequent version and does not change the accepted 1.0.0 assets. Optional Input/Mix still needs an existing configured virtual input for speaker audio; native system-output capture is not included.

The coordinating chat reports the website's stable downloads updated and 36 browser cases passed; those checks are separate from this repository's release verification. This chat has not edited `kangaroo-apps` or deployed the website.

---

## Historical progress (superseded where noted)

Everything below records the candidate stage. Its draft/pending statements, old package paths and instructions to rebuild or replace candidates are historical; the published status and immutable assets above are authoritative.

Updated: 2026-10-15 (Asia/Shanghai). Source baseline: `837d902ad80d3281203988c72b40c19c5c751554`.

## Request and current answer

User: deliver an installable Mac camera recorder with no separately installed runtime, bilingual UI, robust recording/export, DMG + ZIP, and an honest release gate.

Implemented: external FFmpeg export replaced with Apple AVFoundation H.264/AAC; preview, meters, quality and orientation retained; silent mode, persistent source recovery and output validation added. System audio remains an optional virtual input in this candidate: native ScreenCaptureKit would add screen-recording authorization and a second capture clock; it is not a prerequisite for camera + microphone recording and is not claimed as supported.

## Release gates

- No applicable AGENTS.md found in this repository or ancestor directories.
- Host: Apple Silicon, macOS 26.5; Swift 6.3.3 Command Line Tools.
- `security find-identity -v -p codesigning`: only `DockPin Local Development`, no Developer ID Application identity. No private keys or credential values inspected. Developer ID signing, Apple notarization and staple are unavailable. Automatic Gatekeeper assessment rejects this ad hoc build; normal per-app UI approval still needs acceptance. A local/ad hoc signature is not Developer ID.
- GitHub release draft is complete with the final arm64 assets; no stable public Release is published. Code has been committed and pushed. After user clarification, unsigned community stable publication is allowed if normal first-open UI and core recording are accepted; missing Developer ID alone is not a permanent blocker.
- Synthetic export and dependency-closure evidence is separate from actual hardware recording and from human first-open/playback acceptance. See the dated results below.

## Progress

- Inspected capture implementation, localization, existing checks, packaging and CI. Existing capture uses AVCaptureMovieFileOutput with native pause/resume; export invokes an external FFmpeg. Existing UI requires both permissions and rejects silent recordings.

## Final delivery

Delivered: clean source SHA, version, draft Release URL, final arm64 DMG/ZIP and SHA-256, extracted-app environment checks, signing assessment, actual hardware evidence, sanitized verification archive and website facts are recorded at the top. Only the two human acceptance items and stable publication are pending.

## Review paths (first complete candidate, before final clean-source rebuild)

- DMG: `/Users/donie/onion_space/VobeCodingSpace/LumaRec/dist/LumaRec-1.0.0-macOS-universal.dmg`
- ZIP: `/Users/donie/onion_space/VobeCodingSpace/LumaRec/dist/LumaRec-1.0.0-macOS-universal.zip`
- App: `/Users/donie/onion_space/VobeCodingSpace/LumaRec/dist/LumaRec.app`
- Extracted DMG isolated-environment evidence: `/Users/donie/onion_space/VobeCodingSpace/LumaRec/work/dmg-verification/`
- Extracted ZIP isolated-environment evidence: `/Users/donie/onion_space/VobeCodingSpace/LumaRec/work/zip-verification/`
- Real hardware acceptance (PRIVATE, LOCAL ONLY): `/Users/donie/onion_space/VobeCodingSpace/LumaRec/work/hardware-verification/`

First universal package generated successfully using separate arm64/x86_64 SwiftPM cross builds + lipo; no full Xcode required. These first packages embed a dirty source marker; final release assets will be rebuilt after committing source, with fresh hashes and rerun package checks.

### Updated distribution constraint from user

The user confirmed there is no paid Apple Developer account. Missing Developer ID/notarization alone is NOT a permanent stable-release blocker. A clearly disclosed, locally signed community stable release is allowed if actual installation through normal macOS per-app Open Anyway approval and core hardware capture are accepted. Do not require xattr, disabling Gatekeeper/SIP, terminal setup, or installing runtimes. Command-line execution of an unquarantined app does not prove downloaded first-open acceptance.

Real camera/microphone clips are private local evidence. Never upload them to GitHub, repository docs, releases or the website. Only sanitized results/logs and synthetic samples may be published.

### Checks so far

- Apple-only source checks: passed all quality levels, H.264/AAC decode, clockwise portrait pixel inspection, dual-frequency audio mixing, silent export, non-overwrite, invalid media, disk/write preflight and persistent recovery.
- Localization: 122 literal UI/export keys present in both catalogs, format placeholders match.
- Permissions/device status queried without starting capture: camera authorized, microphone authorized, 1 camera, 2 audio inputs. The final packaged hardware run passed; see current delivery for exact evidence.
- Recovery UI now lists every pending recording; a corrupt oldest original cannot block choosing another.

### 2026-10-15: hardware attempt and no-border steering

- First extracted ZIP recorded the real built-in FaceTime HD camera and MacBook Pro microphone: ~2 s record, ~2 s pause, ~2 s resume, then native MP4 export. A 4.2 s H.264/AAC MP4 was produced. Actual decoded audio RMS 0.0024104, video/audio end difference 30.3 ms. Private clip stays under `work/hardware-verification/`; never upload.
- The initial inspection incorrectly treated the PTS difference between variable-sized decoded PCM buffers as an empty audio gap. Fixed the inspector to measure `nextPTS - previousBufferEnd` (true missing time). Reinspection passed: maximum audio gap effectively zero; video gap 66.7 ms; 114 decoded video frames. This is a test measurement correction, not a claim of human lip-sync acceptance.
- User supplied a private live screenshot and requested no large black borders. Changed preview to aspect fill and native output to proportional center crop. Frame is filled without letterboxing or stretching; edges may be cropped. Updated synthetic framing check and user docs accordingly. The screenshot is not copied to repository/release assets.
- Both first-candidate DMG and ZIP passed extracted-app native export and bilingual rendering in a stripped inherited environment with only system PATH. `spctl` rejects the ad hoc candidate as expected; no Gatekeeper bypass used. Final checks will be repeated after the no-border change and clean source build.

### Candidate source qualification before clean build

- Latest source checks passed after center-crop change, including decoding a genuine synthetic 4:3 input and checking all four output corners for no added black border, plus required-audio failure for Mic mode. `work/source-checks.txt` records this run.
- The final draft will attach only installation assets, bilingual notes, synthetic verification samples and sanitized evidence. No private camera clips, device names or personal path logs will be uploaded.
- Remaining stable publication gates: actual downloaded/quarantined package launch through normal per-app UI approval; human playback/lip-sync review; final clean-package hardware run. Additional macOS 13/Intel physical-machine checks remain an explicit platform coverage limit.

### Compatibility follow-up (supersedes 0e35d7f packages)

- Hosted macOS 14 source/media checks passed, but app compilation exposed SDK-dependent Swift notification member names. Replaced them with the verified stable Objective-C notification string values; no runtime behavior change.
- Single microphone export now uses AVAssetReaderTrackOutput directly; only actual multi-track mixing invokes Apple's offline mixer. Source media/recovery/localization checks passed again.
- An extra x86_64-under-Rosetta run on macOS 26.5 crashed inside Apple's CoreAudio `caulk`/offline mixer code (`AQServer`, `AVAssetReaderAudioMixOutput`). This is not an Intel-native pass. Added a native macOS 15 Intel CI job to test the actual Intel runtime separately; macOS 14 ARM CI also remains required. No installed Rosetta or other runtime is required for the Apple Silicon app.
- The package verifier now mounts its own byte-identical private DMG copy, avoiding image-resource locks during parallel independent review. The 0e35d7f DMG copy passed integrity and extracted-app checks; the resource-busy result was not image corruption.
- A complete 0e35d7f actual built-in-camera/microphone run passed: 4.3 s output for 4 s active capture plus 2 s pause; starts both 0; 115 video frames; true audio gap ~0; video/audio end difference 7.7 ms; microphone RMS 0.0015215. Final successor packages will rerun hardware capture. Human playback and downloaded first-open still need one-time user acceptance.

### First-release scope decision

Per coordinating user steering: qualify and distribute **Apple Silicon (arm64) only** for version 1.0.0. Intel/universal development assets are not user-facing downloads and no Intel support claim is made. Do not keep first delivery waiting on Rosetta mixer investigation. The final source commit updates installation guides, READMEs, release notes and CI to the arm64 scope; release builds use `--native` on this Apple Silicon host. Previously listed universal hashes are superseded and must not be used on the website. Native camera code remains the tested native Apple implementation. Downloaded first-open and human playback remain the final user actions, not a request to buy an Apple account.

### Continuous output clock correction (supersedes 7931d81 candidate assets)

The final 7931d81 arm64 actual hardware run produced a valid 4.2 s MP4 with audible decoded microphone PCM, but inspection found a 333 ms video timestamp gap (audio gap ~0, end difference 27 ms). Do not count that run as full hardware acceptance. Source retention worked: its private original is local under `work/arm64-hardware/private-original.mov` and no private media is uploaded.

Fixed native export to emit an explicit continuous 30 fps pixel-buffer clock, holding the last camera frame when input frames arrive late, while preserving audio timing and total duration. This cannot recover camera frames that were never captured; it prevents gaps in the output timestamp stream. Added a synthetic source with seven deliberately missing frames and required all 30 output frames and evenly spaced PTS after export. All native source/recovery/localization checks passed. Rebuild the clean successor, replace only this session's newly created draft candidate assets, and rerun final package + real hardware evidence before human acceptance.
