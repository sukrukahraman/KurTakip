// swift-tools-version: 6.2
import PackageDescription

let strict: [SwiftSetting] = [.treatAllWarnings(as: .error)]

let package = Package(
    name: "CoreLocalization",
    defaultLocalization: "tr",
    platforms: [.iOS(.v17)],
    products: [.library(name: "CoreLocalization", targets: ["CoreLocalization"])],
    targets: [
        .target(name: "CoreLocalization", resources: [.process("Resources")], swiftSettings: strict),
        .testTarget(name: "CoreLocalizationTests", dependencies: ["CoreLocalization"], swiftSettings: strict),
    ]
)
