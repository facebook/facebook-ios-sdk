# Change Log

## [0.3.0](https://github.com/facebook/facebook-sdk-swift/tree/0.3.0) (2017-10-11)
[Full Changelog](https://github.com/facebook/facebook-sdk-swift/compare/0.2.0...0.3.0)

**Implemented enhancements:**

- Update for Xcode 9 and Swift 4 [\#184](https://github.com/facebook/facebook-sdk-swift/pull/184) ([gfosco](https://github.com/gfosco))
- Add userId and user properties to AppEventsLogger. [\#147](https://github.com/facebook/facebook-sdk-swift/pull/147) ([nlutsenko](https://github.com/nlutsenko))
- Expand a set of predefined Read and Publish permissions. [\#130](https://github.com/facebook/facebook-sdk-swift/pull/130) ([ranesr](https://github.com/ranesr))
- Publicize .name property on Permission. [\#96](https://github.com/facebook/facebook-sdk-swift/pull/96) ([nlutsenko](https://github.com/nlutsenko))
- Add AppEventsLogger.pushNotificationsDeviceToken [\#71](https://github.com/facebook/facebook-sdk-swift/pull/71) ([arsonik](https://github.com/arsonik))
- Doc fix, Any/Object [\#69](https://github.com/facebook/facebook-sdk-swift/pull/69) ([arsonik](https://github.com/arsonik))

**Fixed bugs:**

- Fix LoginManager's initializer problem. [\#137](https://github.com/facebook/facebook-sdk-swift/pull/137) ([RyogaK](https://github.com/RyogaK))

**Merged pull requests:**

- Set `swift` user agent suffix in FBSDKSettings [\#164](https://github.com/facebook/facebook-sdk-swift/pull/164) ([mcohnen](https://github.com/mcohnen))
- Update to Xcode 8.3 and Swift 3.1. [\#146](https://github.com/facebook/facebook-sdk-swift/pull/146) ([nlutsenko](https://github.com/nlutsenko))
- Improve ambiguous `logIn\(\)` function names in LoginManager. [\#97](https://github.com/facebook/facebook-sdk-swift/pull/97) ([nlutsenko](https://github.com/nlutsenko))
- Improve UIAlertController APIs in the SwiftCatalog sample app [\#92](https://github.com/facebook/facebook-sdk-swift/pull/92) ([mohshin-shah](https://github.com/mohshin-shah))
- Minor documentation fixes. [\#90](https://github.com/facebook/facebook-sdk-swift/pull/90) ([nlutsenko](https://github.com/nlutsenko))
- Update Facebook ObjC SDK dependency to 4.17. [\#88](https://github.com/facebook/facebook-sdk-swift/pull/88) ([nlutsenko](https://github.com/nlutsenko))
- Update Facebook ObjC SDK dependency to 4.16. [\#68](https://github.com/facebook/facebook-sdk-swift/pull/68) ([nlutsenko](https://github.com/nlutsenko))
- Re-enable Travis-CI CocoaPods linting for all frameworks. [\#61](https://github.com/facebook/facebook-sdk-swift/pull/61) ([nlutsenko](https://github.com/nlutsenko))
- Add Swift version badge to README. [\#60](https://github.com/facebook/facebook-sdk-swift/pull/60) ([nlutsenko](https://github.com/nlutsenko))

## [0.2.0](https://github.com/facebook/facebook-sdk-swift/tree/0.2.0) (2016-09-24)
[Full Changelog](https://github.com/facebook/facebook-sdk-swift/compare/0.1.1...0.2.0)

**Implemented enhancements:**

- Add Swift 3.0 support. [\#58](https://github.com/facebook/facebook-sdk-swift/pull/58) ([nlutsenko](https://github.com/nlutsenko))
- Add constructor for OpenGraphShareContent. [\#42](https://github.com/facebook/facebook-sdk-swift/pull/42) ([richardjrossiii](https://github.com/richardjrossiii))
- Add iOS 9.0+ method for opening URLs to ApplicationDelegate. [\#37](https://github.com/facebook/facebook-sdk-swift/pull/37) ([nlutsenko](https://github.com/nlutsenko))
- Refactor UserProfilePictureView into UserProfile.PictureView. [\#34](https://github.com/facebook/facebook-sdk-swift/pull/34) ([nlutsenko](https://github.com/nlutsenko))
- Add ability to fetch and refresh UserProfile. [\#33](https://github.com/facebook/facebook-sdk-swift/pull/33) ([nlutsenko](https://github.com/nlutsenko))
- Change type GraphRequestProtocol.apiVersion from String to concrete GraphAPIVersion. [\#32](https://github.com/facebook/facebook-sdk-swift/pull/32) ([nlutsenko](https://github.com/nlutsenko))

**Merged pull requests:**

- Update ObjC SDK dependency to 4.15. [\#46](https://github.com/facebook/facebook-sdk-swift/pull/46) ([nlutsenko](https://github.com/nlutsenko))
- Rename ApplicationDelegate to SDKApplicationDelegate to avoid name clashes. [\#36](https://github.com/facebook/facebook-sdk-swift/pull/36) ([nlutsenko](https://github.com/nlutsenko))
- Fix possessive typos in README [\#27](https://github.com/facebook/facebook-sdk-swift/pull/27) ([ashchan](https://github.com/ashchan))
- Mention local CocoaPods repo update in README instructions. [\#23](https://github.com/facebook/facebook-sdk-swift/pull/23) ([nlutsenko](https://github.com/nlutsenko))
- Clarify upgrade instructions for Carthage. [\#21](https://github.com/facebook/facebook-sdk-swift/pull/21) ([nlutsenko](https://github.com/nlutsenko))
- Clarify versioning instruction for CocoaPods installation. [\#15](https://github.com/facebook/facebook-sdk-swift/pull/15) ([nlutsenko](https://github.com/nlutsenko))
- Add missing `git submodule` command to README [\#13](https://github.com/facebook/facebook-sdk-swift/pull/13) ([hirschfl](https://github.com/hirschfl))
- Update README.md [\#11](https://github.com/facebook/facebook-sdk-swift/pull/11) ([SandroMachado](https://github.com/SandroMachado))

## [0.1.1](https://github.com/facebook/facebook-sdk-swift/tree/0.1.1) (2016-07-14)
[Full Changelog](https://github.com/facebook/facebook-sdk-swift/compare/0.1.0...0.1.1)

**Implemented enhancements:**

- Clarify Carthage and sub-project Getting Started instructions in README. [\#7](https://github.com/facebook/facebook-sdk-swift/pull/7) ([nlutsenko](https://github.com/nlutsenko))
- Fix running of SwiftCatalog sample on device. [\#5](https://github.com/facebook/facebook-sdk-swift/pull/5) ([nlutsenko](https://github.com/nlutsenko))

**Fixed bugs:**

- Cannot login with \[.PublishActions\] permissions [\#3](https://github.com/facebook/facebook-sdk-swift/issues/3)

**Merged pull requests:**

- Facebook Swift 0.1.1 [\#9](https://github.com/facebook/facebook-sdk-swift/pull/9) ([nlutsenko](https://github.com/nlutsenko))
- Remove unused LoginManager.DefaultAudience file. [\#8](https://github.com/facebook/facebook-sdk-swift/pull/8) ([nlutsenko](https://github.com/nlutsenko))
- Fix failing login with publish permissions when using LoginManager. [\#4](https://github.com/facebook/facebook-sdk-swift/pull/4) ([nlutsenko](https://github.com/nlutsenko))
- Update links and platforms badge in README. [\#2](https://github.com/facebook/facebook-sdk-swift/pull/2) ([nlutsenko](https://github.com/nlutsenko))
- Update CocoaPods settings and re-enable linting on Travis-CI. [\#1](https://github.com/facebook/facebook-sdk-swift/pull/1) ([nlutsenko](https://github.com/nlutsenko))

## [0.1.0](https://github.com/facebook/facebook-sdk-swift/tree/0.1.0) (2016-07-14)


\* *This Change Log was automatically generated by [github_changelog_generator](https://github.com/skywinder/Github-Changelog-Generator)*
