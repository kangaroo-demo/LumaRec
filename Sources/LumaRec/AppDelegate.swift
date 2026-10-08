import Cocoa
import AVFoundation
import AudioToolbox
import QuartzCore
import LumaRecCore

extension NSColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1.0) {
        let red = CGFloat((hex >> 16) & 0xff) / 255.0
        let green = CGFloat((hex >> 8) & 0xff) / 255.0
        let blue = CGFloat(hex & 0xff) / 255.0
        self.init(calibratedRed: red, green: green, blue: blue, alpha: alpha)
    }
}

struct CaptureDevice {
    let id: String
    let name: String
    let device: AVCaptureDevice

    var label: String {
        name
    }
}

private enum DefaultsKey {
    static let outputDirectory = "outputDirectory"
    static let cameraDeviceID = "cameraDeviceID"
    static let cameraDeviceName = "cameraDeviceName"
    static let builtinAudioDeviceID = "builtinAudioDeviceID"
    static let builtinAudioDeviceName = "builtinAudioDeviceName"
    static let micAudioDeviceID = "micAudioDeviceID"
    static let micAudioDeviceName = "micAudioDeviceName"
    static let audioMode = "audioMode"
    static let orientation = "orientation"
    static let exportQuality = "exportQuality"
}

final class PanelView: NSView {
    var fillColor: NSColor
    var strokeColor: NSColor
    var radius: CGFloat

    init(frame: NSRect, fillColor: NSColor, strokeColor: NSColor, radius: CGFloat) {
        self.fillColor = fillColor
        self.strokeColor = strokeColor
        self.radius = radius
        super.init(frame: frame)
        wantsLayer = true
        layer?.backgroundColor = fillColor.cgColor
        layer?.borderColor = strokeColor.cgColor
        layer?.borderWidth = 1
        layer?.cornerRadius = radius
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class CameraPreviewView: NSView {
    let previewLayer = AVCaptureVideoPreviewLayer()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer = CALayer()
        layer?.backgroundColor = NSColor.black.cgColor
        layer?.cornerRadius = 14
        layer?.masksToBounds = true
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.backgroundColor = NSColor.black.cgColor
        layer?.addSublayer(previewLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()
        previewLayer.frame = bounds
    }
}

final class VerticallyCenteredTextFieldCell: NSTextFieldCell {
    private func centeredRect(for rect: NSRect) -> NSRect {
        var adjusted = super.drawingRect(forBounds: rect)
        let textHeight = cellSize(forBounds: rect).height
        if adjusted.height > textHeight {
            adjusted.origin.y += (adjusted.height - textHeight) / 2
            adjusted.size.height = textHeight
        }
        return adjusted
    }

    override func drawingRect(forBounds rect: NSRect) -> NSRect {
        centeredRect(for: rect)
    }

    override func edit(withFrame rect: NSRect, in controlView: NSView, editor textObj: NSText, delegate: Any?, event: NSEvent?) {
        super.edit(withFrame: centeredRect(for: rect), in: controlView, editor: textObj, delegate: delegate, event: event)
    }

    override func select(withFrame rect: NSRect, in controlView: NSView, editor textObj: NSText, delegate: Any?, start selStart: Int, length selLength: Int) {
        super.select(withFrame: centeredRect(for: rect), in: controlView, editor: textObj, delegate: delegate, start: selStart, length: selLength)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var controller: RecorderWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        let controller = RecorderWindowController()
        self.controller = controller
        buildMenu()
        controller.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)

        // Render documentation and verify the app bundle without accessing any devices.
        let arguments = ProcessInfo.processInfo.arguments
        if let index = arguments.firstIndex(of: "--screenshot"), arguments.indices.contains(index + 1) {
            let path = arguments[index + 1]
            DispatchQueue.main.async {
                guard let view = controller.window?.contentView,
                      let bitmap = view.bitmapImageRepForCachingDisplay(in: view.bounds) else {
                    exit(1)
                }
                view.layoutSubtreeIfNeeded()
                view.cacheDisplay(in: view.bounds, to: bitmap)
                do {
                    guard let png = bitmap.representation(using: .png, properties: [:]) else { exit(1) }
                    try png.write(to: URL(fileURLWithPath: path))
                    NSApp.terminate(nil)
                } catch {
                    fputs("Unable to save preview: \(error.localizedDescription)\n", stderr)
                    exit(1)
                }
            }
        }
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard controller?.isBusy != true else {
            controller?.showBusyAlert()
            return .terminateCancel
        }
        return .terminateNow
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    private func buildMenu() {
        let menu = NSMenu()
        let appItem = NSMenuItem()
        let appMenu = NSMenu(title: "LumaRec")
        appMenu.addItem(withTitle: L("About LumaRec"), action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: L("Hide LumaRec"), action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        let hideOthers = appMenu.addItem(withTitle: L("Hide Others"), action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
        hideOthers.keyEquivalentModifierMask = [.command, .option]
        appMenu.addItem(withTitle: L("Show All"), action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: L("Quit LumaRec"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu
        menu.addItem(appItem)

        let editItem = NSMenuItem()
        let editMenu = NSMenu(title: L("Edit"))
        for (title, selector, key) in [("Undo", "undo:", "z"), ("Redo", "redo:", "Z"),
                                       ("Cut", "cut:", "x"), ("Copy", "copy:", "c"),
                                       ("Paste", "paste:", "v"), ("Select All", "selectAll:", "a")] {
            editMenu.addItem(withTitle: L(title), action: Selector(selector), keyEquivalent: key)
        }
        editItem.submenu = editMenu
        menu.addItem(editItem)

        let languageItem = NSMenuItem()
        let languageMenu = NSMenu(title: L("Language"))
        for language in AppLanguage.allCases {
            let item = NSMenuItem(title: language.title, action: #selector(changeLanguage(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = language.rawValue
            item.state = L10n.language == language ? .on : .off
            languageMenu.addItem(item)
        }
        languageItem.submenu = languageMenu
        menu.addItem(languageItem)

        let helpItem = NSMenuItem()
        let helpMenu = NSMenu(title: L("Help"))
        let project = helpMenu.addItem(withTitle: L("Open project on GitHub"), action: #selector(openProject), keyEquivalent: "")
        project.target = self
        helpItem.submenu = helpMenu
        menu.addItem(helpItem)
        NSApp.mainMenu = menu
    }

    @objc private func changeLanguage(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String, let language = AppLanguage(rawValue: rawValue),
              language != L10n.language else { return }
        guard controller?.isBusy != true else {
            controller?.showBusyAlert()
            return
        }
        UserDefaults.standard.set(language.rawValue, forKey: L10n.preferenceKey)
        L10n.language = language
        controller?.reloadInterface()
        buildMenu()
    }

    @objc private func openProject() {
        NSWorkspace.shared.open(URL(string: "https://github.com/kangaroo-demo/LumaRec")!)
    }
}

final class RecorderWindowController: NSWindowController, NSWindowDelegate, AVCaptureFileOutputRecordingDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    private let rootBackground = PanelView(frame: .zero, fillColor: NSColor(hex: 0xF5F5F7), strokeColor: NSColor(hex: 0xF5F5F7), radius: 0)
    private let toolbarPanel = PanelView(frame: .zero, fillColor: NSColor(hex: 0xFFFFFF), strokeColor: NSColor(hex: 0xE5E7EB), radius: 0)
    private let controlPanel = PanelView(frame: .zero, fillColor: NSColor(hex: 0xF5F5F7), strokeColor: NSColor(hex: 0xF5F5F7), radius: 0)
    private let previewPanel = PanelView(frame: .zero, fillColor: NSColor(hex: 0xFFFFFF), strokeColor: NSColor(hex: 0xE5E7EB), radius: 18)
    private let previewFrame = PanelView(frame: .zero, fillColor: NSColor(hex: 0x000000), strokeColor: NSColor(hex: 0xD1D5DB), radius: 16)
    private let transportPanel = PanelView(frame: .zero, fillColor: NSColor(hex: 0xFFFFFF), strokeColor: NSColor(hex: 0xE5E7EB), radius: 18)
    private let previewView = CameraPreviewView(frame: .zero)

    private let outputField = NSTextField()
    private let filenameField = NSTextField()
    private let cameraPopup = NSPopUpButton()
    private let builtinPopup = NSPopUpButton()
    private let micPopup = NSPopUpButton()
    private let fileTypePopup = NSPopUpButton()
    private let modePopup = NSPopUpButton()
    private let resolutionPopup = NSPopUpButton()
    private let audioMode = NSSegmentedControl(labels: [L("System"), L("Mic"), L("Mix")], trackingMode: .selectOne, target: nil, action: nil)
    private let orientation = NSSegmentedControl(labels: [L("Landscape"), L("Portrait")], trackingMode: .selectOne, target: nil, action: nil)
    private let refreshButton = NSButton(title: L("Refresh devices"), target: nil, action: nil)
    private let startButton = NSButton(title: "", target: nil, action: nil)
    private let pauseButton = NSButton(title: "Ⅱ", target: nil, action: nil)
    private let stopButton = NSButton(title: "■", target: nil, action: nil)
    private let chooseButton = NSButton(title: L("Browse"), target: nil, action: nil)

    private let statusLabel = NSTextField(labelWithString: L("Refresh devices to get started."))
    private let previewStatusLabel = NSTextField(labelWithString: L("Offline"))
    private let cameraNameLabel = NSTextField(labelWithString: L("No camera"))
    private let recordStateLabel = NSTextField(labelWithString: L("Idle"))
    private let timerLabel = NSTextField(labelWithString: "00:00")
    private let recordDot = NSView(frame: NSRect(x: 0, y: 0, width: 10, height: 10))
    private let placeholderLabel = NSTextField(labelWithString: L("Camera preview"))
    private let savedPathLabel = NSTextField(labelWithString: L("Choose an output folder"))
    private let audioMeterView = NSView()

    private var videoDevices: [CaptureDevice] = []
    private var audioDevices: [CaptureDevice] = []

    private let captureSession = AVCaptureSession()
    private let movieOutput = AVCaptureMovieFileOutput()
    private let audioLevelOutput = AVCaptureAudioDataOutput()
    private let sessionQueue = DispatchQueue(label: "camera-recorder.capture-session")
    private let audioLevelQueue = DispatchQueue(label: "camera-recorder.audio-level")
    private var isSessionConfigured = false
    private var configuredAudioInputCount = 0
    private var audioMeterBars: [NSView] = []
    private var lastAudioMeterUpdate: TimeInterval = 0
    private var lastObservedAudioLevel: CGFloat = 0

    private var recordingStartedAt: Date?
    private var pauseStartedAt: Date?
    private var accumulatedPausedDuration: TimeInterval = 0
    private var isRecordingPaused = false
    private var recordTimer: Timer?
    private var tempMovieURL: URL?
    private var finalMP4URL: URL?
    private var recordingAudioInputCount = 0
    private var recordingAudioMode = 0
    private var isRecordingInProgress = false
    private var isExporting = false
    private var isConfiguring = false
    private var exportProcess: Process?
    private var exportConfiguration = ExportConfiguration()

    var isBusy: Bool { isRecordingInProgress || isExporting }

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1280, height: 800),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = L("LumaRec")
        window.appearance = NSAppearance(named: .aqua)
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.minSize = NSSize(width: 1280, height: 800)
        self.init(window: window)
        window.delegate = self
        buildUI()
        previewView.previewLayer.session = captureSession
        audioLevelOutput.setSampleBufferDelegate(self, queue: audioLevelQueue)
        if !ProcessInfo.processInfo.arguments.contains("--screenshot") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                self?.refreshDevices()
            }
        }
    }

    func reloadInterface() {
        persistCurrentSettings()
        window?.contentView?.subviews.forEach { $0.removeFromSuperview() }
        for panel in [toolbarPanel, controlPanel, previewPanel, previewFrame, transportPanel] {
            panel.subviews.forEach { $0.removeFromSuperview() }
        }
        buildUI()
        if !ProcessInfo.processInfo.arguments.contains("--screenshot") { refreshDevices() }
    }

    func showBusyAlert() {
        alert(L("Finish the recording first"), L("Stop recording and wait for MP4 export before changing the language or closing LumaRec."))
    }

    private func buildUI() {
        guard let content = window?.contentView else { return }
        for (index, title) in [L("System"), L("Mic"), L("Mix")].enumerated() { audioMode.setLabel(title, forSegment: index) }
        for (index, title) in [L("Landscape"), L("Portrait")].enumerated() { orientation.setLabel(title, forSegment: index) }
        chooseButton.title = "…"
        previewStatusLabel.stringValue = L("Offline")
        cameraNameLabel.stringValue = L("No camera")
        placeholderLabel.stringValue = L("Camera preview")
        placeholderLabel.isHidden = false
        statusLabel.stringValue = L("Refresh devices to get started.")
        content.addSubview(rootBackground)
        rootBackground.frame = content.bounds
        rootBackground.autoresizingMask = [.width, .height]

        toolbarPanel.frame = NSRect(x: 0, y: 724, width: 1280, height: 76)
        previewPanel.frame = NSRect(x: 20, y: 154, width: 860, height: 542)
        controlPanel.frame = NSRect(x: 900, y: 154, width: 360, height: 542)
        transportPanel.frame = NSRect(x: 20, y: 24, width: 1240, height: 104)
        content.addSubview(toolbarPanel)
        content.addSubview(controlPanel)
        content.addSubview(previewPanel)
        content.addSubview(transportPanel)

        buildToolbar()
        buildPreviewPanel()
        buildControlPanel()
        buildTransportBar()
        setRecordingState(active: false)
        populateEmptyState()
    }

    private func buildToolbar() {
        let titleGroup = NSView(frame: NSRect(x: 470, y: 18, width: 340, height: 36))
        titleGroup.addSubview(makeSymbolView("camera.viewfinder", frame: NSRect(x: 64, y: 7, width: 24, height: 24), color: NSColor(hex: 0x1F2937)))
        let appTitle = makeLabel(L("LumaRec"), size: 19, weight: .semibold, color: NSColor(hex: 0x1F2937))
        appTitle.frame = NSRect(x: 96, y: 4, width: 180, height: 28)
        titleGroup.addSubview(appTitle)
        toolbarPanel.addSubview(titleGroup)

        modePopup.frame = NSRect(x: 870, y: 22, width: 120, height: 32)
        modePopup.removeAllItems()
        modePopup.addItems(withTitles: [L("Standard"), L("Compact"), L("High quality")])
        modePopup.selectItem(at: savedSegment(DefaultsKey.exportQuality, defaultValue: 0, upperBound: 2))
        modePopup.target = self
        modePopup.action = #selector(qualityChanged)
        stylePopup(modePopup)
        toolbarPanel.addSubview(modePopup)

        addToolbarItem("gearshape", L("Settings"), x: 1040, action: #selector(showSettings))
        addToolbarItem("folder", L("Files"), x: 1110, action: #selector(openOutputFolder))
        addToolbarItem("questionmark.circle", L("Help"), x: 1180, action: #selector(showHelp))
    }

    private func addToolbarItem(_ symbolName: String, _ labelText: String, x: CGFloat, action: Selector) {
        let button = NSButton(frame: NSRect(x: x + 8, y: 36, width: 32, height: 28))
        button.isBordered = false
        button.image = makeSymbolImage(symbolName, color: NSColor(hex: 0x4B5563), pointSize: 22)
        button.imagePosition = .imageOnly
        button.contentTintColor = NSColor(hex: 0x4B5563)
        button.target = self
        button.action = action
        button.sendAction(on: .leftMouseUp)
        toolbarPanel.addSubview(button)

        let text = makeLabel(labelText, size: 12, weight: .regular, color: NSColor(hex: 0x4B5563))
        text.alignment = .center
        text.frame = NSRect(x: x - 10, y: 14, width: 68, height: 18)
        toolbarPanel.addSubview(text)
    }

    private func buildControlPanel() {
        let deviceCard = makeSectionCard(title: L("Devices"), frame: NSRect(x: 0, y: 392, width: 360, height: 150))
        controlPanel.addSubview(deviceCard)
        refreshButton.frame = NSRect(x: 266, y: 110, width: 70, height: 26)
        refreshButton.title = L("Refresh")
        styleButton(refreshButton, fill: NSColor(hex: 0xF9FAFB), text: NSColor(hex: 0x111827))
        refreshButton.target = self
        refreshButton.action = #selector(refreshDevices)
        deviceCard.addSubview(refreshButton)
        addFormLabel(L("Camera"), x: 18, y: 82, parent: deviceCard)
        cameraPopup.frame = NSRect(x: 112, y: 72, width: 224, height: 34)
        stylePopup(cameraPopup)
        cameraPopup.target = self
        cameraPopup.action = #selector(selectionChanged)
        deviceCard.addSubview(cameraPopup)
        addFormLabel(L("Microphone"), x: 18, y: 31, parent: deviceCard)
        micPopup.frame = NSRect(x: 112, y: 21, width: 224, height: 34)
        stylePopup(micPopup)
        micPopup.target = self
        micPopup.action = #selector(selectionChanged)
        deviceCard.addSubview(micPopup)

        let audioCard = makeSectionCard(title: L("Audio"), frame: NSRect(x: 0, y: 258, width: 360, height: 120))
        controlPanel.addSubview(audioCard)
        addFormLabel(L("Source"), x: 18, y: 54, parent: audioCard)
        audioMode.frame = NSRect(x: 112, y: 48, width: 224, height: 32)
        audioMode.selectedSegment = savedSegment(DefaultsKey.audioMode, defaultValue: 1, upperBound: 2)
        audioMode.segmentStyle = .rounded
        audioMode.target = self
        audioMode.action = #selector(selectionChanged)
        audioCard.addSubview(audioMode)
        addFormLabel(L("System input"), x: 18, y: 18, parent: audioCard)
        builtinPopup.frame = NSRect(x: 112, y: 10, width: 224, height: 34)
        stylePopup(builtinPopup)
        builtinPopup.target = self
        builtinPopup.action = #selector(selectionChanged)
        audioCard.addSubview(builtinPopup)

        let outputCard = makeSectionCard(title: L("Output"), frame: NSRect(x: 0, y: 80, width: 360, height: 164))
        controlPanel.addSubview(outputCard)
        addFormLabel(L("Folder"), x: 18, y: 96, parent: outputCard)
        outputField.frame = NSRect(x: 112, y: 86, width: 174, height: 34)
        outputField.stringValue = ProcessInfo.processInfo.arguments.contains("--screenshot") ? "~/Movies" : (UserDefaults.standard.string(forKey: DefaultsKey.outputDirectory) ?? FileManager.default.urls(for: .moviesDirectory, in: .userDomainMask).first?.path ?? NSHomeDirectory())
        styleTextField(outputField)
        outputCard.addSubview(outputField)
        chooseButton.frame = NSRect(x: 294, y: 86, width: 50, height: 34)
        styleButton(chooseButton, fill: NSColor(hex: 0xF9FAFB), text: NSColor(hex: 0x111827))
        chooseButton.toolTip = L("Choose output folder")
        chooseButton.target = self
        chooseButton.action = #selector(chooseOutputDirectory)
        outputCard.addSubview(chooseButton)
        addFormLabel(L("Filename"), x: 18, y: 55, parent: outputCard)
        filenameField.frame = NSRect(x: 112, y: 45, width: 224, height: 34)
        filenameField.stringValue = L("Automatic filename")
        styleTextField(filenameField)
        filenameField.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        filenameField.isEditable = false
        outputCard.addSubview(filenameField)
        addFormLabel(L("Format"), x: 18, y: 14, parent: outputCard)
        fileTypePopup.frame = NSRect(x: 112, y: 4, width: 224, height: 34)
        fileTypePopup.removeAllItems()
        fileTypePopup.addItems(withTitles: ["MP4"])
        stylePopup(fileTypePopup)
        outputCard.addSubview(fileTypePopup)

        let pictureCard = makeSectionCard(title: L("Video"), frame: NSRect(x: 0, y: 0, width: 360, height: 66))
        controlPanel.addSubview(pictureCard)
        addFormLabel(L("Orientation"), x: 18, y: 14, parent: pictureCard)
        orientation.frame = NSRect(x: 112, y: 7, width: 224, height: 32)
        orientation.selectedSegment = savedSegment(DefaultsKey.orientation, defaultValue: 0, upperBound: 1)
        orientation.segmentStyle = .rounded
        orientation.target = self
        orientation.action = #selector(orientationChanged)
        pictureCard.addSubview(orientation)
    }

    private func buildPreviewPanel() {
        previewFrame.frame = NSRect(x: 0, y: 0, width: 860, height: 542)
        previewPanel.addSubview(previewFrame)
        previewView.frame = NSRect(x: 0, y: 0, width: 860, height: 542)
        previewFrame.addSubview(previewView)

        let liveChip = PanelView(frame: NSRect(x: 18, y: 486, width: 110, height: 34), fillColor: NSColor(hex: 0x111111, alpha: 0.62), strokeColor: NSColor(hex: 0x111111, alpha: 0.18), radius: 10)
        previewFrame.addSubview(liveChip)
        let liveDot = NSView(frame: NSRect(x: 14, y: 12, width: 10, height: 10))
        liveDot.wantsLayer = true
        liveDot.layer?.cornerRadius = 5
        liveDot.layer?.backgroundColor = NSColor(hex: 0x4ADE80).cgColor
        liveChip.addSubview(liveDot)
        previewStatusLabel.frame = NSRect(x: 30, y: 7, width: 72, height: 20)
        previewStatusLabel.alignment = .center
        previewStatusLabel.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
        previewStatusLabel.textColor = .white
        liveChip.addSubview(previewStatusLabel)

        let deviceChip = PanelView(frame: NSRect(x: 18, y: 18, width: 194, height: 38), fillColor: NSColor(hex: 0x111111, alpha: 0.60), strokeColor: NSColor(hex: 0x111111, alpha: 0.18), radius: 9)
        previewFrame.addSubview(deviceChip)
        cameraNameLabel.frame = NSRect(x: 42, y: 9, width: 142, height: 20)
        cameraNameLabel.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
        cameraNameLabel.textColor = .white
        cameraNameLabel.lineBreakMode = .byTruncatingMiddle
        deviceChip.addSubview(cameraNameLabel)
        deviceChip.addSubview(makeSymbolView("video.fill", frame: NSRect(x: 13, y: 10, width: 20, height: 18), color: .white))

        placeholderLabel.frame = NSRect(x: 0, y: 246, width: 860, height: 40)
        placeholderLabel.alignment = .center
        placeholderLabel.font = NSFont.systemFont(ofSize: 28, weight: .bold)
        placeholderLabel.textColor = NSColor(hex: 0x6B7280)
        placeholderLabel.backgroundColor = .clear
        placeholderLabel.isBezeled = false
        placeholderLabel.isEditable = false
        previewFrame.addSubview(placeholderLabel)
    }

    private func buildTransportBar() {
        recordDot.frame = NSRect(x: 24, y: 56, width: 12, height: 12)
        recordDot.wantsLayer = true
        recordDot.layer?.cornerRadius = 6
        transportPanel.addSubview(recordDot)

        recordStateLabel.frame = NSRect(x: 48, y: 48, width: 160, height: 28)
        recordStateLabel.font = NSFont.systemFont(ofSize: 17, weight: .semibold)
        recordStateLabel.textColor = NSColor(hex: 0x111827)
        transportPanel.addSubview(recordStateLabel)

        savedPathLabel.frame = NSRect(x: 48, y: 24, width: 290, height: 22)
        savedPathLabel.stringValue = LF("Save to: %@", outputField.stringValue)
        savedPathLabel.font = NSFont.systemFont(ofSize: 13, weight: .regular)
        savedPathLabel.textColor = NSColor(hex: 0x6B7280)
        savedPathLabel.lineBreakMode = .byTruncatingMiddle
        transportPanel.addSubview(savedPathLabel)

        let divider1 = PanelView(frame: NSRect(x: 350, y: 24, width: 1, height: 56), fillColor: NSColor(hex: 0xE5E7EB), strokeColor: NSColor(hex: 0xE5E7EB), radius: 0)
        transportPanel.addSubview(divider1)

        transportPanel.addSubview(makeSymbolView("clock", frame: NSRect(x: 386, y: 40, width: 30, height: 30), color: NSColor(hex: 0x111827)))

        let durationLabel = makeLabel(L("Duration"), size: 12, weight: .regular, color: NSColor(hex: 0x6B7280))
        durationLabel.frame = NSRect(x: 430, y: 59, width: 84, height: 18)
        transportPanel.addSubview(durationLabel)
        timerLabel.frame = NSRect(x: 430, y: 28, width: 110, height: 34)
        timerLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 28, weight: .medium)
        timerLabel.textColor = NSColor(hex: 0x111827)
        transportPanel.addSubview(timerLabel)

        startButton.frame = NSRect(x: 584, y: 22, width: 62, height: 62)
        startButton.image = makeSymbolImage("play.fill", color: .white, pointSize: 28)
        startButton.imagePosition = .imageOnly
        styleRoundButton(startButton, fill: NSColor(hex: 0xFF3B30), text: .white)
        startButton.toolTip = L("Start recording")
        startButton.target = self
        startButton.action = #selector(startRecording)
        startButton.sendAction(on: .leftMouseUp)
        transportPanel.addSubview(startButton)

        pauseButton.frame = NSRect(x: 674, y: 31, width: 46, height: 46)
        pauseButton.image = makeSymbolImage("pause.fill", color: NSColor(hex: 0x4B5563))
        pauseButton.imagePosition = .imageOnly
        styleRoundButton(pauseButton, fill: NSColor(hex: 0xF3F4F6), text: NSColor(hex: 0x4B5563))
        pauseButton.toolTip = L("Pause recording")
        pauseButton.target = self
        pauseButton.action = #selector(togglePauseRecording)
        pauseButton.sendAction(on: .leftMouseUp)
        pauseButton.isEnabled = false
        transportPanel.addSubview(pauseButton)

        stopButton.frame = NSRect(x: 740, y: 31, width: 46, height: 46)
        stopButton.image = makeSymbolImage("stop.fill", color: NSColor(hex: 0x4B5563))
        stopButton.imagePosition = .imageOnly
        styleRoundButton(stopButton, fill: NSColor(hex: 0xF3F4F6), text: NSColor(hex: 0x4B5563))
        stopButton.toolTip = L("Stop recording")
        stopButton.target = self
        stopButton.action = #selector(stopRecording)
        stopButton.sendAction(on: .leftMouseUp)
        stopButton.isEnabled = false
        transportPanel.addSubview(stopButton)

        transportPanel.addSubview(makeSymbolView("mic", frame: NSRect(x: 852, y: 44, width: 26, height: 26), color: NSColor(hex: 0x111827)))
        let meterLabel = makeLabel(L("Audio level"), size: 12, weight: .regular, color: NSColor(hex: 0x6B7280))
        meterLabel.frame = NSRect(x: 890, y: 60, width: 90, height: 18)
        transportPanel.addSubview(meterLabel)
        audioMeterView.frame = NSRect(x: 890, y: 34, width: 190, height: 22)
        buildStaticAudioMeter()
        transportPanel.addSubview(audioMeterView)

        resolutionPopup.frame = NSRect(x: 1090, y: 28, width: 126, height: 48)
        resolutionPopup.removeAllItems()
        resolutionPopup.addItems(withTitles: ["1920×1080", "1080×1920"])
        resolutionPopup.selectItem(at: orientation.selectedSegment)
        stylePopup(resolutionPopup)
        resolutionPopup.target = self
        resolutionPopup.action = #selector(resolutionPopupChanged)
        transportPanel.addSubview(resolutionPopup)

        statusLabel.frame = NSRect(x: 48, y: 5, width: 1120, height: 18)
        statusLabel.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        statusLabel.textColor = NSColor(hex: 0x374151)
        statusLabel.lineBreakMode = .byTruncatingMiddle
        statusLabel.isHidden = false
        transportPanel.addSubview(statusLabel)
    }

    private func populateEmptyState() {
        cameraPopup.removeAllItems()
        builtinPopup.removeAllItems()
        micPopup.removeAllItems()
        cameraPopup.addItem(withTitle: L("Refresh devices"))
        builtinPopup.addItem(withTitle: L("Refresh devices"))
        micPopup.addItem(withTitle: L("Refresh devices"))
    }

    private func addControlLabel(_ text: String, y: CGFloat) {
        let label = makeLabel(text, size: 12, weight: .semibold, color: NSColor(hex: 0x6B7280))
        label.frame = NSRect(x: 28, y: y, width: 304, height: 20)
        controlPanel.addSubview(label)
    }

    private func makeSectionCard(title: String, frame: NSRect) -> PanelView {
        let card = PanelView(frame: frame, fillColor: .white, strokeColor: NSColor(hex: 0xE5E7EB), radius: 12)
        let label = makeLabel(title, size: 17, weight: .semibold, color: NSColor(hex: 0x111827))
        label.frame = NSRect(x: 18, y: frame.height - 36, width: frame.width - 36, height: 24)
        card.addSubview(label)
        return card
    }

    private func addFormLabel(_ text: String, x: CGFloat, y: CGFloat, parent: NSView) {
        let label = makeLabel(text, size: 14, weight: .regular, color: NSColor(hex: 0x374151))
        label.frame = NSRect(x: x, y: y, width: 88, height: 18)
        parent.addSubview(label)
    }

    private func makeSymbolImage(_ symbolName: String, color: NSColor, pointSize: CGFloat = 18) -> NSImage? {
        guard let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil) else {
            return makeFallbackIcon(symbolName, color: color, pointSize: pointSize)
        }
        let config = NSImage.SymbolConfiguration(pointSize: pointSize, weight: .regular)
        let configured = image.withSymbolConfiguration(config) ?? image
        configured.isTemplate = true
        return configured
    }

    private func makeFallbackIcon(_ symbolName: String, color: NSColor, pointSize: CGFloat) -> NSImage {
        let size = NSSize(width: pointSize, height: pointSize)
        let image = NSImage(size: size)
        image.lockFocus()
        color.setStroke()
        color.setFill()
        let line = NSBezierPath()
        line.lineWidth = max(1.8, pointSize / 12)

        if symbolName.contains("folder") {
            let body = NSBezierPath(roundedRect: NSRect(x: 2, y: 4, width: pointSize - 4, height: pointSize - 10), xRadius: 3, yRadius: 3)
            body.stroke()
            line.move(to: NSPoint(x: 4, y: pointSize - 9))
            line.line(to: NSPoint(x: pointSize * 0.38, y: pointSize - 9))
            line.line(to: NSPoint(x: pointSize * 0.46, y: pointSize - 6))
            line.line(to: NSPoint(x: pointSize - 4, y: pointSize - 6))
            line.stroke()
        } else if symbolName.contains("gear") {
            NSBezierPath(ovalIn: NSRect(x: 4, y: 4, width: pointSize - 8, height: pointSize - 8)).stroke()
            NSBezierPath(ovalIn: NSRect(x: pointSize * 0.38, y: pointSize * 0.38, width: pointSize * 0.24, height: pointSize * 0.24)).stroke()
            for i in 0..<8 {
                let angle = CGFloat(i) * .pi / 4
                line.move(to: NSPoint(x: pointSize / 2 + cos(angle) * pointSize * 0.34, y: pointSize / 2 + sin(angle) * pointSize * 0.34))
                line.line(to: NSPoint(x: pointSize / 2 + cos(angle) * pointSize * 0.46, y: pointSize / 2 + sin(angle) * pointSize * 0.46))
            }
            line.stroke()
        } else if symbolName.contains("questionmark") {
            let attrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: pointSize * 0.78, weight: .semibold), .foregroundColor: color]
            "?".draw(in: NSRect(x: 0, y: -1, width: pointSize, height: pointSize), withAttributes: attrs)
            NSBezierPath(ovalIn: NSRect(x: 2, y: 2, width: pointSize - 4, height: pointSize - 4)).stroke()
        } else if symbolName.contains("video") || symbolName.contains("camera") {
            NSBezierPath(roundedRect: NSRect(x: 3, y: 6, width: pointSize * 0.62, height: pointSize * 0.48), xRadius: 3, yRadius: 3).stroke()
            line.move(to: NSPoint(x: pointSize * 0.68, y: pointSize * 0.38))
            line.line(to: NSPoint(x: pointSize - 3, y: pointSize * 0.24))
            line.line(to: NSPoint(x: pointSize - 3, y: pointSize * 0.76))
            line.line(to: NSPoint(x: pointSize * 0.68, y: pointSize * 0.62))
            line.stroke()
        } else if symbolName.contains("clock") {
            NSBezierPath(ovalIn: NSRect(x: 3, y: 3, width: pointSize - 6, height: pointSize - 6)).stroke()
            line.move(to: NSPoint(x: pointSize / 2, y: pointSize / 2))
            line.line(to: NSPoint(x: pointSize / 2, y: pointSize * 0.76))
            line.move(to: NSPoint(x: pointSize / 2, y: pointSize / 2))
            line.line(to: NSPoint(x: pointSize * 0.68, y: pointSize * 0.42))
            line.stroke()
        } else if symbolName.contains("mic") {
            NSBezierPath(roundedRect: NSRect(x: pointSize * 0.36, y: pointSize * 0.34, width: pointSize * 0.28, height: pointSize * 0.50), xRadius: pointSize * 0.14, yRadius: pointSize * 0.14).stroke()
            line.move(to: NSPoint(x: pointSize * 0.25, y: pointSize * 0.52))
            line.curve(to: NSPoint(x: pointSize * 0.75, y: pointSize * 0.52), controlPoint1: NSPoint(x: pointSize * 0.25, y: pointSize * 0.20), controlPoint2: NSPoint(x: pointSize * 0.75, y: pointSize * 0.20))
            line.move(to: NSPoint(x: pointSize * 0.50, y: pointSize * 0.18))
            line.line(to: NSPoint(x: pointSize * 0.50, y: pointSize * 0.05))
            line.stroke()
        } else if symbolName.contains("record") || symbolName.contains("circle.fill") {
            NSBezierPath(ovalIn: NSRect(x: pointSize * 0.24, y: pointSize * 0.24, width: pointSize * 0.52, height: pointSize * 0.52)).fill()
        } else if symbolName.contains("play") {
            let path = NSBezierPath()
            path.move(to: NSPoint(x: pointSize * 0.34, y: pointSize * 0.22))
            path.line(to: NSPoint(x: pointSize * 0.34, y: pointSize * 0.78))
            path.line(to: NSPoint(x: pointSize * 0.78, y: pointSize * 0.50))
            path.close()
            path.fill()
        } else if symbolName.contains("pause") {
            NSBezierPath(rect: NSRect(x: pointSize * 0.30, y: pointSize * 0.24, width: pointSize * 0.12, height: pointSize * 0.52)).fill()
            NSBezierPath(rect: NSRect(x: pointSize * 0.58, y: pointSize * 0.24, width: pointSize * 0.12, height: pointSize * 0.52)).fill()
        } else if symbolName.contains("stop") {
            NSBezierPath(rect: NSRect(x: pointSize * 0.30, y: pointSize * 0.30, width: pointSize * 0.40, height: pointSize * 0.40)).fill()
        }

        image.unlockFocus()
        image.isTemplate = false
        return image
    }

    private func makeSymbolView(_ symbolName: String, frame: NSRect, color: NSColor) -> NSImageView {
        let view = NSImageView(frame: frame)
        view.image = makeSymbolImage(symbolName, color: color, pointSize: max(frame.width, frame.height))
        view.imageScaling = .scaleProportionallyUpOrDown
        view.contentTintColor = color
        return view
    }

    private func makeLabel(_ text: String, size: CGFloat, weight: NSFont.Weight, color: NSColor) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = NSFont.systemFont(ofSize: size, weight: weight)
        label.textColor = color
        label.backgroundColor = .clear
        label.isBezeled = false
        label.isEditable = false
        return label
    }

    private func styleTextField(_ field: NSTextField) {
        let currentValue = field.stringValue
        let centeredCell = VerticallyCenteredTextFieldCell(textCell: currentValue)
        centeredCell.wraps = false
        centeredCell.isScrollable = true
        centeredCell.lineBreakMode = .byTruncatingMiddle
        field.cell = centeredCell
        field.stringValue = currentValue
        field.isBezeled = false
        field.isBordered = false
        field.drawsBackground = true
        field.focusRingType = .none
        field.usesSingleLineMode = true
        field.lineBreakMode = .byTruncatingMiddle
        field.cell?.wraps = false
        field.cell?.isScrollable = true
        field.backgroundColor = NSColor(hex: 0xFFFFFF)
        field.textColor = NSColor(hex: 0x111827)
        field.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        field.wantsLayer = true
        field.layer?.backgroundColor = NSColor(hex: 0xFFFFFF).cgColor
        field.layer?.borderColor = NSColor(hex: 0xD1D5DB).cgColor
        field.layer?.borderWidth = 1
        field.layer?.cornerRadius = 8
    }

    private func stylePopup(_ popup: NSPopUpButton) {
        popup.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        popup.contentTintColor = NSColor(hex: 0x111827)
        popup.isBordered = true
        popup.bezelStyle = .rounded
    }

    private func styleButton(_ button: NSButton, fill: NSColor, text: NSColor) {
        button.isBordered = true
        button.bezelStyle = .rounded
        button.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        button.contentTintColor = text
    }

    private func styleRoundButton(_ button: NSButton, fill: NSColor, text: NSColor) {
        button.title = button.image == nil ? button.title : ""
        button.isBordered = false
        button.bezelStyle = .regularSquare
        button.font = NSFont.systemFont(ofSize: 20, weight: .semibold)
        button.contentTintColor = text
        button.wantsLayer = true
        button.layer?.backgroundColor = fill.cgColor
        button.layer?.cornerRadius = button.frame.width / 2
    }

    private func buildStaticAudioMeter() {
        audioMeterView.subviews.forEach { $0.removeFromSuperview() }
        audioMeterBars.removeAll()
        for i in 0..<26 {
            let height: CGFloat = 8
            let bar = NSView(frame: NSRect(x: CGFloat(i) * 7, y: (22 - height) / 2, width: 4, height: height))
            bar.wantsLayer = true
            bar.layer?.cornerRadius = 2
            bar.layer?.backgroundColor = NSColor(hex: 0xD1D5DB).cgColor
            audioMeterView.addSubview(bar)
            audioMeterBars.append(bar)
        }
    }

    private func updateAudioMeter(level: CGFloat) {
        let clamped = max(0, min(1, level))
        lastObservedAudioLevel = clamped
        let activeCount = max(clamped > 0.02 ? 1 : 0, Int((clamped * CGFloat(audioMeterBars.count)).rounded()))

        for (index, bar) in audioMeterBars.enumerated() {
            let wave = abs(sin(CGFloat(index) * 0.7 + clamped * 5.0))
            let height = max(5, min(22, 5 + clamped * 18 * (0.55 + wave * 0.45)))
            bar.frame = NSRect(x: CGFloat(index) * 7, y: (22 - height) / 2, width: 4, height: height)

            if index >= activeCount {
                bar.layer?.backgroundColor = NSColor(hex: 0xD1D5DB).cgColor
            } else if index < 11 {
                bar.layer?.backgroundColor = NSColor(hex: 0x6BCB77).cgColor
            } else if index < 19 {
                bar.layer?.backgroundColor = NSColor(hex: 0xEBCB4B).cgColor
            } else {
                bar.layer?.backgroundColor = NSColor(hex: 0xF59E0B).cgColor
            }
        }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard output === audioLevelOutput else { return }

        let now = CACurrentMediaTime()
        guard now - lastAudioMeterUpdate > 0.045 else { return }
        lastAudioMeterUpdate = now

        let level = audioLevel(from: sampleBuffer)
        DispatchQueue.main.async { [weak self] in
            self?.updateAudioMeter(level: level)
        }
    }

    private func audioLevel(from sampleBuffer: CMSampleBuffer) -> CGFloat {
        guard let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer),
              let streamDescriptionPointer = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription) else {
            return 0
        }

        let streamDescription = streamDescriptionPointer.pointee
        let isFloat = (streamDescription.mFormatFlags & kAudioFormatFlagIsFloat) != 0
        let isSignedInteger = (streamDescription.mFormatFlags & kAudioFormatFlagIsSignedInteger) != 0
        let bitsPerChannel = streamDescription.mBitsPerChannel

        var sizeNeeded = 0
        var blockBuffer: CMBlockBuffer?
        var status = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(
            sampleBuffer,
            bufferListSizeNeededOut: &sizeNeeded,
            bufferListOut: nil,
            bufferListSize: 0,
            blockBufferAllocator: nil,
            blockBufferMemoryAllocator: nil,
            flags: 0,
            blockBufferOut: nil
        )
        guard status == noErr, sizeNeeded > 0 else { return 0 }

        var bufferListData = Data(count: sizeNeeded)
        var sumSquares: Double = 0
        var sampleCount = 0

        bufferListData.withUnsafeMutableBytes { rawBuffer in
            guard let baseAddress = rawBuffer.baseAddress else { return }
            let audioBufferList = baseAddress.assumingMemoryBound(to: AudioBufferList.self)
            status = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(
                sampleBuffer,
                bufferListSizeNeededOut: nil,
                bufferListOut: audioBufferList,
                bufferListSize: sizeNeeded,
                blockBufferAllocator: kCFAllocatorDefault,
                blockBufferMemoryAllocator: kCFAllocatorDefault,
                flags: kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment,
                blockBufferOut: &blockBuffer
            )
            guard status == noErr else { return }

            for buffer in UnsafeMutableAudioBufferListPointer(audioBufferList) {
                guard let data = buffer.mData else { continue }
                let byteCount = Int(buffer.mDataByteSize)

                if isFloat && bitsPerChannel == 32 {
                    let pointer = data.assumingMemoryBound(to: Float.self)
                    let count = byteCount / MemoryLayout<Float>.size
                    for index in 0..<count {
                        let value = Double(pointer[index])
                        sumSquares += value * value
                    }
                    sampleCount += count
                } else if isSignedInteger && bitsPerChannel == 16 {
                    let pointer = data.assumingMemoryBound(to: Int16.self)
                    let count = byteCount / MemoryLayout<Int16>.size
                    for index in 0..<count {
                        let value = Double(pointer[index]) / 32768.0
                        sumSquares += value * value
                    }
                    sampleCount += count
                } else if isSignedInteger && bitsPerChannel == 32 {
                    let pointer = data.assumingMemoryBound(to: Int32.self)
                    let count = byteCount / MemoryLayout<Int32>.size
                    for index in 0..<count {
                        let value = Double(pointer[index]) / 2147483648.0
                        sumSquares += value * value
                    }
                    sampleCount += count
                }
            }
        }

        guard sampleCount > 0 else { return 0 }
        let rms = sqrt(sumSquares / Double(sampleCount))
        return CGFloat(min(1.0, max(0.0, rms * 8.0)))
    }

    @objc private func chooseOutputDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = URL(fileURLWithPath: outputField.stringValue, isDirectory: true)
        if panel.runModal() == .OK, let url = panel.url {
            outputField.stringValue = url.path
            savedPathLabel.stringValue = LF("Save to: %@", url.path)
            persistCurrentSettings()
        }
    }

    @objc private func openOutputFolder() {
        let url = URL(fileURLWithPath: outputField.stringValue, isDirectory: true)
        NSWorkspace.shared.open(url)
    }

    @objc private func showSettings() {
        alert(L("Settings"), L("Choose devices, audio sources, output folder, and orientation in the right panel. Use the quality menu for export quality. Change the interface language in the Language menu."))
    }

    @objc private func showHelp() {
        alert(L("Help"), L("Select a camera and audio source, then click the red button to record. Pause and resume as needed; click Stop to export an MP4. System audio requires a virtual input such as BlackHole or Loopback."))
    }

    @objc private func refreshDevices() {
        guard !isBusy, !isConfiguring else { return }
        refreshButton.isEnabled = false
        setStatus(L("Checking permissions and refreshing devices…"))

        ensurePermissions { [weak self] granted in
            guard let self else { return }
            guard granted else {
                self.refreshButton.isEnabled = true
                self.setStatus(L("Camera or microphone access was denied."))
                self.alert(L("Permission required"), L("Allow LumaRec to access Camera and Microphone in System Settings → Privacy & Security, then refresh devices."))
                return
            }

            self.videoDevices = AVCaptureDevice.devices(for: .video).map {
                CaptureDevice(id: $0.uniqueID, name: $0.localizedName, device: $0)
            }
            self.audioDevices = AVCaptureDevice.devices(for: .audio).map {
                CaptureDevice(id: $0.uniqueID, name: $0.localizedName, device: $0)
            }

            self.cameraPopup.removeAllItems()
            self.builtinPopup.removeAllItems()
            self.micPopup.removeAllItems()

            if self.videoDevices.isEmpty {
                self.cameraPopup.addItem(withTitle: L("No camera found"))
            } else {
                self.videoDevices.forEach { self.cameraPopup.addItem(withTitle: $0.label) }
            }

            if self.audioDevices.isEmpty {
                self.builtinPopup.addItem(withTitle: L("No audio input found"))
                self.micPopup.addItem(withTitle: L("No audio input found"))
            } else {
                self.audioDevices.forEach {
                    self.builtinPopup.addItem(withTitle: $0.label)
                    self.micPopup.addItem(withTitle: $0.label)
                }
                self.restoreSavedDeviceSelections()
            }

            self.refreshButton.isEnabled = true
            self.configureCaptureSession()
        }
    }

    private func ensurePermissions(_ completion: @escaping (Bool) -> Void) {
        let videoStatus = AVCaptureDevice.authorizationStatus(for: .video)
        let audioStatus = AVCaptureDevice.authorizationStatus(for: .audio)

        func requestAudioIfNeeded(_ videoGranted: Bool) {
            guard videoGranted else {
                DispatchQueue.main.async { completion(false) }
                return
            }
            if audioStatus == .authorized {
                DispatchQueue.main.async { completion(true) }
            } else if audioStatus == .notDetermined {
                AVCaptureDevice.requestAccess(for: .audio) { granted in
                    DispatchQueue.main.async { completion(granted) }
                }
            } else {
                DispatchQueue.main.async { completion(false) }
            }
        }

        if videoStatus == .authorized {
            requestAudioIfNeeded(true)
        } else if videoStatus == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { granted in
                requestAudioIfNeeded(granted)
            }
        } else {
            DispatchQueue.main.async { completion(false) }
        }
    }

    @objc private func selectionChanged() {
        guard !isBusy, !isConfiguring else { return }
        persistCurrentSettings()
        configureCaptureSession()
    }

    @objc private func orientationChanged() {
        guard !isBusy else { return }
        resolutionPopup.selectItem(at: orientation.selectedSegment)
        persistCurrentSettings()
        applyPreviewOrientation()
        if orientation.selectedSegment == 1 {
            setStatus(L("Portrait output: 1080 × 1920"))
        } else {
            setStatus(L("Landscape output: 1920 × 1080"))
        }
    }

    @objc private func resolutionPopupChanged() {
        guard !isBusy else { return }
        orientation.selectedSegment = resolutionPopup.indexOfSelectedItem
        orientationChanged()
    }

    private func configureCaptureSession() {
        guard !isConfiguring, !isBusy else { return }
        isSessionConfigured = false
        guard !videoDevices.isEmpty else {
            startButton.isEnabled = false
            setStatus(L("No camera found"))
            return
        }

        let selectedVideo = videoDevices[max(0, cameraPopup.indexOfSelectedItem)].device
        let selectedAudioInputs = currentAudioDevices()
        let selectedCameraName = selectedVideo.localizedName

        isConfiguring = true
        setControlsEnabled(false)
        setStatus(L("Starting camera preview…"))
        sessionQueue.async { [weak self] in
            guard let self else { return }
            var addedAudioInputCount = 0
            self.captureSession.beginConfiguration()
            if self.captureSession.canSetSessionPreset(.hd1920x1080) {
                self.captureSession.sessionPreset = .hd1920x1080
            } else {
                self.captureSession.sessionPreset = .high
            }

            self.captureSession.inputs.forEach { self.captureSession.removeInput($0) }

            do {
                let videoInput = try AVCaptureDeviceInput(device: selectedVideo)
                guard self.captureSession.canAddInput(videoInput) else {
                    throw NSError(domain: "LumaRec", code: 1, userInfo: [NSLocalizedDescriptionKey: L("The selected camera cannot be added to the capture session.")])
                }
                self.captureSession.addInput(videoInput)

                for audioDevice in selectedAudioInputs {
                    let input = try AVCaptureDeviceInput(device: audioDevice)
                    guard self.captureSession.canAddInput(input) else {
                        throw NSError(domain: "LumaRec", code: 2, userInfo: [NSLocalizedDescriptionKey: L("The selected audio source cannot be added. Try Mic mode or a single virtual input.")])
                    }
                    self.captureSession.addInput(input)
                    addedAudioInputCount += 1
                }
            } catch {
                self.captureSession.commitConfiguration()
                self.captureSession.stopRunning()
                DispatchQueue.main.async {
                    self.isConfiguring = false
                    self.setControlsEnabled(true)
                    self.startButton.isEnabled = false
                    self.placeholderLabel.isHidden = false
                    self.previewStatusLabel.stringValue = L("Offline")
                    self.setStatus(LF("Preview failed: %@", error.localizedDescription))
                    self.alert(L("Preview failed"), error.localizedDescription)
                }
                return
            }

            if self.captureSession.outputs.contains(self.movieOutput) == false, self.captureSession.canAddOutput(self.movieOutput) {
                self.captureSession.addOutput(self.movieOutput)
            }
            if self.captureSession.outputs.contains(self.audioLevelOutput) == false, self.captureSession.canAddOutput(self.audioLevelOutput) {
                self.captureSession.addOutput(self.audioLevelOutput)
            }

            self.captureSession.commitConfiguration()

            guard self.movieOutput.connection(with: .video) != nil else {
                self.captureSession.stopRunning()
                DispatchQueue.main.async {
                    self.isConfiguring = false
                    self.setControlsEnabled(true)
                    self.startButton.isEnabled = false
                    self.alert(L("Preview failed"), L("The camera does not support recording with the selected inputs."))
                }
                return
            }

            for connection in self.movieOutput.connections where connection.inputPorts.contains(where: { $0.mediaType == .audio }) {
                connection.isEnabled = true
            }

            if self.captureSession.isRunning == false {
                self.captureSession.startRunning()
            }

            DispatchQueue.main.async {
                self.isConfiguring = false
                self.isSessionConfigured = true
                self.configuredAudioInputCount = addedAudioInputCount
                self.setControlsEnabled(true)
                self.placeholderLabel.isHidden = true
                self.previewStatusLabel.stringValue = L("Live")
                self.previewStatusLabel.textColor = .white
                self.cameraNameLabel.stringValue = selectedCameraName
                if addedAudioInputCount > 0 {
                    self.setStatus(LF("Preview ready. Audio inputs: %d", addedAudioInputCount))
                } else {
                    self.setStatus(L("Preview ready. No audio input is available."))
                }
                self.applyPreviewOrientation()
            }
        }
    }

    private func currentAudioDevices() -> [AVCaptureDevice] {
        guard !audioDevices.isEmpty else { return [] }
        let mode = audioMode.selectedSegment
        let builtin = audioDevices[max(0, builtinPopup.indexOfSelectedItem)].device
        let mic = audioDevices[max(0, micPopup.indexOfSelectedItem)].device

        if mode == 0 {
            return [builtin]
        }
        if mode == 1 {
            return [mic]
        }
        if builtin.uniqueID == mic.uniqueID {
            return [builtin]
        }
        return [builtin, mic]
    }

    private func applyPreviewOrientation() {
        guard let connection = previewView.previewLayer.connection else { return }

        if #available(macOS 14.0, *) {
            let angle: CGFloat = orientation.selectedSegment == 1 ? 90 : 0
            if connection.isVideoRotationAngleSupported(angle) {
                connection.videoRotationAngle = angle
            }
            return
        }

        guard connection.isVideoOrientationSupported else { return }
        if orientation.selectedSegment == 1 {
            connection.videoOrientation = .portrait
        } else {
            connection.videoOrientation = .portrait
        }
    }

    @objc private func startRecording() {
        guard !isBusy, !isConfiguring else { return }
        guard isSessionConfigured else {
            alert(L("Preview is not ready"), L("Click Refresh and wait for the live preview before recording."))
            return
        }
        guard FFmpegLocator.find() != nil else {
            alert(L("FFmpeg not found"), L("Install FFmpeg with brew install ffmpeg, then try again. A custom executable can be set with LUMAREC_FFMPEG."))
            return
        }
        guard configuredAudioInputCount > 0 else {
            alert(L("No audio input"), L("Refresh devices and select a microphone or virtual audio input before recording."))
            return
        }

        let outputDirectory = URL(fileURLWithPath: (outputField.stringValue as NSString).expandingTildeInPath, isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
        } catch {
            alert(L("Output folder is unavailable"), error.localizedDescription)
            return
        }

        let finalURL = outputDirectory.appendingPathComponent(makeOutputFileName())
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("LumaRec-\(UUID().uuidString).mov")

        finalMP4URL = finalURL
        tempMovieURL = tempURL
        recordingAudioInputCount = configuredAudioInputCount
        recordingAudioMode = audioMode.selectedSegment
        exportConfiguration = ExportConfiguration(portrait: orientation.selectedSegment == 1,
                                                  mixAudio: recordingAudioMode == 2,
                                                  quality: ExportQuality(rawValue: modePopup.indexOfSelectedItem) ?? .standard)
        isRecordingInProgress = true
        persistCurrentSettings()

        let selectedAudioNames = currentAudioDevices().map { $0.localizedName }.joined(separator: " + ")

        setControlsEnabled(false)
        pauseButton.isEnabled = true
        stopButton.isEnabled = true
        setRecordingState(active: true)
        if lastObservedAudioLevel < 0.01 {
            setStatus(LF("Recording to %@ · Audio: %@ · Low audio level", finalURL.path, selectedAudioNames))
        } else {
            setStatus(LF("Recording to %@ · Audio: %@", finalURL.path, selectedAudioNames))
        }
        savedPathLabel.stringValue = LF("Recording: %@", finalURL.lastPathComponent)
        recordingStartedAt = Date()
        pauseStartedAt = nil
        accumulatedPausedDuration = 0
        isRecordingPaused = false
        startRecordTimer()

        movieOutput.startRecording(to: tempURL, recordingDelegate: self)
    }

    @objc private func togglePauseRecording() {
        guard movieOutput.isRecording else {
            setStatus(L("No recording is in progress."))
            return
        }

        if isRecordingPaused {
            movieOutput.resumeRecording()
            if let pausedAt = pauseStartedAt {
                accumulatedPausedDuration += Date().timeIntervalSince(pausedAt)
            }
            pauseStartedAt = nil
            isRecordingPaused = false
            pauseButton.image = makeSymbolImage("pause.fill", color: NSColor(hex: 0x4B5563))
            pauseButton.toolTip = L("Pause recording")
            recordStateLabel.stringValue = L("Recording")
            setStatus(L("Recording resumed."))
            startRecordTimer()
        } else {
            movieOutput.pauseRecording()
            pauseStartedAt = Date()
            isRecordingPaused = true
            pauseButton.image = makeSymbolImage("play.fill", color: NSColor(hex: 0x4B5563))
            pauseButton.toolTip = L("Resume recording")
            recordStateLabel.stringValue = L("Paused")
            setStatus(L("Recording paused."))
            recordTimer?.invalidate()
            recordTimer = nil
        }
    }

    @objc private func stopRecording() {
        guard movieOutput.isRecording else {
            setStatus(L("No recording is in progress."))
            return
        }
        setStatus(L("Stopping recording…"))
        pauseButton.isEnabled = false
        stopButton.isEnabled = false
        movieOutput.stopRecording()
    }

    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        DispatchQueue.main.async { [weak self] in
            self?.finishRecording(at: outputFileURL, error: error)
        }
    }

    private func finishRecording(at outputFileURL: URL, error: Error?) {
        isRecordingInProgress = false
        stopRecordTimer()

        let successfullyFinished = (error as NSError?)?.userInfo[AVErrorRecordingSuccessfullyFinishedKey] as? Bool ?? false
        if let error, !successfullyFinished {
            setRecordingState(active: false)
            setControlsEnabled(true)
            pauseButton.isEnabled = false
            stopButton.isEnabled = false
            isRecordingPaused = false
            pauseStartedAt = nil
            setStatus(LF("Recording failed: %@", error.localizedDescription))
            alert(L("Recording failed"), error.localizedDescription)
            return
        }

        guard let finalURL = finalMP4URL else {
            setRecordingState(active: false)
            setControlsEnabled(true)
            pauseButton.isEnabled = false
            stopButton.isEnabled = false
            isRecordingPaused = false
            pauseStartedAt = nil
            setStatus(L("Recording stopped, but the output path is missing."))
            return
        }

        let audioTrackCount = AVAsset(url: outputFileURL).tracks(withMediaType: .audio).count
        recordingAudioInputCount = audioTrackCount
        exportConfiguration.audioTrackCount = audioTrackCount
        guard audioTrackCount > 0 else {
            setRecordingState(active: false)
            setControlsEnabled(true)
            pauseButton.isEnabled = false
            stopButton.isEnabled = false
            isRecordingPaused = false
            pauseStartedAt = nil
            setStatus(LF("No audio track. Temporary recording: %@", outputFileURL.path))
            alert(L("No audio was recorded"), L("The recording has no audio track. Check microphone permissions and select an audio source, then try again. The temporary MOV has been kept."))
            return
        }

        setStatus(LF("Exporting MP4 · Audio tracks: %d", audioTrackCount))
        isExporting = true
        recordStateLabel.stringValue = L("Exporting…")
        pauseButton.isEnabled = false
        stopButton.isEnabled = false
        convertMovieToMP4(tempURL: outputFileURL, finalURL: finalURL)
    }

    private func convertMovieToMP4(tempURL: URL, finalURL: URL) {
        guard let ffmpegURL = FFmpegLocator.find() else {
            isExporting = false
            setRecordingState(active: false)
            setControlsEnabled(true)
            setStatus(LF("Export failed. Temporary recording kept at: %@", tempURL.path))
            alert(L("FFmpeg not found"), L("Install FFmpeg with brew install ffmpeg, then try again. A custom executable can be set with LUMAREC_FFMPEG."))
            return
        }
        let process = Process()
        process.executableURL = ffmpegURL
        process.arguments = exportConfiguration.arguments(input: tempURL, output: finalURL)

        // A file avoids filling a pipe and blocking FFmpeg on a long error message.
        let logURL = FileManager.default.temporaryDirectory.appendingPathComponent("LumaRec-\(UUID().uuidString).log")
        FileManager.default.createFile(atPath: logURL.path, contents: nil)
        guard let logHandle = try? FileHandle(forWritingTo: logURL) else {
            isExporting = false
            setRecordingState(active: false)
            setControlsEnabled(true)
            setStatus(LF("Export failed. Temporary recording kept at: %@", tempURL.path))
            return
        }
        process.standardOutput = FileHandle.nullDevice
        process.standardError = logHandle
        exportProcess = process

        process.terminationHandler = { [weak self] process in
            try? logHandle.close()
            let errorText = (try? String(contentsOf: logURL, encoding: .utf8)) ?? ""
            try? FileManager.default.removeItem(at: logURL)
            DispatchQueue.main.async {
                guard let self else { return }
                self.isExporting = false
                self.exportProcess = nil
                self.setRecordingState(active: false)
                self.setControlsEnabled(true)
                self.pauseButton.isEnabled = false
                self.stopButton.isEnabled = false
                self.isRecordingPaused = false
                self.pauseStartedAt = nil

                if ExportValidation.succeeded(output: finalURL, exitCode: process.terminationStatus, errorLog: errorText) {
                    try? FileManager.default.removeItem(at: tempURL)
                    self.setStatus(LF("Saved: %@", finalURL.path))
                    self.savedPathLabel.stringValue = LF("Saved: %@", finalURL.path)
                    self.notifyRecordingFinished(finalURL)
                } else {
                    self.setStatus(LF("Export failed. Temporary recording kept at: %@", tempURL.path))
                    self.alert(L("MP4 export failed"), errorText.isEmpty ? LF("FFmpeg exit code: %d", process.terminationStatus) : errorText)
                }
            }
        }

        do {
            try process.run()
        } catch {
            try? logHandle.close()
            try? FileManager.default.removeItem(at: logURL)
            isExporting = false
            exportProcess = nil
            setRecordingState(active: false)
            setControlsEnabled(true)
            pauseButton.isEnabled = false
            stopButton.isEnabled = false
            setStatus(LF("Export failed: %@", error.localizedDescription))
            alert(L("MP4 export failed"), error.localizedDescription)
        }
    }

    private func notifyRecordingFinished(_ fileURL: URL) {
        let alert = NSAlert()
        alert.messageText = L("Recording complete")
        alert.informativeText = LF("File: %@\nFolder: %@", fileURL.lastPathComponent, fileURL.deletingLastPathComponent().path)
        alert.addButton(withTitle: L("Open file"))
        alert.addButton(withTitle: L("Show in Finder"))
        alert.addButton(withTitle: L("OK"))

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            NSWorkspace.shared.open(fileURL)
        } else if response == .alertSecondButtonReturn {
            NSWorkspace.shared.activateFileViewerSelecting([fileURL])
        }
    }

    private func makeOutputFileName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let direction = orientation.selectedSegment == 1 ? "portrait" : "landscape"
        return "camera_\(formatter.string(from: Date()))_\(direction)_\(UUID().uuidString.prefix(8)).mp4"
    }

    private func setControlsEnabled(_ enabled: Bool) {
        refreshButton.isEnabled = enabled
        startButton.isEnabled = enabled
        cameraPopup.isEnabled = enabled
        builtinPopup.isEnabled = enabled
        micPopup.isEnabled = enabled
        audioMode.isEnabled = enabled
        orientation.isEnabled = enabled
        outputField.isEnabled = enabled
        chooseButton.isEnabled = enabled
        modePopup.isEnabled = enabled
        resolutionPopup.isEnabled = enabled
    }

    private func savedSegment(_ key: String, defaultValue: Int, upperBound: Int) -> Int {
        if ProcessInfo.processInfo.arguments.contains("--screenshot") { return defaultValue }
        guard UserDefaults.standard.object(forKey: key) != nil else { return defaultValue }
        return min(upperBound, max(0, UserDefaults.standard.integer(forKey: key)))
    }

    private func restoreSavedDeviceSelections() {
        selectSavedDevice(in: cameraPopup, devices: videoDevices, idKey: DefaultsKey.cameraDeviceID, nameKey: DefaultsKey.cameraDeviceName, fallbackIndex: 0)
        selectSavedDevice(in: builtinPopup, devices: audioDevices, idKey: DefaultsKey.builtinAudioDeviceID, nameKey: DefaultsKey.builtinAudioDeviceName, fallbackIndex: preferredBuiltinAudioIndex())
        selectSavedDevice(in: micPopup, devices: audioDevices, idKey: DefaultsKey.micAudioDeviceID, nameKey: DefaultsKey.micAudioDeviceName, fallbackIndex: preferredMicrophoneIndex())
        persistCurrentSettings()
    }

    private func selectSavedDevice(in popup: NSPopUpButton, devices: [CaptureDevice], idKey: String, nameKey: String, fallbackIndex: Int) {
        guard devices.isEmpty == false else { return }
        let defaults = UserDefaults.standard

        if let savedID = defaults.string(forKey: idKey),
           let index = devices.firstIndex(where: { $0.id == savedID }) {
            popup.selectItem(at: index)
            return
        }

        if let savedName = defaults.string(forKey: nameKey),
           let index = devices.firstIndex(where: { $0.name == savedName }) {
            popup.selectItem(at: index)
            return
        }

        popup.selectItem(at: min(max(0, fallbackIndex), devices.count - 1))
    }

    private func preferredMicrophoneIndex() -> Int {
        guard audioDevices.isEmpty == false else { return 0 }

        if let defaultAudio = AVCaptureDevice.default(for: .audio),
           let index = audioDevices.firstIndex(where: { $0.id == defaultAudio.uniqueID }) {
            return index
        }

        let avoidWords = ["virtual", "oray", "blackhole", "loopback", "soundflower", "iphone", "ipad"]
        let localMicWords = ["macbook", "built-in", "内建", "内置", "麦克风", "microphone"]

        if let index = audioDevices.firstIndex(where: { device in
            let lower = device.name.lowercased()
            return localMicWords.contains(where: { lower.contains($0) }) && avoidWords.contains(where: { lower.contains($0) }) == false
        }) {
            return index
        }

        if let index = audioDevices.firstIndex(where: { device in
            let lower = device.name.lowercased()
            return avoidWords.contains(where: { lower.contains($0) }) == false
        }) {
            return index
        }

        return 0
    }

    private func preferredBuiltinAudioIndex() -> Int {
        guard audioDevices.isEmpty == false else { return 0 }
        let systemAudioWords = ["oray", "blackhole", "loopback", "soundflower", "virtual"]

        if let index = audioDevices.firstIndex(where: { device in
            let lower = device.name.lowercased()
            return systemAudioWords.contains(where: { lower.contains($0) })
        }) {
            return index
        }

        return preferredMicrophoneIndex()
    }

    private func persistCurrentSettings() {
        guard !ProcessInfo.processInfo.arguments.contains("--screenshot") else { return }
        let defaults = UserDefaults.standard
        defaults.set(outputField.stringValue, forKey: DefaultsKey.outputDirectory)
        defaults.set(audioMode.selectedSegment, forKey: DefaultsKey.audioMode)
        defaults.set(orientation.selectedSegment, forKey: DefaultsKey.orientation)
        defaults.set(modePopup.indexOfSelectedItem, forKey: DefaultsKey.exportQuality)

        if videoDevices.indices.contains(cameraPopup.indexOfSelectedItem) {
            let device = videoDevices[cameraPopup.indexOfSelectedItem]
            defaults.set(device.id, forKey: DefaultsKey.cameraDeviceID)
            defaults.set(device.name, forKey: DefaultsKey.cameraDeviceName)
        }

        if audioDevices.indices.contains(builtinPopup.indexOfSelectedItem) {
            let device = audioDevices[builtinPopup.indexOfSelectedItem]
            defaults.set(device.id, forKey: DefaultsKey.builtinAudioDeviceID)
            defaults.set(device.name, forKey: DefaultsKey.builtinAudioDeviceName)
        }

        if audioDevices.indices.contains(micPopup.indexOfSelectedItem) {
            let device = audioDevices[micPopup.indexOfSelectedItem]
            defaults.set(device.id, forKey: DefaultsKey.micAudioDeviceID)
            defaults.set(device.name, forKey: DefaultsKey.micAudioDeviceName)
        }

        defaults.synchronize()
    }

    private func setRecordingState(active: Bool) {
        recordStateLabel.stringValue = active ? L("Recording") : L("Ready to record")
        recordDot.layer?.backgroundColor = active ? NSColor(hex: 0xEF4444).cgColor : NSColor(hex: 0x22C55E).cgColor
        timerLabel.stringValue = active ? "00:00" : "00:00"
        startButton.layer?.backgroundColor = (active ? NSColor(hex: 0xE5E7EB) : NSColor(hex: 0xFF3B30)).cgColor
        if active == false {
            pauseButton.isEnabled = false
            stopButton.isEnabled = false
            pauseButton.image = makeSymbolImage("pause.fill", color: NSColor(hex: 0x4B5563))
            pauseButton.toolTip = L("Pause recording")
        }
    }

    private func startRecordTimer() {
        recordTimer?.invalidate()
        recordTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(updateRecordTimer), userInfo: nil, repeats: true)
        updateRecordTimer()
    }

    private func stopRecordTimer() {
        recordTimer?.invalidate()
        recordTimer = nil
    }

    @objc private func updateRecordTimer() {
        guard let started = recordingStartedAt else { return }
        let currentPaused = pauseStartedAt.map { Date().timeIntervalSince($0) } ?? 0
        let elapsed = max(0, Int(Date().timeIntervalSince(started) - accumulatedPausedDuration - currentPaused))
        timerLabel.stringValue = String(format: "%02d:%02d", elapsed / 60, elapsed % 60)
    }

    private func setStatus(_ text: String) {
        statusLabel.stringValue = text
    }

    private func alert(_ title: String, _ message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: L("OK"))
        alert.runModal()
    }

    @objc private func qualityChanged() {
        persistCurrentSettings()
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        guard !isBusy else {
            showBusyAlert()
            return false
        }
        return true
    }

    func windowWillClose(_ notification: Notification) {
        persistCurrentSettings()
        if movieOutput.isRecording {
            movieOutput.stopRecording()
        }
        sessionQueue.async { [weak self] in
            self?.captureSession.stopRunning()
        }
    }
}
