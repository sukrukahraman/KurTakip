// swift-tools-version: 6.2
import PackageDescription

let strict: [SwiftSetting] = [.treatAllWarnings(as: .error)]

let package = Package(
    name: "CoreNetwork",
    platforms: [.iOS(.v17)],
    products: [.library(name: "CoreNetwork", targets: ["CoreNetwork"])],
    dependencies: [
        .package(path: "../CoreCommon"),
    ],
    targets: [
        .target(name: "CoreNetwork", dependencies: ["CoreCommon"], swiftSettings: strict),
        .testTarget(name: "CoreNetworkTests", dependencies: ["CoreNetwork"], swiftSettings: strict),
    ]
)
