// swift-tools-version: 5.9
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
