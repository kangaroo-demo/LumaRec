# Contributing / 参与贡献

Use macOS 13+ with Swift 5.9+ Command Line Tools. No package manager or FFmpeg is needed.

```sh
swift run LumaRecChecks
./scripts/build-app.sh --archive --native
./scripts/verify-package.sh "$PWD/dist/LumaRec-1.0.0-macOS-arm64.zip" "$PWD/work/zip-verification"
```

`Sources/LumaRec` contains AppKit UI and camera capture. `Sources/LumaRecCore` contains native export,
recording recovery, localization, device discovery, synthetic qualification and actual-output inspection.
`Tests/LumaRecChecks` runs checks without XCTest or full Xcode. Packaging works with Command Line Tools. The first release is arm64 only; run release builds on Apple Silicon. Universal/Intel development builds are not qualified downloads.

The extracted app's `--verify-export /absolute/new-directory` flag generates synthetic media and exercises
its actual exporter, without opening a camera. `--screenshot /absolute/file.png --language en` (or `zh-Hans`)
renders its interface without requesting permissions. `--device-status` reads availability and permission status.

For authorized local hardware acceptance, `--hardware-verify /absolute/evidence-directory` launches the
normal app, requests normal macOS permissions and drives the same UI actions: record 2s, pause 2s,
resume 2s, stop and export. It validates the resulting duration, timestamp continuity and nonzero microphone
PCM after decoding. Be present to approve system prompts; do not grant them through automation.
Hardware clips are private local evidence: never commit or upload them. Human playback/lip-sync review
and downloaded-app Gatekeeper UI acceptance are separate requirements.

Manually check denial, Silent with microphone denied, device switching/disconnection, stopping while paused,
quit while busy, long recordings and output-volume failures. Keep both string catalogs complete.
See [release procedure](docs/RELEASING.md) and [handoff](docs/release-handoff.md).

请同步维护中英文本地化；合成素材测试不能替代真实硬件验收。报告问题时附 macOS、架构、设备种类与复现步骤。
分享日志前移除个人路径，勿上传用户录制、密钥、生成的应用或本地工作目录。
