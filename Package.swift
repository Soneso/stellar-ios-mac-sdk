// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "stellarsdk",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
    ],
    products: [
        .library(
            name: "stellarsdk", 
            targets: ["stellarsdk", "ed25519C"]
        )
    ],
    targets: [
        .target(
            name: "stellarsdk",
            dependencies: [
                .target(name: "ed25519C")
            ],
            path: "stellarsdk/stellarsdk",
            exclude: [
                "Info.plist",
                "stellarsdk.h",
                "libs/ed25519-C"
            ]
        ),
        .target(
            name: "ed25519C",
            path: "stellarsdk/stellarsdk/libs/ed25519-C",
            exclude: [
                "license.txt"
            ],
            publicHeadersPath: "include"
        )
    ]
)
