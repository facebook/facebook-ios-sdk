---
oncalls: ['sdk']
---

# Public API Design — Dual Swift/ObjC Interface Pattern

The SDK is migrating from Objective-C to Swift. New public APIs that involve
Swift-only types (enums with associated values, `Result`, structs) must follow
the **dual-interface pattern** established by `LoginManager.logIn()`:

1. A **Swift-preferred** method marked `@nonobjc`, using Swift-native types
2. An **ObjC-compatible** method marked `@available(swift, obsoleted: 0.1)` and
   `@objc(selectorName:)`, using ObjC-bridgeable types (`(Type?, Error?) -> Void`)
3. Both delegate to a **shared private implementation**

## Example (from LoginManager)

```swift
// MARK: - Swift API (preferred)

@nonobjc
public func logIn(
  viewController: UIViewController? = nil,
  configuration: LoginConfiguration?,
  completion: @escaping LoginResultBlock  // Swift-only LoginResult enum
) {
  commonLogIn(/* ... */)
}

// MARK: - ObjC API (legacy-compatible)

@available(swift, obsoleted: 0.1)
@objc(logInFromViewController:configuration:completion:)
public func logIn(
  from viewController: UIViewController?,
  configuration: LoginConfiguration?,
  completion: @escaping (LoginManagerLoginResult?, Error?) -> Void
) {
  commonLogIn(/* ... */)
}

// MARK: - Shared Implementation

private func commonLogIn(/* ... */) {
  // Core logic here
}
```

Reference: `FBSDKLoginKit/FBSDKLoginKit/LoginManager.swift:128-199`

## When to Use This Pattern

- The method returns or accepts Swift-only types
- The method is `public` and part of the SDK's external API surface
- The type is already `@objc`-annotated (like `LoginManager`)

## When NOT Needed

- Internal types (not part of public API)
- Types that are naturally ObjC-compatible (`@objc` enums with `Int` raw values,
  `NSObject` subclasses)
- Types already documented as Swift-only in `Package.swift`

## Key Annotations

| Annotation | Purpose |
|-----------|---------|
| `@nonobjc` | Hides the method from ObjC callers |
| `@available(swift, obsoleted: 0.1)` | Hides the method from Swift callers |
| `@objc(selectorName:)` | Exposes the method to ObjC with a specific selector |
