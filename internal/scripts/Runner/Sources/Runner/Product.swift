// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import ArgumentParser

enum Product: String, CaseIterable, ExpressibleByArgument {
    case aem = "FBAEMKit"
    case basics = "FBSDKCoreKit_Basics"
    case core = "FBSDKCoreKit"
    case login = "FBSDKLoginKit"
    case share = "FBSDKShareKit"
    case gamingServices = "FBSDKGamingServicesKit"
//    TODO: Uncomment for release
//    case tvoskit = "FBSDKTVOSKit"

    init?(argument: String) {
        switch argument {
        case "aem", "AEM", "AEMKit": self = .aem
        case "basics", "Basics": self = .basics
        case "core", "Core", "CoreKit": self = .core
        case "login", "Login", "LoginKit": self = .login
        case "share", "Share", "FBSDKShareKit": self = .share
        case "gamingServices", "GamingServices", "FBSDKGamingServicesKit": self = .gamingServices
//        TODO: Uncomment for release
//        case "tvos", "TVOS", "FBSDKTVOSKit": self = .tvoskit
        default:
            fatalError("Invalid product argument: \(argument)")
        }
    }

    var destinations: [Destination] {
        switch self {
        case .aem, .basics, .core, .login, .share:
            return [
                Destination.ios,
                Destination.iosSimulator,
                Destination.macCatalyst,
//                TODO: Uncomment for release
//                Destination.tvos,
//                Destination.tvosSimulator
            ]
        case .gamingServices:
            return [
                Destination.ios,
                Destination.iosSimulator,
                Destination.macCatalyst
            ]

//        TODO: Uncomment for release
//        case .tvoskit:
//            return [
//                Destination.tvos,
//                Destination.tvosSimulator
//            ]
        }
    }

    func scheme(destination: Destination, libraryType: LibraryType) -> String {
        rawValue + destination.schemeSuffix(libraryType: libraryType)
    }

    func stringBundlePathInArchive(for libraryType: LibraryType) -> String? {
        guard self == .core,
              libraryType == .dynamic
        else { return nil }

        return "Products/@rpath/\(rawValue).framework"
    }
}
