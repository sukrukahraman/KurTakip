// swift-tools-version: 6.2
import PackageDescription

let strict: [SwiftSetting] = [.treatAllWarnings(as: .error)]

let package = Package(
    name: "CoreModel",
    platforms: [.iOS(.v17)],
    products: [.library(name: "CoreModel", targets: ["CoreModel"])],
    targets: [
        .target(name: "CoreModel", swiftSettings: strict),
    ]
)
