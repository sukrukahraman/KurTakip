// swift-tools-version: 6.2
import PackageDescription

let strict: [SwiftSetting] = [.treatAllWarnings(as: .error)]

let package = Package(
    name: "CoreDatabase",
    platforms: [.iOS(.v17)],
    products: [.library(name: "CoreDatabase", targets: ["CoreDatabase"])],
    dependencies: [
        .package(path: "../CoreModel"),
        // <skill:package-deps>
    ],
    targets: [
        .target(
            name: "CoreDatabase",
            dependencies: [
                "CoreModel",
                // <skill:target-deps>
            ],
            swiftSettings: strict
        ),
        .testTarget(
            name: "CoreDatabaseTests",
            dependencies: [
                "CoreDatabase",
                // <skill:test-deps>
            ],
            swiftSettings: strict
        ),
    ]
)
