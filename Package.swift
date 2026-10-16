// swift-tools-version: 6.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PinMAMEKit",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "PinMAMEKit",
            targets: ["PinMAMEKit"]
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "PinMAMEKit",
            dependencies: [
                "libpinmame"
            ],
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency"),
            ],
        ),
        .testTarget(
            name: "PinMAMEKitTests",
            dependencies: ["PinMAMEKit"],
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency"),
            ],
        ),
        .binaryTarget(name: "libpinmame", url: "https://github.com/Samasaur1/pinmame/releases/download/cc0e25c10f9d0ffede5b87da13f43639bc06f86e-patched/libpinmame.artifactbundle.zip", checksum: "de6a7111059ba660d976b9169826234ad94927210f2ec164505d25f480c45273")
    ]
)
