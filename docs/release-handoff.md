# LumaRec 1.0.0 release handoff

Updated: 2026-10-15 (Asia/Shanghai). Source baseline: `837d902ad80d3281203988c72b40c19c5c751554`.

## Request and current answer

User: deliver an installable Mac camera recorder with no separately installed runtime, bilingual UI, robust recording/export, DMG + ZIP, and an honest release gate.

Implementation in progress: replace external FFmpeg export with Apple AVFoundation H.264/AAC; retain preview, meters, quality and orientation; add silent mode, persistent source recovery and output validation. System audio remains an optional virtual input in this candidate: native ScreenCaptureKit would add screen-recording authorization and a second capture clock; it is not a prerequisite for camera + microphone recording and is not claimed as supported.

## Release gates

- No applicable AGENTS.md found in this repository or ancestor directories.
- Host: Apple Silicon, macOS 26.5; Swift 6.3.3 Command Line Tools.
- `security find-identity -v -p codesigning`: only `DockPin Local Development`, no Developer ID Application identity. No private keys or credential values inspected. Developer ID signing, Apple notarization and staple are unavailable. Automatic Gatekeeper assessment rejects this ad hoc build; normal per-app UI approval still needs acceptance. A local/ad hoc signature is not Developer ID.
- No existing GitHub releases. Authorized to commit/push and prepare a draft. After user clarification, unsigned community stable publication is allowed if normal first-open UI and core recording are accepted; missing Developer ID alone is not a permanent blocker.
- Synthetic export and dependency-closure evidence is separate from actual hardware recording and from human first-open/playback acceptance. See the dated results below.

## Progress

- Inspected capture implementation, localization, existing checks, packaging and CI. Existing capture uses AVCaptureMovieFileOutput with native pause/resume; export invokes an external FFmpeg. Existing UI requires both permissions and rejects silent recordings.

## Final delivery

Pending: source SHA; candidate version; draft Release URL; asset names, architectures and SHA-256; extraction/isolated-environment evidence; signing assessment; hardware acceptance evidence; website wording.

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
- Permissions/device status queried without starting capture: camera authorized, microphone authorized, 1 camera, 2 audio inputs. Actual packaged hardware acceptance is still pending.
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
