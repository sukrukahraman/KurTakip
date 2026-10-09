// swift-tools-version: 6.2
import PackageDescription

let strict: [SwiftSetting] = [.treatAllWarnings(as: .error)]

let package = Package(
    name: "CoreUI",
    platforms: [.iOS(.v17)],
    products: [.library(name: "CoreUI", targets: ["CoreUI"])],
    dependencies: [
        .package(path: "../CoreCommon"),
        .package(path: "../CoreDesignSystem"),
        .package(path: "../CoreLocalization"),
        .package(path: "../CoreTesting"),
        .package(url: "https://github.com/nalexn/ViewInspector", exact: "0.10.5"),
    ],
    targets: [
        .target(
            name: "CoreUI",
            dependencies: ["CoreCommon", "CoreDesignSystem", "CoreLocalization"],
            swiftSettings: strict
        ),
        .testTarget(
            name: "CoreUITests",
            dependencies: [
                "CoreUI", "CoreTesting",
                .product(name: "ViewInspector", package: "ViewInspector"),
            ],
            swiftSettings: strict
        ),
    ]
)
