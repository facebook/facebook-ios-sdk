// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Facebook",
    platforms: [
        .iOS(.v8)
    ],
    products: [
        .library(
            name: "FBSDKCoreKit",
            targets: ["FBSDKCoreKit"]
        ),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "FBSDKCoreKit",
            dependencies: [],
            path: "FBSDKCoreKit/FBSDKCoreKit",
            exclude: [
                // Either needs to be fixed and included,
                // or included but somehow compiled no-arc
                //"Internal_NoARC/FBSDKDynamicFrameworkLoader.m",
                "Internal/Device",
                "FBSDKDeviceViewControllerBase.m",
                "FBSDKDeviceButton.m",
                "Swift"
            ],
            cSettings: [
                .headerSearchPath("AppEvents"),
                .headerSearchPath("Basics/Internal"),
                .headerSearchPath("AppEvents/Internal/RestrictiveDataFilter"),
                .headerSearchPath("Internal"),
//                .headerSearchPath("."),
                .headerSearchPath("AppEvents/Internal"),
                .headerSearchPath("AppLink"),
                .headerSearchPath("Internal/Network"),
                .headerSearchPath("Internal/ServerConfiguration"),
                .headerSearchPath("AppEvents/Internal/Codeless"),
                .headerSearchPath("Internal/UI"),
                .headerSearchPath("Internal/TokenCaching"),
                .headerSearchPath("Internal/Instrument/CrashReport"),
                .headerSearchPath("Basics/Instrument"),
                .headerSearchPath("Internal/Instrument/ErrorReport"),
                .headerSearchPath("Internal/Cryptography"),
                .headerSearchPath("Internal/ErrorRecovery"),
                .headerSearchPath("Internal/Base64"),
                .headerSearchPath("Internal/BridgeAPI/ProtocolVersions"),
                .headerSearchPath("Internal/BridgeAPI"),
                .headerSearchPath("Internal/Instrument"),
                .headerSearchPath("AppLink/Internal"),
            ]

        ),
    ]
)
