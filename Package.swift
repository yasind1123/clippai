// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Clippai",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "ClippaiApp", targets: ["ClippaiApp"])
    ],
    targets: [
        .executableTarget(
            name: "ClippaiApp",
            dependencies: [],
            path: "Clippai",
            exclude: [
                "Info.plist",
                "Clippai.Debug.entitlements",
                "Clippai.Release.entitlements",
                "Assets.xcassets"
            ]
        )
    ]
)
