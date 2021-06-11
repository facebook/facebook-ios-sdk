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

let conditionalCompilationFlag = "FBSDK_SWIFT_PACKAGE"

let package = Package(
    name: "Facebook",
    platforms: [
        .iOS(.v9),
        .tvOS(.v10)
    ],
    products: [

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
            targets: ["FacebookShare"]
        ),

        /*
          The Facebook Gaming Services SDK
        */
        .library(
            name: "FacebookGamingServices",
            targets: ["FacebookGamingServices"]
        )
    ],
    targets: [
        /*
          The kernel of the SDK
        */
        .target(
            name: "FBSDKCoreKit_Basics"
        ),

        /*
          The legacy Objective-C implementation that will be converted to Swift.
          This will not contain interfaces for new features written in Swift.
        */
        .target(
            name: "LegacyCoreKit",
            dependencies: ["FBSDKCoreKit_Basics"],
            path: "FBSDKCoreKit/FBSDKCoreKit",
            exclude: ["Swift"],
            cSettings: [
                .headerSearchPath("AppEvents"),
                .headerSearchPath("AppEvents/Internal"),
                .headerSearchPath("AppEvents/Internal/AAM"),
                .headerSearchPath("AppEvents/Internal/AEM"),
                .headerSearchPath("AppEvents/Internal/Codeless"),
                .headerSearchPath("AppEvents/Internal/ViewHierarchy/"),
                .headerSearchPath("AppEvents/Internal/ML"),
                .headerSearchPath("AppEvents/Internal/Integrity"),
                .headerSearchPath("AppEvents/Internal/EventDeactivation"),
                .headerSearchPath("AppEvents/Internal/SKAdNetwork"),
                .headerSearchPath("AppEvents/Internal/SuggestedEvents"),
                .headerSearchPath("AppLink"),
                .headerSearchPath("AppLink/Internal"),
                .headerSearchPath("GraphAPI"),
                .headerSearchPath("Internal"),
                .headerSearchPath("Internal/Base64"),
                .headerSearchPath("Internal/BridgeAPI"),
                .headerSearchPath("Internal/BridgeAPI/ProtocolVersions"),
                .headerSearchPath("Internal/Cryptography"),
                .headerSearchPath("Internal/Device"),
                .headerSearchPath("Internal/ErrorRecovery"),
                .headerSearchPath("Internal/FeatureManager"),
                .headerSearchPath("Internal/Instrument"),
                .headerSearchPath("Internal/Instrument/CrashReport"),
                .headerSearchPath("Internal/Instrument/ErrorReport"),
                .headerSearchPath("Internal/Monitoring"),
                .headerSearchPath("Internal/Network"),
                .headerSearchPath("Internal/ServerConfiguration"),
                .headerSearchPath("Internal/TokenCaching"),
                .headerSearchPath("Internal/UI"),
                .headerSearchPath("Internal/WebDialog"),
                .define("FBSDK_SWIFT_PACKAGE", to: nil, .when(platforms: [.iOS, .macOS, .tvOS], configuration: nil))
            ],
            linkerSettings: [
                .linkedFramework("Accelerate")
            ]
        ),

        /*
          The main Core SDK module
        */
        .target(
            name: "FacebookCore",
            dependencies: ["LegacyCoreKit"],
            cSettings: [
                .headerSearchPath("../../FBSDKCoreKit/FBSDKCoreKit/Internal"),
                .define("FBSDK_SWIFT_PACKAGE", to: nil, .when(platforms: [.iOS, .macOS, .tvOS], configuration: nil))
            ],
            swiftSettings: [
                .define("FBSDK_SWIFT_PACKAGE")
            ]
        ),

        /*
          The legacy Objective-C interface that will be used to maintain
          backwards compatibility with types that have been converted to Swift.

          This will not contain interfaces for new features written in Swift.
        */
        .target(
            name: "FBSDKCoreKit",
            dependencies: ["LegacyCoreKit", "FacebookCore"],
            cSettings: [
                .define("FBSDK_SWIFT_PACKAGE", to: nil, .when(platforms: [.iOS, .macOS, .tvOS], configuration: nil))
            ]
        ),

        /*
          The legacy Objective-C implementation that will be converted to Swift.
          This will not contain interfaces for new features written in Swift.
        */
        .target(
            name: "FBSDKLoginKit",
            dependencies: ["FBSDKCoreKit"],
            path: "FBSDKLoginKit/FBSDKLoginKit",
            exclude: ["Swift"],
            cSettings: [
                .headerSearchPath("Internal"),
                .headerSearchPath("../../FBSDKCoreKit/FBSDKCoreKit/Internal"),
                .define(
                    conditionalCompilationFlag,
                    to: nil,
                    .when(platforms: [.iOS, .macOS, .tvOS], configuration: nil)
                )
            ]
        ),

        /*
          The main Login SDK module
        */
        .target(
            name: "FacebookLogin",
            dependencies: ["FacebookCore", "FBSDKLoginKit"],
            path: "FBSDKLoginKit/FBSDKLoginKit/Swift",
            cSettings: [
                .define("FBSDK_SWIFT_PACKAGE", to: nil, .when(platforms: [.iOS, .macOS, .tvOS], configuration: nil))
            ],
            swiftSettings: [.define("TARGET_OS_TV", .when(platforms: [.tvOS], configuration: nil))]
        ),

        /*
          The legacy Objective-C implementation that will be converted to Swift.
          This will not contain interfaces for new features written in Swift.
        */
        .target(
            name: "FBSDKShareKit",
            dependencies: ["FBSDKCoreKit"],
            path: "FBSDKShareKit/FBSDKShareKit",
            exclude: ["Swift"],
            cSettings: [
                .headerSearchPath("Internal"),
                .headerSearchPath("../../FBSDKCoreKit/FBSDKCoreKit/Internal"),
                .define("FBSDK_SWIFT_PACKAGE", to: nil, .when(platforms: [.iOS, .macOS, .tvOS], configuration: nil))
            ]
        ),

        /*
          The main Share SDK module
        */
        .target(
            name: "FacebookShare",
            dependencies: ["FacebookCore", "FBSDKShareKit"],
            path: "FBSDKShareKit/FBSDKShareKit/Swift",
            cSettings: [
                .define("FBSDK_SWIFT_PACKAGE", to: nil, .when(platforms: [.iOS, .macOS, .tvOS], configuration: nil))
            ]
        ),

        /*
          The legacy Objective-C implementation that will be converted to Swift.
          This will not contain interfaces for new features written in Swift.
        */
        .target(
            name: "FBSDKGamingServicesKit",
            dependencies: ["FBSDKCoreKit"],
            path: "FBSDKGamingServicesKit/FBSDKGamingServicesKit",
            exclude: ["Swift"],
            cSettings: [
                .headerSearchPath("Internal"),
                .headerSearchPath("../../FBSDKCoreKit/FBSDKCoreKit/Internal"),
                .headerSearchPath("../../FBSDKShareKit/FBSDKShareKit/Internal"),
                .define(
                    conditionalCompilationFlag,
                    to: nil,
                    .when(platforms: [.iOS, .macOS, .tvOS], configuration: nil)
                )
            ]
        ),

        /*
          The main Gaming Services SDK module
        */
        .target(
            name: "FacebookGamingServices",
            dependencies: ["FacebookCore", "FBSDKGamingServicesKit"],
            path: "FBSDKGamingServicesKit/FBSDKGamingServicesKit/Swift",
            cSettings: [
                .define("FBSDK_SWIFT_PACKAGE", to: nil, .when(platforms: [.iOS, .macOS, .tvOS], configuration: nil))
            ]
        )
    ],
    cxxLanguageStandard: CXXLanguageStandard.cxx11
)
