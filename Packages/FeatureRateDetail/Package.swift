// swift-tools-version: 6.2
import PackageDescription

let strict: [SwiftSetting] = [.treatAllWarnings(as: .error)]

let package = Package(
    name: "FeatureRateDetail",
    platforms: [.iOS(.v17)],
    products: [.library(name: "FeatureRateDetail", targets: ["FeatureRateDetail"])],
    dependencies: [
        .package(path: "../CoreCommon"),
        .package(path: "../CoreDesignSystem"),
        .package(path: "../CoreLocalization"),
        .package(path: "../CoreUI"),
        .package(path: "../CoreTesting"),
        .package(url: "https://github.com/nalexn/ViewInspector", exact: "0.10.5"),
        .package(path: "../CoreModel"),
        .package(path: "../CoreRepository"),
        // <skill:package-deps>
    ],
    targets: [
        .target(
            name: "FeatureRateDetail",
            dependencies: [
                "CoreCommon",
                "CoreDesignSystem",
                "CoreLocalization",
                "CoreUI",
                "CoreModel",
                "CoreRepository",
                // <skill:target-deps>
            ],
            swiftSettings: strict
        ),
        .testTarget(
            name: "FeatureRateDetailTests",
            dependencies: [
                "FeatureRateDetail",
                "CoreTesting",
                .product(name: "ViewInspector", package: "ViewInspector"),
                // <skill:test-deps>
            ],
            swiftSettings: strict
        ),
    ]
)
