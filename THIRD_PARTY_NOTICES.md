# Third-party notices / 第三方说明

LumaRec's source code, documentation, and included icon are provided under the [MIT License](LICENSE). It uses the macOS AppKit, AVFoundation, AudioToolbox, and QuartzCore frameworks supplied by Apple.

LumaRec 的源码、文档及随附图标采用 [MIT 许可证](LICENSE)，并使用 Apple 提供的 macOS AppKit、AVFoundation、AudioToolbox 和 QuartzCore 框架。

## FFmpeg

[FFmpeg](https://ffmpeg.org/) is installed separately and invoked as an external process. This repository and its build script do not distribute an FFmpeg binary or its libraries. FFmpeg's license depends on its build configuration; builds that enable `libx264` include GPL components. Consult [FFmpeg's legal page](https://ffmpeg.org/legal.html) and your distributor's notices. If you redistribute a modified package containing FFmpeg, review and meet that build's license and source-distribution obligations.

[FFmpeg](https://ffmpeg.org/) 需单独安装，LumaRec 通过外部进程调用。仓库及构建脚本不分发 FFmpeg 二进制或相关库。FFmpeg 的许可证取决于构建配置，启用 `libx264` 的版本包含 GPL 组件。请参考 [FFmpeg 法律说明](https://ffmpeg.org/legal.html)及发行方声明。若自行修改打包流程并包含 FFmpeg，应遵守该版本的许可证和源码分发要求。

## Virtual audio devices / 虚拟音频设备

[BlackHole](https://github.com/ExistentialAudio/BlackHole) and [Loopback](https://rogueamoeba.com/loopback/) are optional, independently installed tools. They are not included in LumaRec and remain subject to their own licenses. Mentioning them does not imply affiliation or endorsement.

[BlackHole](https://github.com/ExistentialAudio/BlackHole) 和 [Loopback](https://rogueamoeba.com/loopback/) 是可选且独立安装的工具，不包含在 LumaRec 中，使用各自的许可证。文档提及这些工具不代表合作或背书。
