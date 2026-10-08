// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LumaRec",
    defaultLocalization: "en",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "LumaRec", targets: ["LumaRec"]),
        .executable(name: "LumaRecChecks", targets: ["LumaRecChecks"])
    ],
    targets: [
        .target(name: "LumaRecCore", resources: [.process("Resources")]),
        .executableTarget(name: "LumaRec", dependencies: ["LumaRecCore"]),
        .executableTarget(name: "LumaRecChecks", dependencies: ["LumaRecCore"], path: "Tests/LumaRecChecks")
    ]
)
