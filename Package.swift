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
            url: "https://github.com/facebook/facebook-ios-sdk/releases/download/v12.0.1/FBSDKCoreKit_Basics-Static_XCFramework.zip",
            checksum: "e94f0c61ee84e4349354e058d1c8c5349457b7570a2acf557bf736cc903a094e"
        ),

        /*
          The legacy Objective-C implementation that will be converted to Swift.
          This will not contain interfaces for new features written in Swift.
        */
        .binaryTarget(
            name: "FBAEMKit",
            url: "https://github.com/facebook/facebook-ios-sdk/releases/download/v12.0.1/FBAEMKit-Static_XCFramework.zip",
            checksum: "098f13451bd31a82eef074da3bb3eb7f5fa13c2a9a6c96a8433ac31bdadfa10d"
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
            url: "https://github.com/facebook/facebook-ios-sdk/releases/download/v12.0.1/FBSDKCoreKit-Static_XCFramework.zip",
            checksum: "c06dd4e510d82d60a6998ba9e8e77d8bd4ac949917d55f1b882d4d478351b3eb"
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
            url: "https://github.com/facebook/facebook-ios-sdk/releases/download/v12.0.1/FBSDKLoginKit-Static_XCFramework.zip",
            checksum: "3d12e1f2d626b2e11cb5dca2424c23eb3945d2fdb87206d30a018c30649bd766"
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
            url: "https://github.com/facebook/facebook-ios-sdk/releases/download/v12.0.1/FBSDKShareKit-Static_XCFramework.zip",
            checksum: "0884105877a25f96d5f2554f781d2aeb16acdd0843ad03a5e11dafce434e6a8a"
        ),

        // The main Share SDK module
        .target(
            name: "FacebookShare",
            dependencies: ["FacebookCore", "FBSDKShareKit"]
        ),

        // The main Facebook Gaming Services module
        .binaryTarget(
            name: "FacebookGamingServices",
            url: "https://github.com/facebook/facebook-ios-sdk/releases/download/v12.0.1/FacebookGamingServices-Static_XCFramework.zip",
            checksum: "b5c7fdb93af1ff38d5fe347e7001a1f8837e4c143302cb9f8ff29ef47255d2ed"
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
