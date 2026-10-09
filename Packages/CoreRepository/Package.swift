// swift-tools-version: 6.2
import PackageDescription

let strict: [SwiftSetting] = [.treatAllWarnings(as: .error)]

let package = Package(
    name: "CoreRepository",
    platforms: [.iOS(.v17)],
    products: [.library(name: "CoreRepository", targets: ["CoreRepository"])],
    dependencies: [
        .package(path: "../CoreCommon"),
        .package(path: "../CoreModel"),
        .package(path: "../CoreNetwork"),
        .package(path: "../CoreDatabase"),
        // <skill:package-deps>
    ],
    targets: [
        .target(
            name: "CoreRepository",
            dependencies: [
                "CoreCommon",
                "CoreModel",
                "CoreNetwork",
                "CoreDatabase",
                // <skill:target-deps>
            ],
            swiftSettings: strict
        ),
        .testTarget(
            name: "CoreRepositoryTests",
            dependencies: [
                "CoreRepository",
                // <skill:test-deps>
            ],
            swiftSettings: strict
        ),
    ]
)
