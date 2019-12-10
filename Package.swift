// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

// Copyright (c) 2016-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

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
                .headerSearchPath("AppEvents/Internal"),
                .headerSearchPath("AppEvents/Internal/Codeless"),
                .headerSearchPath("AppEvents/Internal/ViewHierarchy/"),
                .headerSearchPath("AppEvents/Internal/ML"),
                .headerSearchPath("AppEvents/Internal/RestrictiveDataFilter"),
                .headerSearchPath("AppEvents/Internal/EventDeactivation"),
                .headerSearchPath("AppEvents/Internal/SuggestedEvents"),
                .headerSearchPath("AppLink"),
                .headerSearchPath("AppLink/Internal"),
                .headerSearchPath("Basics/Instrument"),
                .headerSearchPath("Basics/Internal"),
                .headerSearchPath("Internal"),
                .headerSearchPath("Internal/Base64"),
                .headerSearchPath("Internal/BridgeAPI"),
                .headerSearchPath("Internal/BridgeAPI/ProtocolVersions"),
                .headerSearchPath("Internal/Cryptography"),
                .headerSearchPath("Internal/ErrorRecovery"),
                .headerSearchPath("Internal/Instrument"),
                .headerSearchPath("Internal/Instrument/CrashReport"),
                .headerSearchPath("Internal/Instrument/ErrorReport"),
                .headerSearchPath("Internal/Network"),
                .headerSearchPath("Internal/ServerConfiguration"),
                .headerSearchPath("Internal/TokenCaching"),
                .headerSearchPath("Internal/UI"),
            ],
            linkerSettings: [
                .linkedFramework("Accelerate"),
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
