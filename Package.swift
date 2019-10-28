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
            name: "FacebookCore",
            targets: ["FacebookCore"]
        ),
        .library(
            name: "FacebookLogin",
            targets: ["FacebookLogin"]
        ),
        .library(
            name: "FacebookShare",
            targets: ["FacebookShare"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "FBSDKCoreKit",
            dependencies: [],
            path: "FBSDKCoreKit/FBSDKCoreKit",
            exclude: [
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
        .target(
            name: "FacebookCore",
            dependencies: ["FBSDKCoreKit"],
            path: "FBSDKCoreKit/FBSDKCoreKit/Swift"
        ),
        .target(
            name: "FBSDKLoginKit",
            dependencies: ["FBSDKCoreKit"],
            path: "FBSDKLoginKit/FBSDKLoginKit",
            exclude: [
                "include/FBSDKLoginKit.h",
                "include/FBSDKLoginButton.h",
                "Swift"
            ],
            cSettings: [
                .headerSearchPath("Internal"),
                .headerSearchPath("../../FBSDKCoreKit/FBSDKCoreKit/Internal"),
            ]
        ),
        .target(
            name: "FacebookLogin",
            dependencies: ["FacebookCore", "FBSDKLoginKit"],
            path: "FBSDKLoginKit/FBSDKLoginKit/Swift"
        ),
        .target(
            name: "FBSDKShareKit",
            dependencies: ["FBSDKCoreKit"],
            path: "FBSDKShareKit/FBSDKShareKit",
            exclude: [
                "Swift",
                "FBSDKDeviceShareButton.h",
                "FBSDKDeviceShareButton.m",
                "FBSDKDeviceShareViewController.h",
                "FBSDKDeviceShareViewController.m",
            ],
            cSettings: [
                .headerSearchPath("Internal"),
                .headerSearchPath("../../FBSDKCoreKit/FBSDKCoreKit/Internal"),
            ]
        ),
        .target(
            name: "FacebookShare",
            dependencies: ["FacebookCore", "FBSDKShareKit"],
            path: "FBSDKShareKit/FBSDKShareKit/Swift"
        ),
    ]
)
