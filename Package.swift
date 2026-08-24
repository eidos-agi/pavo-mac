// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PavoMac",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "PavoMac", targets: ["PavoMac"]),
        .executable(name: "PavoDesktop", targets: ["PavoDesktop"]),
    ],
    targets: [
        .target(name: "PavoMac", path: "Sources/PavoMac"),
        .executableTarget(name: "PavoDesktop", dependencies: ["PavoMac"], path: "Sources/PavoDesktop"),
    ]
)
