// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "ArcNext",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .executable(name: "ArcNext", targets: ["ArcNextApp"]),
        .library(name: "ArcNextCore", targets: ["ArcNextCore"]),
        .library(name: "ArcNextUI", targets: ["ArcNextUI"]),
        .library(name: "ArcNextBrowser", targets: ["ArcNextBrowser"]),
    ],
    dependencies: [
        .package(url: "https://github.com/migueldeicaza/SwiftTerm.git", from: "1.2.0"),
    ],
    targets: [
        .executableTarget(
            name: "ArcNextApp",
            dependencies: [
                "ArcNextCore",
                "ArcNextUI",
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]),
        .target(
            name: "ArcNextCore",
            dependencies: [
                .product(name: "SwiftTerm", package: "SwiftTerm"),
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]),
        .target(
            name: "ArcNextUI",
            dependencies: [
                "ArcNextCore",
                .product(name: "SwiftTerm", package: "SwiftTerm"),
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]),
        .target(
            name: "ArcNextBrowser",
            dependencies: [],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]),
        .testTarget(
            name: "ArcNextCoreTests",
            dependencies: [
                "ArcNextCore",
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]),
    ])
