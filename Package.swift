// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SkillsManagerApp",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "SkillsManagerApp",
            targets: ["SkillsManagerApp"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "SkillsManagerApp",
            dependencies: [],
            path: "Sources/SkillsManagerApp",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "SkillsManagerAppTests",
            dependencies: ["SkillsManagerApp"],
            path: "Tests/SkillsManagerAppTests"
        )
    ]
)
