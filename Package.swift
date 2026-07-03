// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "VoiceTranslation",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    products: [
        .library(name: "VoiceRepliesCore", targets: ["VoiceRepliesCore"]),
        .executable(name: "VoiceTranslation", targets: ["VoiceRepliesMac"])
    ],
    targets: [
        .target(
            name: "VoiceRepliesCore",
            path: "Sources/VoiceRepliesCore"
        ),
        .executableTarget(
            name: "VoiceRepliesMac",
            dependencies: ["VoiceRepliesCore"],
            path: "Sources/VoiceRepliesMac"
        ),
        .testTarget(
            name: "VoiceTranslationTests",
            dependencies: ["VoiceRepliesCore"],
            path: "Tests/VoiceTranslationTests"
        )
    ]
)
