// swift-tools-version: 6.2
import PackageDescription

let strict: [SwiftSetting] = [.treatAllWarnings(as: .error)]

let package = Package(
    name: "FeatureRatesList",
    platforms: [.iOS(.v17)],
    products: [.library(name: "FeatureRatesList", targets: ["FeatureRatesList"])],
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
            name: "FeatureRatesList",
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
            name: "FeatureRatesListTests",
            dependencies: [
                "FeatureRatesList",
                "CoreTesting",
                .product(name: "ViewInspector", package: "ViewInspector"),
                // <skill:test-deps>
            ],
            swiftSettings: strict
        ),
    ]
)
