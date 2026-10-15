import Cocoa
import LumaRecCore

let arguments = ProcessInfo.processInfo.arguments
if arguments.contains("--device-status") {
    print(CaptureDevices.status())
    exit(0)
}
if let index = arguments.firstIndex(of: "--inspect-recording"), arguments.indices.contains(index + 1) {
    let url = URL(fileURLWithPath: arguments[index + 1])
    Task {
        do { print(try await RecordingInspection.inspect(url, expectedDuration: 4)); exit(0) }
        catch { fputs("\(error)\n", stderr); exit(1) }
    }
    dispatchMain()
}
if let index = arguments.firstIndex(of: "--verify-export"), arguments.indices.contains(index + 1) {
    let directory = URL(fileURLWithPath: arguments[index + 1], isDirectory: true)
    Task {
        do {
            for line in try await MediaQualification.run(in: directory) { print(line) }
            print("SYNTHETIC ONLY: no camera or microphone was accessed.")
            exit(0)
        } catch {
            fputs("Native export verification failed: \(error.localizedDescription)\n", stderr)
            exit(1)
        }
    }
    dispatchMain()
}
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
