// swift-tools-version: 6.2
import PackageDescription

let strict: [SwiftSetting] = [.treatAllWarnings(as: .error)]

let package = Package(
    name: "CoreTesting",
    platforms: [.iOS(.v17)],
    products: [.library(name: "CoreTesting", targets: ["CoreTesting"])],
    dependencies: [
        .package(path: "../CoreCommon"),
        .package(path: "../CoreLocalization"),
        // <skill:package-deps>
    ],
    targets: [
        .target(
            name: "CoreTesting",
            dependencies: [
                "CoreCommon",
                "CoreLocalization",
                // <skill:target-deps>
            ],
            swiftSettings: strict
        ),
        .testTarget(
            name: "CoreTestingTests",
            dependencies: [
                "CoreTesting",
                // <skill:test-deps>
            ],
            swiftSettings: strict
        ),
    ]
)
