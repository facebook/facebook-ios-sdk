# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

[Full Changelog](https://github.com/facebook/facebook-objc-sdk/compare/v4.44.1...HEAD)

### Added

- Typedefs for public Objective-C blocks
- `NS_DESIGNATED_INITIALIZER` for required inits
- `NS_TYPED_EXTENSIBLE_ENUM` where made sense
- `getter` name for certain properties, like booleans
- `NS_ASSUME_NONNULL_BEGIN`, `NS_ASSUME_NONNULL_END`, and other nullability annotations
- Generics for Arrays, Sets, and Dictionaries
- `NS_SWIFT_NAME` to remove the `FBSDK` prefix where necessary (left `FB` prefix for UI elements)

### Changed

- Using `instancetype` for inits
- All `NSError **` translate to throws on Swift
- Updated Xcode Projects and Schemes to most Valid Project settings
- Getter methods changed to `readonly` properties
- Getter/Setter methods changed to `readwrite` properties
- Dot notation for access to properties
- Collections/Dictionaries became non null when at all possible
- Class creation methods become Swift inits

### Removed

- Deprecated methods
- Deprecated classes
- Deprecated properties
- Made `init` and `new` unavailable where necessary
- Used `NS_SWIFT_UNAVAILABLE` where necessary

### Fixed

- Various bug fixes

## 4.44.1

[2019-04-11](https://github.com/facebook/facebook-objc-sdk/releases/tag/v4.44.1) |
[Full Changelog](https://github.com/facebook/facebook-objc-sdk/compare/v4.44.0...v4.44.1)

### Fixed

- `_inBackground` now indicates correct application state

## 4.44.0

[2019-04-02](https://github.com/facebook/facebook-objc-sdk/releases/tag/v4.44.0) |
[Full Changelog](https://github.com/facebook/facebook-objc-sdk/compare/v4.43.0...v4.44.0)

### Added

- Add parameter `_inBackground` for app events

### Fixed

- Various bug fixes

## 4.43.0

[2019-04-01](https://github.com/facebook/facebook-objc-sdk/releases/tag/v4.43.0) |
[Full Changelog](https://github.com/facebook/facebook-objc-sdk/compare/v4.42.0...v4.43.0)

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

[2019-03-20](https://github.com/facebook/facebook-objc-sdk/releases/tag/v4.42.0) |
[Full Changelog](https://github.com/facebook/facebook-objc-sdk/compare/v4.41.2...v4.42.0)

### Changed

- Moved directory structure for better separation

### Fixed

- Various bug fixes

## 4.41.2

[2019-03-18](https://github.com/facebook/facebook-objc-sdk/releases/tag/v4.41.2) |
[Full Changelog](https://github.com/facebook/facebook-objc-sdk/compare/v4.41.1...v4.41.2)

### Fixed

- Resolved issues with the release process
- Various bug fixes

## 4.41.1

[2019-03-18](https://github.com/facebook/facebook-objc-sdk/releases/tag/v4.41.1) |
[Full Changelog](https://github.com/facebook/facebook-objc-sdk/compare/v4.41.0...v4.41.1)

### Fixed

- Resolved build failures with Carthage and Cocoapods
- Various bug fixes

## 4.41.0

[2019-03-13](https://github.com/facebook/facebook-objc-sdk/releases/tag/v4.41.0) |
[Full Changelog](https://github.com/facebook/facebook-objc-sdk/compare/v4.40.0...v4.41.0)

### Fixed

- Various bug fixes

## 4.40.0

[2019-01-17](https://github.com/facebook/facebook-objc-sdk/releases/tag/v4.40.0) |
[Full Changelog](https://github.com/facebook/facebook-objc-sdk/compare/v4.39.1...v4.40.0)

### Fixed

- Various bug fixes

## 4.39.1

[2019-01-08](https://github.com/facebook/facebook-objc-sdk/releases/tag/v4.39.1) |
[Full Changelog](https://github.com/facebook/facebook-objc-sdk/compare/sdk-version-4.0.0...v4.39.1) |
[Facebook Developer Docs Changelog](https://developers.facebook.com/docs/ios/change-log-4x)
