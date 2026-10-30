// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LaunchboardKitV1",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "LaunchboardKit", targets: ["LaunchboardKit"]),
    ],
    targets: [
        .target(
            name: "LaunchboardKit",
            path: "Sources/LaunchboardKit",
            linkerSettings: [.linkedFramework("Carbon")]
        ),
        .testTarget(
            name: "LaunchboardTests",
            dependencies: ["LaunchboardKit"],
            path: "Tests/LaunchboardTests"
        ),
    ]
)
