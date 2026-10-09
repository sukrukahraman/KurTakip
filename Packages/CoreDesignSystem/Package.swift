// swift-tools-version: 6.2
import PackageDescription

let strict: [SwiftSetting] = [.treatAllWarnings(as: .error)]

let package = Package(
    name: "CoreDesignSystem",
    platforms: [.iOS(.v17)],
    products: [.library(name: "CoreDesignSystem", targets: ["CoreDesignSystem"])],
    dependencies: [
        .package(url: "https://github.com/nalexn/ViewInspector", exact: "0.10.5"),
    ],
    targets: [
        .target(name: "CoreDesignSystem", swiftSettings: strict),
        .testTarget(
            name: "CoreDesignSystemTests",
            dependencies: ["CoreDesignSystem", .product(name: "ViewInspector", package: "ViewInspector")],
            swiftSettings: strict
        ),
    ]
)
