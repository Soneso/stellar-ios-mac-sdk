// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "stellarsdk",
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
            publicHeadersPath: "include"
        )
    ]
)
