# Facebook SDK in Swift (Beta)

[![Platforms](https://img.shields.io/cocoapods/p/FacebookCore.svg)]()
[![Swift Version](https://img.shields.io/badge/Swift-3.0.x-orange.svg)]()
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)]()

[![Build Status](https://img.shields.io/travis/facebook/facebook-sdk-swift/master.svg?style=flat)](https://travis-ci.org/facebook/facebook-sdk-swift)

Swift-taylored experience to integrate your app with Facebook. Including:

- [Facebook Login](https://developers.facebook.com/docs/swift/login) - Authenticate people with their Facebook credentials.
- [Share and Send Dialogs](https://developers.facebook.com/docs/swift/sharing) - Enable sharing content from your app to Facebook.
- [App Events](https://developers.facebook.com/docs/swift/appevents) - Understand your audience and the performance of your app.
- [Graph API](https://developers.facebook.com/docs/swift/graph) - Read and write directly to Facebook social graph.

## Getting Started

- **[CocoaPods](https://cocoapods.org)**
    - Make sure you are running the latest version of CocoaPods by running:
      ```bash
      gem install cocoapods
      # (or if the above fails)
      sudo gem install cocoapods
      ```
      _We support any version of CocoaPods 1.0.1 or later._

    - Update your local specs repo by running:
      ```bash
      pod repo update
      ```
      _This step is optional, if you updated the specs repo recently._

    - Add the following lines to your Podfile:
    
      ```ruby
      pod 'FacebookCore'
      pod 'FacebookLogin'
      pod 'FacebookShare'
      ```
    - Run `pod install`
    - You are all set!

 You may also exclude any of these dependencies, if you do not need the features of those parts of the SDK.
  
- **[Carthage](https://github.com/carthage/carthage)**

    - Make sure you are running the latest version of Carthage by running:
      ```bash
      brew update
      brew upgrade carthage
      ```
      _We recommend using Carthage version 0.17.2 or later._
	  
    - Add the following line to your Cartfile:
      ```
      github "facebook/Facebook-SDK-Swift"
      ```

    - Run `carthage update`.  
      _This will fetch dependencies into a `Carthage/Checkouts` folder, then build each one._
    - On your application targets' `General` settings tab, in the `Linked Frameworks and Libraries` section:
        - Drag & drop the following frameworks from `Carthage/Build` folder on disk:
        - At a minimum:
            - `FacebookCore.framework`
            - `FBSDKCoreKit.framework`
            - `Bolts.framework`
        - To use Login with Facebook:
            - `FacebookLogin.framework`
            - `FacebookCore.framework` (and its dependencies)
        - To use Share and Send Dialogs
            - `FacebookShare.framework`
            - `FacebookCore.framework` (and its dependencies)
    - On your application targets' `Build Phases` tab:
        - Click `+` icon and choose `New Run Script Phase`.
        - Create a script with a shell of your choice (e.g. `/bin/sh`).
        - Add the following to the script area below the shell:
          ```
          /usr/local/bin/carthage copy-frameworks
          ```

        - Add the paths to the frameworks you want to use under `Input Files`, for example:
        
          ```
          $(SRCROOT)/Carthage/Build/iOS/FacebookCore.framework
          $(SRCROOT)/Carthage/Build/iOS/FBSDKCoreKit.framework
          $(SRCROOT)/Carthage/Build/iOS/Bolts.framework
          ```

- **Using Facebook SDK as a sub-project**

  While not recommended, it is entirely possible for you to build the Facebook SDK for Swift outside of any dependency management system. 
  
  Note that you will have to manage updating this solution (as well as the dependencies on the Facebook SDK for iOS) on your own.
  
  - Clone the repository.
  - Run the following command in the root directory of the repository: `git submodule update --init --recursive`
  - Add `FacebookSwift.xcodeproj` as a sub-project to your applications' project.
  - Add the `FacebookCore.framework`, `FacebookLogin.framework`, and `FacebookShare.framework` build products from the sub-project to your applications `Link Frameworks and Libraries` and `Embedded Binaries` sections.
  
  Don't forget to also embed/link `FBSDKCoreKit.framework`, `FBSDKLoginKit.framework`, `FBSDKShareKit.framework` and `Bolts.framework` too!
  
## Modules

The frameworks for the Facebook SDK in Swift are organized in the same way that the Facebook SDK for iOS is. 

They also currently depend upon the Facebook SDK for iOS, although this may change at some point in the future.

### FacebookCore

[![FacebookCore on CocoaPods](https://img.shields.io/cocoapods/v/FacebookCore.svg)](https://cocoapods.org/pods/FacebookCore)

Depends on `FBSDKCoreKit.framework` and `Bolts.framework`.

The following types are included, with enhancements for Swift:

- `AccessToken`
- `ApplicationDelegate`
- `AppEvents`

 A myriad of improvements, including type-safe built-in `AppEvent`s, an `AppEvent` struct, and more.
 
- `GraphRequest`

 You can now implement your own type-safe `GraphRequest`s, including native-typed results.
 
- `SDKSettings`

 Logging behaviors are now implemented as a type-safe set, based on Swift enums.
 
- `Permission`

 Are no longer stringly-typed (string-based), but separate types for read and write permissions (also includes a built-in permission list, which includes most common permissions by default).

### FacebookLogin

[![FacebookCore on CocoaPods](https://img.shields.io/cocoapods/v/FacebookLogin.svg)](https://cocoapods.org/pods/FacebookLogin)

Depends on `FacebookCore.framework` and `FBSDKLoginKit.framework`.

The following types are included, with enhancements for Swift:

- `LoginManager`

 Now uses the type-safe permissions from `FacebookCore`, and has constructors with `LoginBehavior` and `DefaultAudience`, instead of requiring manual setting of properties.
 
- `LoginButton`

 Can no longer change permissions after creation, helping to enforce using a single login button for a given set of permissions.
 Note that `LoginButton` is not intended to work with interface builder or storyboards at this time. We may re-address this in the future.
 
### FacebookShare

[![FacebookCore on CocoaPods](https://img.shields.io/cocoapods/v/FacebookShare.svg)](https://cocoapods.org/pods/FacebookShare)

Depends on `FacebookCore.framework` and `FBSDKShareKit.framework`.

The following types are included, with enhancements for Swift:

- `LinkShareContent`

 Now a struct, and has a proper initializer enforcing required properties.
 
- `OpenGraphShareContent`

 Now a struct, uses type-safe `OpenGraphPropertyName` and `OpenGraphPropertyValue`, as well as structs for `OpenGraphObject` and `OpenGraphAction`.
 
- `PhotoShareContent`

 Now a struct, and better type-safety for properties on it.
 
- `VideoShareContent`

 Now a struct, and better type-safety for properties on it.
  
- `GraphSharer` 

 Now a generic type, that can handle any type of content.
 
- `ShareDialog`

 Now a generic type, that can handle any type of content.
 
- `MessageDialog`

 Now a generic type, that can handle any type of content.
 
- `GameRequest` 

 Now a struct, contains proper type-safe enum for `Recipient`, `Result`.
 
- `GameRequest.Dialog`
- `AppGroupRequest.Dialog`
- `AppInvite`

 Now a struct, use a type-safe `Promotion` property, instead of separate `promotionCode` and `promotionText`.

- `AppInvite.Dialog`

## Give Feedback

Facebook SDK in Swift is still in beta, and we would love to hear your thoughts and feedback on it.

- **Have an idea or feature request?** [Open an issue](https://github.com/facebook/facebook-sdk-swift/issues/new). Tell us more about the feature or an idea and why you think it's relevant.
- **Have a bug to report?** [Open an issue](https://github.com/facebook/facebook-sdk-swift/issues/new). If possible, include the version of the SDK you are using, and any technical details.
- **Need help with your code?** Join [Facebook Developers Group](https://www.facebook.com/groups/fbdevelopers) on Facebook or ask questions on [Stack Overflow](https://facebook.stackoverflow.com).

## Contribute

All of Facebook SDK for Swift development happens on GitHub. 
Contributions make for good karma and we welcome new contributors with tremendous joy.
We encourage you also to read our [contributing guidelines](https://github.com/facebook/facebook-sdk-swift/blob/master/CONTRIBUTING.md) before submitting a Pull Request.

## LICENSE

See the [`LICENSE`](https://github.com/facebook/facebook-sdk-swift/blob/master/LICENSE) file.
