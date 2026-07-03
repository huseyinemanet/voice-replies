// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "VoiceTranslation",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "VoiceTranslation", targets: ["VoiceTranslation"])
    ],
    targets: [
        .executableTarget(
            name: "VoiceTranslation",
            path: "Sources/VoiceTranslation"
        )
    ]
)
