<p align="center">
  <img src="docs/images/icon.png" width="112" alt="LumaRec 图标">
</p>

<h1 align="center">LumaRec · 流光录</h1>

<p align="center">一个原生 macOS 摄像头录制小工具，在本机预览、录制并保存 MP4 视频。</p>

<p align="center"><a href="README.md">English</a> · 简体中文</p>

![LumaRec 中文界面](docs/images/lumarec-zh.png)

LumaRec 使用 Swift 和 AppKit 开发，是一个开源的摄像头录制工具。选择摄像头、麦克风或虚拟音频输入，查看实时预览和音频电平，开始录制，结束后导出 MP4。无需注册账号，也无需云端服务。

## 功能

- 实时摄像头预览和音频电平。
- 开始、暂停、继续和停止录制。
- 麦克风、系统输入、混合三种音频模式。
- 横屏 1920 × 1080，或顺时针旋转的竖屏 1080 × 1920，以 30 fps 导出。
- MP4 输出，使用 H.264 视频和 AAC 音频，提供标准、轻量、高质量三档。
- 自选保存目录，并记住设备和录制偏好。
- **默认英文**，通过菜单栏 **Language → 简体中文** 切换，选择会自动保存。

输出分辨率是导出目标，实际画质取决于摄像头。低分辨率输入会按比例缩放并补边；竖屏模式将摄像头画面顺时针旋转 90°。

## 运行要求

- macOS 13 Ventura 或更新版本。
- 摄像头和音频输入设备，并授予摄像头、麦克风权限。
- 包含 `libx264` 和 AAC 编码器的 [FFmpeg](https://ffmpeg.org/)，可使用 Homebrew 版本。
- 从源码构建需要 Xcode Command Line Tools 和 Swift 5.9 或更新版本。

## 构建与运行

安装命令行工具，并通过 [Homebrew](https://brew.sh/) 安装 FFmpeg：

```sh
xcode-select --install  # 已安装 Command Line Tools 时跳过。
brew install ffmpeg
git clone https://github.com/kangaroo-demo/LumaRec.git
cd LumaRec
./scripts/build-app.sh
open dist/LumaRec.app
```

脚本会编译 Release 版本、组装应用，并进行本机临时签名（ad hoc）。应用未经过 Apple 公证。请运行 `.app`，以便 macOS 正确显示摄像头和麦克风权限提示。也可以在 Xcode 中打开 `Package.swift` 浏览和编辑源码。

为当前 Mac 架构生成 ZIP：

```sh
./scripts/build-app.sh --archive
```

FFmpeg 是独立的运行依赖，应用和 ZIP 不包含 FFmpeg。LumaRec 会查找 `/opt/homebrew/bin`、`/usr/local/bin` 和 `PATH`。使用自定义安装时，可直接启动可执行文件：

```sh
LUMAREC_FFMPEG=/absolute/path/to/ffmpeg dist/LumaRec.app/Contents/MacOS/LumaRec
```

## 录制步骤

1. 打开 LumaRec，允许访问摄像头和麦克风。
2. 选择摄像头和麦克风；插拔设备后点击“刷新”。
3. 选择音频来源、保存目录、画面方向和导出质量。
4. 点击红色按钮开始录制，用暂停按钮暂停或继续。
5. 点击停止并等待 MP4 导出完成，然后打开文件或在 Finder 中查看。

默认保存到当前用户的“影片”目录。文件名包含时间、方向和随机短 ID，不覆盖已有录制。退出前请先停止录制并等待导出完成。

### 系统音频与混音

“系统”模式选择的是音频输入设备，不能直接捕获扬声器输出。录制系统声音需要安装并配置 [BlackHole](https://github.com/ExistentialAudio/BlackHole) 或 [Loopback](https://rogueamoeba.com/loopback/) 等虚拟音频设备，把播放声音路由到该设备，再在“系统输入”中选择它。需要同时听到声音时，可在“音频 MIDI 设置”中建立多输出设备。

“混合”模式尝试同时录制所选系统输入和麦克风，并在导出时合并音轨。某些设备组合无法加入同一个 AVFoundation 会话；此时请先用虚拟或聚集输入设备合并音源，再录制该单个输入。两个菜单选择同一设备时只录一次。当前版本必须有音频输入，不支持无声视频录制。

## 隐私与常见问题

视频处理全部在本机完成。LumaRec 没有统计分析、账号系统、上传服务或自动更新器。偏好设置保存在 macOS UserDefaults 中；GitHub 帮助菜单会通过浏览器打开项目页面。

- **没有预览或声音：** 检查“系统设置 → 隐私与安全性 → 摄像头 / 麦克风”，然后刷新设备。
- **找不到 FFmpeg：** 执行 `brew install ffmpeg`，或按上面的方式指定 `LUMAREC_FFMPEG`。
- **系统声音为空：** 检查虚拟设备的音频路由和界面电平。
- **导出失败：** 原始临时 MOV 会保留，导出失败时状态栏会显示其路径。检查输出目录权限及磁盘空间。临时录制文件未加密，恢复文件后请自行删除不再需要的副本。

## 开发

```sh
swift run LumaRecChecks --require-ffmpeg
./scripts/build-app.sh --archive
```

测试覆盖双语资源和导出行为；安装 FFmpeg、FFprobe 后，还会通过合成视频验证实际编码结果，无需访问摄像头。GitHub Actions 会测试和构建 macOS 应用；真实硬件录制仍需在 Mac 上手动验证。

工程结构、截图命令和贡献方式见 [CONTRIBUTING.md](CONTRIBUTING.md)。

## 许可证

采用 [MIT 许可证](LICENSE)。FFmpeg 和虚拟音频工具是独立项目，使用各自许可证，详见[第三方说明](THIRD_PARTY_NOTICES.md)。
