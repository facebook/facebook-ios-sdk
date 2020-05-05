# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

### Important

[Full Changelog](https://github.com/facebook/facebook-ios-sdk/compare/v7.0.0...HEAD)

## 7.0.0

## Changed

- Using version 7.0 of the Facebook Graph API
- Dropping support for Xcode versions below 11. This is in line with [Apple's plans](https://developer.apple.com/news/?id=03262020b) to disallow submission of Apps that do not include the iOS 13 SDK.
This means that from v7.0 on, all SDK kits will be built using Xcode 11 and Swift 5.1.
- Include the enhanced Swift interfaces

This primarily matters for how you include CocoaPods

| Distribution Channel  | Old way                              | New Way              |
| :---                  | :---                                 | :---                 |
| CocoaPods             | `pod 'FBSDKCoreKit/Swift'`           | `pod 'FBSDKCoreKit'` |
| Swift Package Manager | No change                            | No change            |
| Carthage              | No change                            | No change            |

## Deprecated

- FBSDKMarketingKit

[2020-05-05](https://github.com/facebook/facebook-ios-sdk/releases/tag/v7.0.0) |
[Full Changelog](https://github.com/facebook/facebook-ios-sdk/compare/v6.5.2...v7.0.0)

## 6.5.2

- Various bug fixes

[2020-04-29](https://github.com/facebook/facebook-ios-sdk/releases/tag/v6.5.2) |
[Full Changelog](https://github.com/facebook/facebook-ios-sdk/compare/v6.5.1...v6.5.2)

## 6.5.1

## Fixed

- The Swift interface for SharingDelegate should not have a nullable error in the callback.
- Fixes issue with login callback during backgrounding.
- Minor fixes related to Integrity

[2020-04-23](https://github.com/facebook/facebook-ios-sdk/releases/tag/v6.5.1) |
[Full Changelog](https://github.com/facebook/facebook-ios-sdk/compare/v6.5.0...v6.5.1)

## 6.5.0

## Added

- More usecase for Integrity is supported.

[2020-04-20](https://github.com/facebook/facebook-ios-sdk/releases/tag/v6.5.0) |
[Full Changelog](https://github.com/facebook/facebook-ios-sdk/compare/v6.4.0...v6.5.0)

## 6.4.0

## Added

FBSDKMessageDialog now accepts FBSDKSharePhotoContent.

FBSDKGamingServicesKit/FBSDKGamingImageUploader.h
`uploadImageWithConfiguration:andResultCompletionHandler:`
`uploadImageWithConfiguration:completionHandler:andProgressHandler:`

FBSDKGamingServicesKit/FBSDKGamingVideoUploader.h
`uploadVideoWithConfiguration:andResultCompletionHandler:`
`uploadVideoWithConfiguration:completionHandler:andProgressHandler:`

## Deprecated

FBSDKGamingServicesKit/FBSDKGamingImageUploader.h
`uploadImageWithConfiguration:andCompletionHandler:`

FBSDKGamingServicesKit/FBSDKGamingVideoUploader.h
`uploadVideoWithConfiguration:andCompletionHandler:`

[2020-03-25](https://github.com/facebook/facebook-ios-sdk/releases/tag/v6.4.0) |
[Full Changelog](https://github.com/facebook/facebook-ios-sdk/compare/v6.3.0...v6.4.0)

## Changed

Various bug fixes, CI improvements

## 6.3.0

## Added

- Support new event type for suggested events

[2020-03-25](https://github.com/facebook/facebook-ios-sdk/releases/tag/v6.3.0) |
[Full Changelog](https://github.com/facebook/facebook-ios-sdk/compare/v6.2.0...v6.3.0)

## 6.2.0

## Added

- Support for Gaming Video Uploads
- Allow Gaming Image Uploader to accept a callback
- [Messenger Sharing](https://developers.facebook.com/docs/messenger-platform/changelog/#20200304)

[2020-03-09](https://github.com/facebook/facebook-ios-sdk/releases/tag/v6.2.0) |
[Full Changelog](https://github.com/facebook/facebook-ios-sdk/compare/v6.0.0...v6.2.0)

## 6.0.0

### Updated

- Uses API version 6.0 by default

### Fixed

- `FBSDKShareDialog` delegate callbacks on apps using iOS 13

### Removed

#### ShareKit

- Facebook Messenger Template and OpenGraph Sharing
- `FBSDKMessengerActionButton`
- `FBSDKShareMessengerGenericTemplateContent`
- `FBSDKShareMessengerGenericTemplateElement`
- `FBSDKShareMessengerMediaTemplateMediaType`
- `FBSDKShareMessengerMediaTemplateContent`
- `FBSDKShareMessengerOpenGraphMusicTemplateContent`
- `FBSDKShareMessengerURLActionButton`
- `FBSDKShareAPI` since it exists to make sharing of open graph objects easier. It also requires  the deprecated `publish_actions` permission which is deprecated.
- Property `pageID` from `FBSDKSharingContent` since it only applies to sharing to Facebook Messenger
- `FBSDKShareOpenGraphAction`
- `FBSDKShareOpenGraphContent`
- `FBSDKShareOpenGraphObject`
- `FBSDKShareOpenGraphValueContainer`

#### CoreKit

- `FBSDKSettings` property `instrumentEnabled`
- Sharing of open graph objects. This is because the "publish_actions" permission is deprecated so we should not be providing helper methods that encourage its use. For more details see: https://developers.facebook.com/docs/sharing/opengraph
- `FBSDKAppEventNameSubscriptionHeartbeat`

#### LoginKit

- `FBSDKLoginBehavior` Login flows no longer support logging in through the native application. This change reflects that.

[2020-02-03](https://github.com/facebook/facebook-ios-sdk/releases/tag/v6.0.0) |
[Full Changelog](https://github.com/facebook/facebook-ios-sdk/compare/v5.15.1...v6.0.0)

## 5.15.1

### Fixed
- fix multi-thread issue for Crash Report
- fix write to file issue for Crash Report

[2020-01-28](https://github.com/facebook/facebook-ios-sdk/releases/tag/v5.15.1) |
[Full Changelog](https://github.com/facebook/facebook-ios-sdk/compare/v5.15.0...v5.15.1)

## 5.15.0

### Fixed

- fix for CocoaPods (i.e. macro `FBSDKCOCOAPODS`)
- fixes a bug in for sharing callbacks for apps using SceneDelegate

[2020-01-21](https://github.com/facebook/facebook-ios-sdk/releases/tag/v5.15.0) |
[Full Changelog](https://github.com/facebook/facebook-ios-sdk/compare/v5.14.0...v5.15.0)

## 5.14.0

### Added

- SPM Support for tvOS

### Fixed

- fix for CocoaPods static libs (i.e. no `use-frameworks!`)
- various bug fixes and unit test additions

[2020-01-14](https://github.com/facebook/facebook-ios-sdk/releases/tag/v5.14.0) |
[Full Changelog](https://github.com/facebook/facebook-ios-sdk/compare/v5.13.1...v5.14.0)

## 5.13.1

### Fixed

- bug fix for address inferencer weights load

[2019-12-16](https://github.com/facebook/facebook-ios-sdk/releases/tag/v5.13.1) |
[Full Changelog](https://github.com/facebook/facebook-ios-sdk/compare/v5.13.0...v5.13.1)

## 5.13.0

[2019-12-11](https://github.com/facebook/facebook-ios-sdk/releases/tag/v5.13.0) |
[Full Changelog](https://github.com/facebook/facebook-ios-sdk/compare/v5.12.0...v5.13.0)

### Added
- Parameter deactivation

### Fixed
- Update ML model to support non-English input

## 5.12.0

### Changed
- Updated suggested events

[2019-12-03](https://github.com/facebook/facebook-ios-sdk/releases/tag/v5.12.0) |
[Full Changelog](https://github.com/facebook/facebook-ios-sdk/compare/v5.11.1...v5.12.0)

## 5.11.1

[2019-11-19](https://github.com/facebook/facebook-ios-sdk/releases/tag/v5.11.1) |
[Full Changelog](https://github.com/facebook/facebook-ios-sdk/compare/v5.11.0...v5.11.1)

### Fixed

- Accelerate automatically linked for SPM installs [6c1a7e](https://github.com/facebook/facebook-ios-sdk/commit/6c1a7ea6d8a8aec23bf00a0da1dfb03214741c58)
- Fixes building for Unity [6a83270](https://github.com/facebook/facebook-ios-sdk/commit/6a83270d5b4f9bbbe49ae9b323a09ffc392dcc00)
- Updates build scripts, various bug fixes

## 5.11.0

[2019-11-14](https://github.com/facebook/facebook-ios-sdk/releases/tag/v5.11.0) |
[Full Changelog](https://github.com/facebook/facebook-ios-sdk/compare/v5.10.1...v5.11.0)

### Added
- Launch event suggestions

## 5.10.1

[2019-11-12](https://github.com/facebook/facebook-ios-sdk/releases/tag/v5.10.1) |
[Full Changelog](https://github.com/facebook/facebook-ios-sdk/compare/v5.10.0...v5.10.1)

### Fixed

- Various bugfixes with SPM implementation

## 5.10.0

[2019-11-06](https://github.com/facebook/facebook-ios-sdk/releases/tag/v5.10.0) |
[Full Changelog](https://github.com/facebook/facebook-ios-sdk/compare/v5.9.0...v5.10.0)

### Added

- Support for Swift Package Manager

## 5.9.0

[2019-10-29](https://github.com/facebook/facebook-ios-sdk/releases/tag/v5.9.0) |
[Full Changelog](https://github.com/facebook/facebook-ios-sdk/compare/v5.8.0...v5.9.0)

### Changed

- Using Graph API version 5.0

## 5.8.0

[2019-10-08](https://github.com/facebook/facebook-ios-sdk/releases/tag/v5.8.0) |
[Full Changelog](https://github.com/facebook/facebook-ios-sdk/compare/v5.7.0...v5.8.0)

### Added

- Launch automatic advanced matching: https://www.facebook.com/business/help/2445860982357574

## 5.7.0

[2019-09-30](https://github.com/facebook/facebook-ios-sdk/releases/tag/v5.7.0) |
[Full Changelog](https://github.com/facebook/facebook-ios-sdk/compare/v5.6.0...v5.7.0)

### Changed
- Nullability annotation in FBSDKCoreKit

### Fixed
- Various bug fixes
- Build scripts (for documentation and to support libraries that include Swift)

## 5.6.0

[2019-09-13](https://github.com/facebook/facebook-ios-sdk/releases/tag/v5.6.0) |
[Full Changelog](https://github.com/facebook/facebook-ios-sdk/compare/v5.5.0...v5.6.0)

### Changed
- Fixed FB Login for multi-window apps that created via Xcode 11
- Added support for generate_multiple_pod_projects for cocoapods 1.7.0
- Improved performance and stability of crash reporting
- Added user agent suffix for macOS

### Fixed
- Various bug fixes

## 5.5.0

[2019-08-30](https://github.com/facebook/facebook-ios-sdk/releases/tag/v5.5.0) |
[Full Changelog](https://github.com/facebook/facebook-ios-sdk/compare/v5.4.1...v5.5.0)

### Changed
- Replaced UIWebView with WKWebView as Apple will stop accepting submissions of apps that use UIWebView APIs
- Added support for Catalyst

### Fixed
- Various bug fixes

## 5.4.1

[2019-08-21](https://github.com/facebook/facebook-ios-sdk/releases/tag/v5.4.1) |
[Full Changelog](https://github.com/facebook/facebook-ios-sdk/compare/v5.4.0...v5.4.1)

### Changed
- Deprecated `+[FBSDKSettings isInstrumentEnabled]`, please use `+[FBSDKSettings isAutoLogEnabled]` instead

### Fixed
- Fix Facebook Login for iOS 13 beta
- Various bug fixes

## 5.4.0

[2019-08-15](https://github.com/facebook/facebook-ios-sdk/releases/tag/v5.4.0) |
[Full Changelog](https://github.com/facebook/facebook-ios-sdk/compare/v5.3.0...v5.4.0)

### Changed
- Add handling for crash and error to make SDK more stable

## 5.3.0

[2019-07-29](https://github.com/facebook/facebook-ios-sdk/releases/tag/v5.3.0) |
[Full Changelog](https://github.com/facebook/facebook-ios-sdk/compare/v5.2.3...v5.3.0)

### Changed
- Graph API update to v4.0

## 5.2.3

[2019-07-15](https://github.com/facebook/facebook-ios-sdk/releases/tag/v5.2.3) |
[Full Changelog](https://github.com/facebook/facebook-ios-sdk/compare/v5.2.2...v5.2.3)

### Fixed
- Fixed Facebook Login issues

## 5.2.2

[2019-07-14](https://github.com/facebook/facebook-ios-sdk/releases/tag/v5.2.2) |
[Full Changelog](https://github.com/facebook/facebook-ios-sdk/compare/v5.2.1...v5.2.2)

### Fixed
- Fixed Facebook Login on iOS 13 beta
- Various bug fixes

## 5.2.1

[2019-07-02](https://github.com/facebook/facebook-ios-sdk/releases/tag/v5.2.1) |
[Full Changelog](https://github.com/facebook/facebook-ios-sdk/compare/v5.2.0...v5.2.1)

### Fixed

- Various bug fixes

## 5.2.0

[2019-06-30](https://github.com/facebook/facebook-ios-sdk/releases/tag/v5.2.0) |
[Full Changelog](https://github.com/facebook/facebook-ios-sdk/compare/v5.1.1...v5.2.0)

### Fixed

- Fixed a crash caused by sensitive data filtering
- Fixed FB Login for iOS 13

## 5.1.1

[2019-06-22](https://github.com/facebook/facebook-ios-sdk/releases/tag/v5.1.1) |
[Full Changelog](https://github.com/facebook/facebook-ios-sdk/compare/v5.1.0...v5.1.1)

## 5.1.0

[2019-06-21](https://github.com/facebook/facebook-ios-sdk/releases/tag/v5.1.0) |
[Full Changelog](https://github.com/facebook/facebook-ios-sdk/compare/v5.0.2...v5.1.0)

## 5.0.2
[2019-06-05](https://github.com/facebook/facebook-ios-sdk/releases/tag/v5.0.2) |
[Full Changelog](https://github.com/facebook/facebook-ios-sdk/compare/v5.0.1...v5.0.2)

### Fixed

- Various bug fixes

## 5.0.1
[2019-05-21](https://github.com/facebook/facebook-ios-sdk/releases/tag/v5.0.1) |
[Full Changelog](https://github.com/facebook/facebook-ios-sdk/compare/v5.0.0...v5.0.1)

### Fixed

- Various bug fixes

## 5.0.0

[2019-04-30](https://github.com/facebook/facebook-ios-sdk/releases/tag/v5.0.0) |
[Full Changelog](https://github.com/facebook/facebook-ios-sdk/compare/v4.44.1...v5.0.0)

### Added
- support manual SDK initialization

### Changed
- extend coverage of AutoLogAppEventsEnabled flag to all internal analytics events

### Added

- Typedefs for public Objective-C blocks
- `NS_DESIGNATED_INITIALIZER` for required inits
- `NS_TYPED_EXTENSIBLE_ENUM` where made sense
- `getter` name for certain properties, like booleans
- `NS_ASSUME_NONNULL_BEGIN`, `NS_ASSUME_NONNULL_END`, and other nullability annotations
- Generics for Arrays, Sets, and Dictionaries
- `NS_SWIFT_NAME` to remove the `FBSDK` prefix where necessary (left `FB` prefix for UI elements)
- `FBSDKLoginManager -logInWithPermissions:fromViewController:handler:`
- `FBSDKLoginButton permissions`
- `FBSDKDeviceLoginButton permissions`
- `FBSDKDeviceLoginViewController permissions`
- New `FBSDKAppEventName` values

### Changed

- Using `instancetype` for inits
- All `NSError **` translate to throws on Swift
- Updated Xcode Projects and Schemes to most Valid Project settings
- Getter methods changed to `readonly` properties
- Getter/Setter methods changed to `readwrite` properties
- Dot notation for access to properties
- Collections/Dictionaries became non null when at all possible
- Class creation methods become Swift inits
- Used `NS_REFINED_FOR_SWIFT` where advisable

### Deprecated

- `FBSDKLoginManager -logInWithReadPermissions:fromViewController:handler:`
- `FBSDKLoginManager -logInWithWritePermissions:fromViewController:handler:`
- `FBSDKLoginButton readPermissions`
- `FBSDKLoginButton writePermissions`
- `FBSDKDeviceLoginButton readPermissions`
- `FBSDKDeviceLoginButton writePermissions`
- `FBSDKDeviceLoginViewController readPermissions`
- `FBSDKDeviceLoginViewController writePermissions`
- `FBSDKUtility SHA256HashString`
- `FBSDKUtility SHA256HashData`

### Removed

- Deprecated methods
- Deprecated classes
- Deprecated properties
- Made `init` and `new` unavailable where necessary
- Used `NS_SWIFT_UNAVAILABLE` where necessary

### Fixed

- Various bug fixes

### 5.X Upgrade Guide

#### All Developers

- Light-weight generics have been added for Arrays, Sets, and Dictionaries. Make sure you're passing in the proper
  types.
- Some methods used to have closures as arguments, but did not have them as the final argument. All these methods have
  been rearranged to have the closure as the final argument.

#### ObjC Developers

- Certain string values, like App Event Names and HTTP Method, have been made NSString typedef with the
  `NS_TYPED_EXTENSIBLE_ENUM` attribute. All your existing code should work just fine.

#### Swift Developers

- `NS_SWIFT_NAME` was applied where applicable. Most of these changes Xcode can fix automatically.
  - The `FBSDK` prefix for UI elements has been replaced with the simpler `FB` prefix.
  - The `FBSDK` prefix for all other types has been removed.
  - `FBSDKError` is now `CoreError`.
- `NS_ERROR_ENUM` is used to handling errors now. For more details, view Apple's documentation on
  [Handling Cocoa Errors in Swift](https://developer.apple.com/documentation/swift/cocoa_design_patterns/handling_cocoa_errors_in_swift).
- Certain string values, like App Event Names and HTTP Method, have been made extensible structs with the
  `NS_TYPED_EXTENSIBLE_ENUM` attribute:
  - `FBSDKAppEventNamePurchased` -> `AppEvents.Name.purchased`
  - `"custom_app_event"` -> `AppEvents.Name("custom_app_event")`
- Certain values have been annotated with `NS_REFINED_FOR_SWIFT` and can be customized via either:
  1. The Facebook SDK in Swift (Beta)
  2. Implementing custom extensions

```swift
// Custom extensions
public extension AccessToken {
  var permissions: Set<String> {
    return Set(__permissions)
  }
}

extension AppEvents.Name {
  static let customAppEvent = AppEvents.Name("custom_app_event")
}

extension ShareDialog.Mode: CustomStringConvertible {
  public var description: String {
    return __NSStringFromFBSDKShareDialogMode(self)
  }
}

// Later in code
let perms: Set<String> = AccessToken(...).permissions

let event: AppEvents.Name = .customAppEvent

let mode: ShareDialog.Mode = .native
let description: String = "\(mode)"
```

## 4.44.1

[2019-04-11](https://github.com/facebook/facebook-ios-sdk/releases/tag/v4.44.1) |
[Full Changelog](https://github.com/facebook/facebook-ios-sdk/compare/v4.44.0...v4.44.1)

### Fixed

- `_inBackground` now indicates correct application state

## 4.44.0

[2019-04-02](https://github.com/facebook/facebook-ios-sdk/releases/tag/v4.44.0) |
[Full Changelog](https://github.com/facebook/facebook-ios-sdk/compare/v4.43.0...v4.44.0)

### Added

- Add parameter `_inBackground` for app events

### Fixed

- Various bug fixes

## 4.43.0

[2019-04-01](https://github.com/facebook/facebook-ios-sdk/releases/tag/v4.43.0) |
[Full Changelog](https://github.com/facebook/facebook-ios-sdk/compare/v4.42.0...v4.43.0)

### Added

- Support for Xcode 10.2

### Deprecated

- `FBSDKLoginBehaviorNative`
- `FBSDKLoginBehaviorSystemAccount`
- `FBSDKLoginBehaviorWeb`
- `[FBSDKLoginManager renewSystemCredentials]`

### Fixed

- Various bug fixes

## 4.42.0

[2019-03-20](https://github.com/facebook/facebook-ios-sdk/releases/tag/v4.42.0) |
[Full Changelog](https://github.com/facebook/facebook-ios-sdk/compare/v4.41.2...v4.42.0)

### Changed

- Moved directory structure for better separation

### Fixed

- Various bug fixes

## 4.41.2

[2019-03-18](https://github.com/facebook/facebook-ios-sdk/releases/tag/v4.41.2) |
[Full Changelog](https://github.com/facebook/facebook-ios-sdk/compare/v4.41.1...v4.41.2)

### Fixed

- Resolved issues with the release process
- Various bug fixes

## 4.41.1

[2019-03-18](https://github.com/facebook/facebook-ios-sdk/releases/tag/v4.41.1) |
[Full Changelog](https://github.com/facebook/facebook-ios-sdk/compare/v4.41.0...v4.41.1)

### Fixed

- Resolved build failures with Carthage and Cocoapods
- Various bug fixes

## 4.41.0

[2019-03-13](https://github.com/facebook/facebook-ios-sdk/releases/tag/v4.41.0) |
[Full Changelog](https://github.com/facebook/facebook-ios-sdk/compare/v4.40.0...v4.41.0)

### Fixed

- Various bug fixes

## 4.40.0

[2019-01-17](https://github.com/facebook/facebook-ios-sdk/releases/tag/v4.40.0) |
[Full Changelog](https://github.com/facebook/facebook-ios-sdk/compare/v4.39.1...v4.40.0)

### Fixed

- Various bug fixes

## 4.39.1

[2019-01-08](https://github.com/facebook/facebook-ios-sdk/releases/tag/v4.39.1) |
[Full Changelog](https://github.com/facebook/facebook-ios-sdk/compare/sdk-version-4.0.0...v4.39.1) |
[Facebook Developer Docs Changelog](https://developers.facebook.com/docs/ios/change-log-4x)
