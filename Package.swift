// swift-tools-version:5.3

import PackageDescription

struct ProjectSettings {
    static let marketingVersion: String = "5.0.4"
}

let package = Package(
    name: "SRGMediaPlayer",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v9),
        .tvOS(.v12),
        .watchOS(.v5)
    ],
    products: [
        .library(
            name: "SRGMediaPlayer",
            targets: ["SRGMediaPlayer"]
        )
    ],
    dependencies: [
        .package(name: "libextobjc", url: "https://github.com/SRGSSR/libextobjc.git", .branch("feature/spm-support")),
        .package(name: "MAKVONotificationCenter", url: "https://github.com/SRGSSR/MAKVONotificationCenter.git", .branch("feature/spm-support")),
        .package(name: "SRGLogger", url: "https://github.com/SRGSSR/srglogger-apple.git", .branch("feature/spm-support"))
    ],
    targets: [
        .target(
            name: "SRGMediaPlayer",
            dependencies: ["libextobjc", "MAKVONotificationCenter", "SRGLogger"],
            resources: [
                .process("Resources")
            ],
            cSettings: [
                .define("MARKETING_VERSION", to: "\"\(ProjectSettings.marketingVersion)\""),
            ]
        ),
        .testTarget(
            name: "SRGMediaPlayer-tests",
            dependencies: ["SRGMediaPlayer"]
        )
    ]
)
