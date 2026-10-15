# Acceptance checklist / 验收清单

Release 1.0.0 acceptance update (2026-10-15): the user accepted the release and authorized stable publication with “通过直接发布正式版本”. This records the user's decision; it does not describe a more specific manual test sequence or mark the detailed physical scenarios below as executed. See [release handoff](release-handoff.md) for the separate automated, hardware and public-download evidence.

Record date, source SHA, package SHA-256, Mac architecture and macOS version for each run.
Automated pass/fail evidence lives separately from human acceptance. Do not mark unchecked items passed.

- [ ] Download final DMG/ZIP through a browser, verify checksum, drag app to Applications, eject DMG.
- [ ] Open through Finder. If blocked as unverified, use the normal per-app Privacy & Security → Open Anyway
      UI. Record OS wording, successful launch, and subsequent normal launch. No security-disable commands.
- [ ] On a fresh permission state, grant Camera and Microphone normally. Confirm camera picture and meter.
- [ ] Record speech and visible claps for 10+ seconds; pause for 5+ seconds, resume and clap again; stop.
      Play the MP4 in QuickTime. Confirm audible speech, lip-sync before/after pause and no frozen pause gap.
- [ ] Stop while paused; output is playable and excludes the pause. Repeat pause/resume several times.
- [ ] Confirm portrait picture rotates clockwise and landscape is not rotated; check a recognizable marker.
- [ ] Switch devices; reject permissions; enable them in System Settings and Refresh; Silent works when
      Microphone permission is denied. Camera denial gives a clear message and does not start capture.
- [ ] Disconnect selected camera/microphone while recording; app reports interruption, retains originals and
      permits recovery/export if the source is readable. Reconnect and Refresh restores preview.
- [ ] Fail export using an unavailable/read-only destination. Existing files survive; no final partial MP4 is
      presented as complete. Relaunch, select any pending recording and export to a writable folder.
- [ ] Make one pending recording corrupt; later recordings remain selectable and recoverable.
- [ ] Try quitting/changing language while recording/exporting; app prevents accidental loss. After completion,
      app quits normally. Check saved folder/device/quality/language preferences on relaunch.
- [ ] Check long recording, disk use and low-space behavior on a controlled test volume; avoid filling user disk.
- [ ] Repeat basic installation/capture on macOS 13 and current macOS, Apple Silicon and Intel; record scope.

`--hardware-verify` can verify actual capture callbacks, pause duration, decoded frame timestamps and
nonzero recorded PCM. It cannot assess human lip-sync, first-open Gatekeeper UI, every permission-denial
case or physical disconnection. Synthetic `--verify-export` is not evidence of hardware recording.

请勿把待验收项写成通过。硬件样片包含个人影像/声音，仅留本机，发布只附脱敏结论和合成测试样片。
