// swift-tools-version: 5.9
// DecisaSDK — native iOS attribution SDK (Swift Package Manager) for web2app,
// funnel2app, and paid-ads conversion tracking via Decisa's public pixel ingest.
import PackageDescription

let package = Package(
    name: "DecisaSDK",
    platforms: [.iOS(.v13), .macOS(.v11)],
    products: [
        .library(name: "DecisaSDK", targets: ["DecisaSDK"]),
    ],
    targets: [
        .target(
            name: "DecisaSDK",
            linkerSettings: [
                .linkedFramework("AdServices", .when(platforms: [.iOS])),
            ]
        ),
        .testTarget(
            name: "DecisaSDKTests",
            dependencies: ["DecisaSDK"]
        ),
    ]
)
