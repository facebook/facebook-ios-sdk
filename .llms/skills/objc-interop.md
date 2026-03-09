---
oncalls: ['sdk']
apply_to_path: '.*\.(m|h)$'
---

# Objective-C Interop Conventions

## Header Imports — CocoaPods vs SPM

Gate header imports to support both CocoaPods and SPM builds:

```objc
#ifdef FBSDKCOCOAPODS
#import <FBSDKCoreKit/FBSDKCoreKit+Internal.h>
#else
#import "FBSDKCoreKit+Internal.h"
#endif
```

Always use `FBSDKCOCOAPODS` as the preprocessor macro for this gate.

## Public Headers

Public ObjC headers must be placed in the module's `include/` directory so they
are visible to SPM consumers.

## Naming

See `.llms/rules/llms.md` "Naming" for full conventions. Key point: the `FBSDK`
prefix is only used in the `@objc()` name, never in the Swift name.
