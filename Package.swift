// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "simian",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .executable(
            name: "simian",
            targets: ["simian"]),
    ],
    dependencies: [
        .package(url: "https://github.com/jnewc/Cosmic", .upToNextMajor(from: "7.3.1")),
        .package(url: "https://github.com/crossroadlabs/Regex.git", .upToNextMajor(from: "1.2.0")),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "simian",
            dependencies: ["Cosmic", "Regex"]),
        .testTarget(
            name: "simianTests",
            dependencies: ["simian"]),
    ]
)
