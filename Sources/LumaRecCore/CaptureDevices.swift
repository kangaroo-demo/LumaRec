import AVFoundation

public enum CaptureDevices {
    public static var cameras: [AVCaptureDevice] {
        let types: [AVCaptureDevice.DeviceType]
        if #available(macOS 14.0, *) { types = [.builtInWideAngleCamera, .external, .continuityCamera] }
        else { types = [.builtInWideAngleCamera, .externalUnknown] }
        return AVCaptureDevice.DiscoverySession(deviceTypes: types, mediaType: .video, position: .unspecified).devices
    }

    public static var microphones: [AVCaptureDevice] {
        let types: [AVCaptureDevice.DeviceType]
        if #available(macOS 14.0, *) { types = [.microphone, .external] }
        else { types = [.builtInMicrophone, .externalUnknown] }
        return AVCaptureDevice.DiscoverySession(deviceTypes: types, mediaType: .audio, position: .unspecified).devices
    }

    public static func status() -> String {
        func name(_ value: AVAuthorizationStatus) -> String {
            switch value {
            case .authorized: return "authorized"
            case .notDetermined: return "notDetermined"
            case .denied: return "denied"
            case .restricted: return "restricted"
            @unknown default: return "unknown"
            }
        }
        return "Camera permission: \(name(AVCaptureDevice.authorizationStatus(for: .video)))\nMicrophone permission: \(name(AVCaptureDevice.authorizationStatus(for: .audio)))\nCamera devices: \(cameras.count)\nAudio input devices: \(microphones.count)\nNo capture was started."
    }
}
