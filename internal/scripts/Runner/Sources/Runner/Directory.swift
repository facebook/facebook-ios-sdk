// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import Foundation
import ShellOut

enum Directory {
    case box
    case build
    case coreKit
    case fbsource(isSandcastle: Bool)
    case hackbook
    case hackbookBuild
    case home
    case include
    case `internal`
    case internalScripts
    case releaseSimulator
    case runner
    case samples
    case scripts
    case sdk
    case vendorLib
    case vendoredFacebookSDK
    case xcframeworks
    case xcodeBuildDir

    // Note: Expect box_dir to be the sdk directory here.
    // BOX_DIR=/data/sandcastle/boxes/trunk-git-facebook-ios-sdk
    // As a follow-up this can likely be removed entirely and can just use the initial directory.
    static var boxURL: URL = {
        do {
            return URL(fileURLWithPath: try shellOut(to: "echo $BOX_DIR"))
        } catch {
            fatalError("Creating a URL should succeed with or without an env var for BOX_DIR")
        }
    }()

    static var scratchURL: URL = {
        do {
            return URL(fileURLWithPath: try shellOut(to: "mkscratch path"))
        } catch {
            fatalError("Error creating scratch dir with `mkscratch path`")
        }
    }()

    static var initial: URL = {
        do {
            return URL(fileURLWithPath: try shellOut(to: "pwd"))
        } catch {
            fatalError("Need an initial directory to run commands from.")
        }
    }()

    static var homeURL: URL = {
        guard let path = try? shellOut(to: "echo $HOME"),
              !path.isEmpty
        else {
            fatalError("There should be a $HOME env var defined")
        }

        return URL(fileURLWithPath: path)
    }()

    var path: String {
        url.relativePath
    }

    var url: URL {
        switch self {
        case .box:
            return Directory.boxURL

        case .build:
            return Directory.sdk.url
                .appendingPathComponent("build")

        case .coreKit:
            return Directory.sdk.url
                .appendingPathComponent("FBSDKCoreKit")
                .appendingPathComponent("FBSDKCoreKit")

        case let .fbsource(isSandcastle):
            if isSandcastle {
                return URL(fileURLWithPath: "/data/sandcastle/boxes/trunk-hg-fbobjc-fbsource")
            } else {
                do {
                    let fbsourcePath = try shellOut(to: "echo ~/fbsource")
                    return URL(fileURLWithPath: fbsourcePath)
                } catch {
                    fatalError("Could not resolve path: ~/fbsource. Is fbsource checked out on your local machine?")
                }
            }

        case .hackbook:
            return Directory.internal.url
                .appendingPathComponent("testing")
                .appendingPathComponent("Hackbook")

        case .hackbookBuild:
            return Directory.hackbook.url
                .appendingPathComponent("build")

        case .home:
            return Directory.homeURL

        case .include:
            return Directory.coreKit.url
                .appendingPathComponent("include")

        case .internal:
            return Directory.sdk.url
                .appendingPathComponent("internal")

        case .internalScripts:
            return Directory.internal.url
                .appendingPathComponent("scripts")

        case .releaseSimulator:
            return Directory.xcodeBuildDir.url
                .appendingPathComponent("Release-iphonesimulator")

        case .runner:
            return Directory.internalScripts.url
                .appendingPathComponent("Runner")

        case .samples:
            return Directory.sdk.url
                .appendingPathComponent("samples")

        case .scripts:
            return Directory.sdk.url
                .appendingPathComponent("scripts")

        case .sdk:
            return Directory.initial
                .appendingPathComponent("../../..")

        case .vendorLib:
            return Directory.sdk.url
                .deletingLastPathComponent()
                .appendingPathComponent("VendorLib")

        case .vendoredFacebookSDK:
            return Directory.vendorLib.url
                .appendingPathComponent("FacebookSDK")

        case .xcframeworks:
            return Directory.build.url
                .appendingPathComponent("XCFrameworks")

        case .xcodeBuildDir:
            return Directory.scratchURL
                .appendingPathComponent("XCODE_BUILD_DIR")
        }
    }
}
