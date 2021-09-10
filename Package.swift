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
        /*
         The Kernel of the SDK. Must be included as a runtime dependency.
         */
        .library(
            name: "FBSDKCoreKit_Basics",
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

        /*
          The Facebook Login SDK
        */
        .library(
            name: "FacebookLogin",
            targets: ["FacebookLogin"]
        ),

        /*
          The Facebook Share SDK
        */
        .library(
            name: "FacebookShare",
            targets: ["FBSDKShareKit", "FacebookShare"]
        ),

        /*
          The Facebook Gaming Services SDK
        */
        .library(
            name: "FacebookGamingServices",
            targets: ["FacebookGamingServices", "FBSDKGamingServicesKit"]
        ),

        /*
          The Facebook AEM Kit
        */
        .library(
            name: "FacebookAEM",
            targets: ["FBAEMKit", "FacebookAEM"]
        )
    ],
    targets: [
        /*
          The kernel of the SDK
        */
        .binaryTarget(
            name: "FBSDKCoreKit_Basics",
            url: "https://github.com/facebook/facebook-ios-sdk/releases/download/v11.2.0/FBSDKCoreKit_Basics_XCFramework.zip",
            checksum: "4c1a5e69b1e858be4ceeff1547e71ce7ef758864edc1061166c39502075a7ba0"
        ),

        /*
          The legacy Objective-C implementation of AEM Kit
        */
        .binaryTarget(
            name: "FBAEMKit",
            url: "https://github.com/facebook/facebook-ios-sdk/releases/download/v11.2.0/FBAEMKit_XCFramework.zip",
            checksum: "f7ad5812f0f1c5ca10e577c034400358bf50a5220696f697bf3a1bc300f1f995"
        ),
        
        /*
          The main AEM module
         */
        .target(
          name: "FacebookAEM",
          dependencies: ["FBAEMKit"]
        ),
        
        /*
          The legacy Objective-C interface that will be used to maintain
          backwards compatibility with types that have been converted to Swift.

          This will not contain interfaces for new features written in Swift.
        */
        .binaryTarget(
            name: "FBSDKCoreKit",
            url: "https://github.com/facebook/facebook-ios-sdk/releases/download/v11.2.0/FBSDKCoreKit_XCFramework.zip",
            checksum: "4bd619e776cc82c53908bb94d85c9ada0d386f8c437f72ea26fc056dc121e272"
        ),

        .target(
            name: "FacebookCore",
            dependencies: ["FBSDKCoreKit"]
        ),

        /*
          The main Core SDK module
        */

        /*
          The legacy Objective-C implementation that will be converted to Swift.
          This will not contain interfaces for new features written in Swift.
        */
        .binaryTarget(
            name: "FBSDKLoginKit",
            url: "https://github.com/facebook/facebook-ios-sdk/releases/download/v11.2.0/FBSDKLoginKit_XCFramework.zip",
            checksum: "589eb1edfc91ab36f0b66830866b8ec8b75c9b54528e80640032e8154a77021b"
        ),
        
        /*
          The main Login SDK module
        */
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
            url: "https://github.com/facebook/facebook-ios-sdk/releases/download/v11.2.0/FBSDKShareKit_XCFramework.zip",
            checksum: "c8b161a7151b4b79985be256e20994e146007562b927a876afa6c30b5b2b5c61"
        ),
        
        /*
          The main Share SDK module
        */
        .target(
            name: "FacebookShare",
            dependencies: ["FacebookCore", "FBSDKShareKit"]
        ),

        .binaryTarget(
            name: "FacebookGamingServices",
            url: "https://github.com/facebook/facebook-ios-sdk/releases/download/v11.2.0/FacebookGamingServices_XCFramework.zip",
            checksum: "ed9edc676e5937652902e39f3d98f6fe37505d0e6a1ee8130621f04317c425f3"
        ),
        
        /*
          The legacy Objective-C interface that will be used to maintain
          backwards compatibility with types that have been converted to Swift.

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
