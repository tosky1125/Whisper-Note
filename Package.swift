// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WhisperNote",
    platforms: [
        .iOS(.v16)
    ],
    dependencies: [
        .package(url: "https://github.com/argmaxinc/WhisperKit", from: "0.3.0")
    ],
    targets: [
        .target(
            name: "WhisperNote",
            dependencies: ["WhisperKit"]
        )
    ]
)