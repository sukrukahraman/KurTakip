// swift-tools-version: 6.2
import PackageDescription

let strict: [SwiftSetting] = [.treatAllWarnings(as: .error)]

let package = Package(
    name: "CoreCommon",
    platforms: [.iOS(.v17)],
    products: [.library(name: "CoreCommon", targets: ["CoreCommon"])],
    targets: [
        .target(name: "CoreCommon", swiftSettings: strict),
        .testTarget(name: "CoreCommonTests", dependencies: ["CoreCommon"], swiftSettings: strict),
    ]
)
