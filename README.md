<p align="center">
  <img src="docs/images/icon.png" width="112" alt="LumaRec icon">
</p>

<h1 align="center">LumaRec</h1>

<p align="center">A small, native macOS camera recorder. Preview, record, and save MP4 videos locally.</p>

<p align="center">English · <a href="README.zh-CN.md">简体中文</a></p>

![LumaRec English interface](docs/images/lumarec-en.png)

LumaRec is an open-source Swift/AppKit utility for recording a camera with a microphone or virtual audio input. It keeps the everyday controls in one window: choose your devices, check the preview and audio meter, record, then export an MP4. No account or cloud service is required.

## Features

- Live camera preview and audio level meter.
- Start, pause, resume, and stop recording.
- Microphone, system input, and mixed audio modes.
- Landscape 1920 × 1080 or clockwise-rotated portrait 1080 × 1920 output, at 30 fps.
- H.264 video and AAC audio in MP4, with Standard, Compact, and High quality presets.
- An output folder of your choice; device and recording preferences are remembered.
- English by default, with a persistent **Language → 简体中文** switch.

Output dimensions are export targets. Actual capture quality depends on your camera; lower-resolution sources are scaled and padded to fit. Portrait mode rotates the camera image 90° clockwise.

## Requirements

- macOS 13 Ventura or later.
- A camera and an audio input, with Camera and Microphone permissions granted.
- [FFmpeg](https://ffmpeg.org/) with the `libx264` and AAC encoders. The Homebrew build works.
- Xcode Command Line Tools with Swift 5.9 or later to build from source.

## Build and run

Install the build tools and FFmpeg using [Homebrew](https://brew.sh/):

```sh
xcode-select --install  # Skip if the Command Line Tools are already installed.
brew install ffmpeg
git clone https://github.com/kangaroo-demo/LumaRec.git
cd LumaRec
./scripts/build-app.sh
open dist/LumaRec.app
```

The script compiles a release build, assembles the app bundle, and signs it locally with an ad hoc signature. The app is not notarized by Apple. Run the `.app` bundle so macOS can display its camera and microphone permission prompts correctly. You can also open `Package.swift` in Xcode to browse and edit the source.

To create a ZIP for the current Mac's architecture:

```sh
./scripts/build-app.sh --archive
```

FFmpeg is an external runtime dependency and is not included in the app or ZIP. LumaRec checks `/opt/homebrew/bin`, `/usr/local/bin`, and `PATH`. To use another installation, launch the executable directly:

```sh
LUMAREC_FFMPEG=/absolute/path/to/ffmpeg dist/LumaRec.app/Contents/MacOS/LumaRec
```

## Record a video

1. Open LumaRec and allow Camera and Microphone access.
2. Choose your camera and microphone. Click **Refresh** after plugging in another device.
3. Choose an audio source, output folder, orientation, and export quality.
4. Click the red record button. Use Pause to pause or resume.
5. Click Stop and wait for MP4 export. Open the saved file or reveal it in Finder.

Recordings default to your Movies folder. Filenames include a timestamp, orientation, and a short random ID; existing recordings are not overwritten. Stop and finish exporting before closing the app.

### System audio and mixing

**System** selects an audio input device; it does not capture speaker output by itself. To record macOS system audio, install and configure a virtual audio device such as [BlackHole](https://github.com/ExistentialAudio/BlackHole) or [Loopback](https://rogueamoeba.com/loopback/), route playback into it, and select it under **System input**. Use a Multi-Output Device in Audio MIDI Setup if you also want to hear the playback.

**Mix** attempts to capture the selected system input and microphone, then combines their audio tracks during export. Some device combinations cannot be added to one AVFoundation session. In that case, combine the sources in a virtual/aggregate input and record that single input. Selecting the same device in both menus records it only once. This version requires an audio input; silent video recording is not supported.

## Privacy and troubleshooting

Video processing runs locally. LumaRec has no analytics, account system, upload service, or automatic updater. Preferences are stored in macOS UserDefaults. The GitHub help action opens the project in your browser.

- **No preview or audio:** check **System Settings → Privacy & Security → Camera / Microphone**, then refresh devices.
- **FFmpeg not found:** run `brew install ffmpeg`, or set `LUMAREC_FFMPEG` as shown above.
- **Silent system audio:** check the virtual device's routing and the live audio meter.
- **Export failed:** the original temporary MOV is kept; the status line shows its path for export failures. Check the output folder's permissions and available disk space. Temporary recordings are not encrypted; delete recovered files when you no longer need them.

## Development

```sh
swift run LumaRecChecks --require-ffmpeg
./scripts/build-app.sh --archive
```

The tests cover localization and export behavior; when FFmpeg and FFprobe are available, they also encode and inspect synthetic videos without accessing a camera. GitHub Actions tests and builds the macOS app. Hardware capture still needs manual testing on a Mac.

See [CONTRIBUTING.md](CONTRIBUTING.md) for the project layout, screenshot commands, and contribution guidance.

## License

[MIT](LICENSE). FFmpeg and virtual audio tools are separate projects with their own licenses; see [third-party notices](THIRD_PARTY_NOTICES.md).
