LumaRec 1.0.0 — Installation / 安装说明

macOS 13 Ventura or later. Apple Silicon (arm64) only. Intel is not qualified and has no first-release download.
No Homebrew, FFmpeg, Xcode, terminal, account, or internet connection is needed to record/export.

This stable community release is locally (ad hoc) signed and is NOT Apple Developer ID signed or notarized.
macOS may block the first launch.
Never disable Gatekeeper, remove quarantine using commands, or install a runtime to run LumaRec.

1. Open the DMG and drag LumaRec to Applications. Eject the disk image.
   With the ZIP, double-click to extract and drag LumaRec.app to Applications.
2. Open LumaRec from Applications. If macOS blocks it as unverified, dismiss the message,
   open System Settings → Privacy & Security, and use Open Anyway for LumaRec,
   then confirm Open if macOS offers that normal approval. The wording varies by macOS version.
   Only do this for an official project download whose checksum you have verified.
   If Open Anyway is unavailable (for example a managed Mac), stop and report the message;
   do not weaken system security.
3. Allow Camera and Microphone when asked. Choose your camera and Mic input.
4. Wait for the live preview. Check the meter while speaking; choose a folder and quality.
5. Record, pause/resume, then Stop. Wait for MP4 export before quitting.
   Silent mode needs only Camera permission. Language → 简体中文 changes the interface.

All media stays on your Mac. No analytics or upload service.
Default output: Movies. Recovery originals: ~/Library/Application Support/LumaRec/Recordings.
Help → Recover recordings lets you select any unfinished recording and export it again.
Originals are not encrypted; delete unwanted recovery folders in Finder when no longer needed.
A damaged MOV from a crash or full disk may be unrecoverable, even though it is retained.

Input/Mix are optional advanced modes for an already configured virtual audio input.
They do not directly record speaker output. Camera + microphone needs no virtual driver.

────────────────────────────────────────

需要 macOS 13 Ventura 或更新版本；首版仅提供 Apple 芯片（arm64）应用。Intel 尚未完成验收，暂无下载。
录制和导出无需 Homebrew、FFmpeg、Xcode、终端、账号或网络。

此社区稳定版仅有本地临时签名，未使用 Apple Developer ID 签名，也未经过 Apple 公证。
macOS 可能拦截首次启动。
不要关闭 Gatekeeper、通过命令移除隔离标记，或安装额外运行环境。

1. 打开 DMG，将 LumaRec 拖入“应用程序”，再推出磁盘映像。
   使用 ZIP 时，双击解压，将 LumaRec.app 拖入“应用程序”。
2. 从“应用程序”打开 LumaRec。如系统因开发者未验证而拦截，关闭该提示，
   在“系统设置 → 隐私与安全性”中针对 LumaRec 点击“仍要打开”，并按系统提示确认。
   不同 macOS 版本的按钮文案可能不同。仅对核对过校验和的官方项目下载这样操作。
   若没有“仍要打开”（例如受管理的 Mac），请停止并反馈提示，不要降低系统安全性。
3. 系统询问时允许摄像头和麦克风访问，选择摄像头及“麦克风”输入。
4. 等待实时预览，对着麦克风说话确认电平，选择目录和质量。
5. 开始录制，可暂停或继续；停止后等待 MP4 导出完成再退出。
   “无声”模式仅需摄像头权限。通过 Language → 简体中文 切换界面。

所有素材留在本机，无统计分析、无上传服务。
默认输出到“影片”。恢复素材位于 ~/Library/Application Support/LumaRec/Recordings。
“帮助 → 恢复录制”可选择任意一条未完成的录制并重新导出。
原始素材未加密；不再需要时，可通过 Finder 删除对应恢复文件夹。
崩溃或磁盘写满时损坏的 MOV 即使保留，也可能无法修复。

“输入/混合”是给已配置虚拟音频输入的可选高级模式，不能直接录制扬声器声音。
摄像头加麦克风的基础录制无需任何虚拟驱动。

The published installers are the unchanged accepted artifacts. Candidate wording inside their bundled guides is historical; current release status: https://github.com/kangaroo-demo/LumaRec/releases/tag/v1.0.0
已发布安装包保持验收时原样，包内说明中的“候选”字样为历史记录；当前正式状态以以上发布页面为准。
