# Contributing / 参与贡献

Bug reports and small, focused pull requests are welcome. Include your macOS version, Mac architecture, selected devices, and steps to reproduce. Remove personal paths and recordings from logs before sharing them. English and Chinese issues are both welcome.

欢迎提交问题和小范围的 Pull Request。请说明 macOS 版本、Mac 架构、所选设备和复现步骤；分享日志前请去除个人路径和录制内容。支持使用中文或英文交流。

## Layout / 工程结构

```text
Package.swift                      Swift Package Manager project
Sources/LumaRec/
  main.swift                       App entry point
  AppDelegate.swift                AppKit UI and AVFoundation capture
Sources/LumaRecCore/
  ExportConfiguration.swift        FFmpeg discovery and export settings
  Localization.swift               English default and language selection
  Resources/{en,zh-Hans}.lproj/     Interface and permission translations
Resources/                         App metadata and icon
scripts/build-app.sh               Local build, packaging, and signing
Tests/LumaRecChecks/                Tests without hardware access
docs/images/                       Icon and generated UI screenshots
.github/workflows/ci.yml           macOS tests and app packaging
```

## Verify a change / 验证改动

```sh
swift run LumaRecChecks --require-ffmpeg
./scripts/build-app.sh --archive
```

Checks run with Command Line Tools and do not require XCTest or the full Xcode app. Use `swift run LumaRecChecks` to run translation checks when FFmpeg is unavailable.

验证工具只需要 Command Line Tools，不依赖 XCTest 或完整 Xcode。未安装 FFmpeg 时，可执行 `swift run LumaRecChecks` 运行双语资源检查。

For capture changes, manually test permissions, preview, pause/resume, both orientations, each audio mode, device switching, and export failure recovery. Confirm that exported files play with audio. Camera and microphone access is not part of automated tests.

修改录制逻辑后，请手动验证权限、预览、暂停与继续、横竖屏、各音频模式、设备切换和导出失败恢复，并确认导出文件可正常播放且带有声音。自动测试不会访问摄像头或麦克风。

## Screenshots / 界面截图

The screenshot mode renders the app window and exits without requesting permissions or opening capture devices. `--language` applies only to that launch and does not change the saved preference.

截图模式会渲染应用窗口并退出，不请求权限、不打开录制设备。`--language` 仅影响本次启动，不改变已保存的偏好。

```sh
dist/LumaRec.app/Contents/MacOS/LumaRec --language en --screenshot docs/images/lumarec-en.png
dist/LumaRec.app/Contents/MacOS/LumaRec --language zh-Hans --screenshot docs/images/lumarec-zh.png
```

Keep the English and Chinese string catalogs and READMEs in sync. Add tests for changes that affect export results or data safety. Avoid committing generated apps, FFmpeg binaries, local recordings, secrets, or the original `work/` and `outputs/` folders.

请同步维护中英文字符串和 README。涉及导出结果或数据安全的修改应补充测试。不要提交生成的应用、FFmpeg 二进制、录制文件、密钥或原来的 `work/`、`outputs/` 目录。
