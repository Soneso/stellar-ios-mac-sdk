// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "stellarsdk",
    platforms: [
        .macOS(.v12),
        .iOS(.v15),
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
        ),
        .testTarget(
            name: "stellarsdkUnitTests",
            dependencies: ["stellarsdk"],
            path: "stellarsdk/stellarsdkUnitTests",
            resources: [
                .copy("soroban/soroban_token_contract.wasm")
            ]
        ),
        .testTarget(
            name: "stellarsdkIntegrationTests",
            dependencies: ["stellarsdk"],
            path: "stellarsdk/stellarsdkIntegrationTests",
            resources: [
                .copy("soroban/soroban_hello_world_contract.wasm"),
                .copy("soroban/soroban_token_contract.wasm"),
                .copy("soroban/soroban_auth_contract.wasm"),
                .copy("soroban/soroban_atomic_swap_contract.wasm"),
                .copy("soroban/soroban_events_contract.wasm"),
                .copy("web_authenticator_contracts/wasm/sep_45_account.wasm")
            ]
        ),
    ]
)
