# Third-party notices / 第三方说明

LumaRec's source, documentation and included icon are provided under the [MIT License](LICENSE).
The distributed app uses Apple AppKit, AVFoundation, AudioToolbox, CoreMedia, CoreVideo,
CoreGraphics and QuartzCore supplied by macOS, with the system Swift runtime.
It does not bundle or invoke FFmpeg, libx264, Homebrew libraries or any other third-party runtime.
H.264 and AAC encoding/decoding use Apple's media services.

LumaRec 的源码、文档及随附图标采用 [MIT 许可证](LICENSE)。应用仅使用 macOS 提供的 Apple 框架及系统 Swift 运行时，不包含或调用 FFmpeg、libx264、Homebrew 库或其他第三方运行组件。H.264/AAC 编解码由 Apple 媒体服务完成。

BlackHole and Loopback are optional, independently installed virtual audio tools. They are
not required for camera/microphone recording, not included, and retain their own licenses.
Mentioning them does not imply affiliation or endorsement.

BlackHole 和 Loopback 是可选且独立安装的虚拟音频工具，摄像头及麦克风录制不需要这些工具。它们不包含在应用中，使用各自许可证；提及不代表合作或背书。
