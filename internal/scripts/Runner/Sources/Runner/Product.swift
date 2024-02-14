// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import ArgumentParser

enum Product: String, CaseIterable, ExpressibleByArgument {
    case aem = "FBAEMKit"
    case basics = "FBSDKCoreKit_Basics"
    case core = "FBSDKCoreKit"
    case login = "FBSDKLoginKit"
    case share = "FBSDKShareKit"
    case gamingServices = "FBSDKGamingServicesKit"

    init?(argument: String) {
        switch argument {
        case "aem", "AEM", "AEMKit": self = .aem
        case "basics", "Basics": self = .basics
        case "core", "Core", "CoreKit": self = .core
        case "login", "Login", "LoginKit": self = .login
        case "share", "Share", "FBSDKShareKit": self = .share
        case "gamingServices", "GamingServices", "FBSDKGamingServicesKit": self = .gamingServices
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
            ]
        case .gamingServices:
            return [
                Destination.ios,
                Destination.iosSimulator,
                Destination.macCatalyst,
            ]
        }
    }

    func scheme(destination: Destination, libraryType: LibraryType) -> String {
        rawValue + destination.schemeSuffix(libraryType: libraryType)
    }

    func stringBundlePathInArchive(for libraryType: LibraryType, forDestination destination: Destination) -> String? {
        guard self == .core,
              libraryType == .dynamic
        else { return nil }

        if destination == Destination.macCatalyst {
            return "Products/@rpath/\(rawValue).framework/Versions/A/Resources"
        }
        return "Products/@rpath/\(rawValue).framework"
    }
}
