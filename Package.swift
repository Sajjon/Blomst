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
        .package(url: "https://github.com/sajjon/BytePattern", from: "0.0.3"),
        .package(url: "https://github.com/attaswift/BigInt", from: "5.3.0"),
    ],
    targets: [
        .binaryTarget(
            name: "BLST",
            path: "BLST.xcframework"
        ),
        .target(
            name: "Blomst",
            dependencies: [
                "BLST",
                .product(name: "BytesMutation", package: "BytePattern"),
                .product(name: "BytePattern", package: "BytePattern"),
            ]),
        .testTarget(
            name: "BlomstTests",
            dependencies: [
                "Blomst",
                "BigInt",
                .product(name: "XCTAssertBytesEqual", package: "BytePattern")
            ]),
    ]
)
