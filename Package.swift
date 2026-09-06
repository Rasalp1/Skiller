// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Skiller",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "Skiller",
            targets: ["Skiller"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "Skiller",
            dependencies: [],
            path: "Sources/Skiller"
        ),
        .testTarget(
            name: "SkillerTests",
            dependencies: ["Skiller"],
            path: "Tests/SkillerTests"
        )
    ]
)
