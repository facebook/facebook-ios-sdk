// swift-tools-version:5.3
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
        .iOS(.v9),
        .tvOS(.v10)
    ],
    products: [
         // The Kernel of the SDK. Must be included as a runtime dependency.
        .library(
            name: "FacebookBasics",
            targets: ["FBSDKCoreKit_Basics"]
        ),

        /*
          The Core SDK library that provides two importable modules:

            - FacebookCore which includes the most current interface and
              will contain interfaces for new features written in Swift

            - FBSDKCoreKit which contains legacy Objective-C interfaces
              that will be used to maintain backwards compatibility with
              types that have been converted to Swift.
              This will not contain interfaces for new features written in Swift.
        */
        .library(
            name: "FacebookCore",
            targets: ["FacebookCore", "FBSDKCoreKit"]
        ),

        //  The Facebook Login SDK
        .library(
            name: "FacebookLogin",
            targets: ["FacebookLogin"]
        ),

        //  The Facebook Share SDK
        .library(
            name: "FacebookShare",
            targets: ["FBSDKShareKit", "FacebookShare"]
        ),

        //  The Facebook Gaming Services SDK
        .library(
            name: "FacebookGamingServices",
            targets: ["FacebookGamingServices", "FBSDKGamingServicesKit"]
        ),

        // The Facebook AEM Kit
        .library(
            name: "FacebookAEM",
            targets: ["FBAEMKit", "FacebookAEM"]
        )
    ],
    targets: [
        // The kernel of the SDK
        .binaryTarget(
            name: "FBSDKCoreKit_Basics",
            url: "https://github.com/facebook/facebook-ios-sdk/releases/download/v12.0.0/FBSDKCoreKit_Basics-Static_XCFramework.zip",
            checksum: "39cb8b75aa6a8a9b9d51dbbcbe216d6d67c1d652b354874a1918c39937dba099"
        ),

        /*
          The legacy Objective-C implementation that will be converted to Swift.
          This will not contain interfaces for new features written in Swift.
        */
        .binaryTarget(
            name: "FBAEMKit",
            url: "https://github.com/facebook/facebook-ios-sdk/releases/download/v12.0.0/FBAEMKit-Static_XCFramework.zip",
            checksum: "c95e396a920288f81123ab0c99bf7475f357988003ea07ff28bce221d8ec8c6a"
        ),

        // The main AEM module
        .target(
          name: "FacebookAEM",
          dependencies: ["FBAEMKit"]
        ),

        /*
          The legacy Objective-C implementation that will be converted to Swift.
          This will not contain interfaces for new features written in Swift.
        */
        .binaryTarget(
            name: "FBSDKCoreKit",
            url: "https://github.com/facebook/facebook-ios-sdk/releases/download/v12.0.0/FBSDKCoreKit-Static_XCFramework.zip",
            checksum: "185a8b872c76608cae5b81d89308659252396e9b5eaec22648e668a180d6bbac"
        ),

        // The main Core SDK module
        .target(
            name: "FacebookCore",
            dependencies: ["FBSDKCoreKit"],
            linkerSettings: [
                .linkedLibrary("c++"),
                .linkedLibrary("z"),
                .linkedFramework("Accelerate")
            ]
        ),

        /*
          The legacy Objective-C implementation that will be converted to Swift.
          This will not contain interfaces for new features written in Swift.
        */
        .binaryTarget(
            name: "FBSDKLoginKit",
            url: "https://github.com/facebook/facebook-ios-sdk/releases/download/v12.0.0/FBSDKLoginKit-Static_XCFramework.zip",
            checksum: "23f867e5066a68ee5a51c689b779530d78c362305666e7cf5d36a55a2bb32213"
        ),

        // The main Login SDK module
        .target(
            name: "FacebookLogin",
            dependencies: ["FacebookCore", "FBSDKLoginKit"]
        ),

        /*
          The legacy Objective-C implementation that will be converted to Swift.
          This will not contain interfaces for new features written in Swift.
        */
        .binaryTarget(
            name: "FBSDKShareKit",
            url: "https://github.com/facebook/facebook-ios-sdk/releases/download/v12.0.0/FBSDKShareKit-Static_XCFramework.zip",
            checksum: "2b109e69969c09658178519369369b41b35ee04cbdce62c27fb0d82d53c605d7"
        ),

        // The main Share SDK module
        .target(
            name: "FacebookShare",
            dependencies: ["FacebookCore", "FBSDKShareKit"]
        ),

        // The main Facebook Gaming Services module
        .binaryTarget(
            name: "FacebookGamingServices",
            url: "https://github.com/facebook/facebook-ios-sdk/releases/download/v12.0.0/FacebookGamingServices-Static_XCFramework.zip",
            checksum: "091e45ab140254d4e987fdaf25a36a530f3c0f8be515daa0973a27294cce8188"
        ),

        /*
          The legacy Objective-C implementation that will be converted to Swift.
          This will not contain interfaces for new features written in Swift.
        */
        .target(
            name: "FBSDKGamingServicesKit",
            dependencies: ["FacebookGamingServices"],
            exclude: ["Exported"]
        ),
    ],
    cxxLanguageStandard: CXXLanguageStandard.cxx11
)
