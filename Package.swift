// swift-tools-version:5.3

import PackageDescription

struct ProjectSettings {
    static let marketingVersion: String = "7.2.0"
}

let package = Package(
    name: "SRGMediaPlayer",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v12),
        .tvOS(.v12)
    ],
    products: [
        .library(
            name: "SRGMediaPlayer",
            targets: ["SRGMediaPlayer"]
        )
    ],
    dependencies: [
        .package(name: "libextobjc", url: "https://github.com/SRGSSR/libextobjc.git", .exact("0.6.0-srg4")),
        .package(name: "MAKVONotificationCenter", url: "https://github.com/SRGSSR/MAKVONotificationCenter.git", .exact("1.0.0-srg6")),
        .package(name: "SRGLogger", url: "https://github.com/SRGSSR/srglogger-apple.git", .upToNextMinor(from: "3.1.0"))
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
                .define("NS_BLOCK_ASSERTIONS", to: "1", .when(configuration: .release))
            ]
        ),
        .testTarget(
            name: "SRGMediaPlayerTests",
            dependencies: ["SRGMediaPlayer"],
            cSettings: [
                .headerSearchPath("Private")
            ]
        )
    ]
)
