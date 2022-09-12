// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "Blomst",
    platforms: [.macOS(.v13)],
    products: [
        .library(
            name: "Blomst",
            targets: ["Blomst"]),
    ],
    dependencies: [
        .package(url: "https://github.com/sajjon/BytePattern", branch: "main")
    ],
    targets: [
        .binaryTarget(
            name: "BLST",
            path: "BLST.xcframework"
        ),
        .target(
            name: "Blomst",
            dependencies: ["BLST"]),
        .testTarget(
            name: "BlomstTests",
            dependencies: [
                "Blomst",
                .product(name: "XCTAssertBytesEqual", package: "BytePattern")
            ]),
    ]
)
