---
oncalls: ['sdk']
---

# Facebook iOS SDK — Coding Rules

These constraints apply to every change. Violating them will break builds or reviews.

## Style

- 2-space indentation (no tabs), 120-char line length
- Trailing commas mandatory on multi-line collections
- Imports sorted; `@testable` imports first
- Classes must be `final` unless explicitly `open`
- Modifier order: `public override` (not `override public`)
- Max cyclomatic complexity: 11

## Copyright Header (every Swift/ObjC file)

```swift
/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */
```

## Naming

- Public types: clean names (`LoginManager`), ObjC name via `@objc(FBSDKLoginManager)`
- Internal types: underscore prefix (`_ErrorFactory`, `_BridgeAPI`)
- Protocols: `-ing`/`-Providing`/`-Creating` suffixes (`ErrorCreating`, `URLOpening`)
- Factory protocols: `*FactoryProtocol` (`GraphRequestFactoryProtocol`)
- SPM naming: `FBSDK` prefix = ObjC target, no prefix = Swift target
  (e.g., `FBSDKLoginKit` vs `FacebookLogin`)
- Extensions for splitting types: `Settings+AutoLogAppEvents.swift`
- Private constant namespacing: `private enum Keys { static let ... }`

## Dependency Properties

Properties in `ObjectDependencies` / `TypeDependencies` must be in **alphabetical
order** by name. Types must always be protocols, never concrete types.

## Public API — Dual Swift/ObjC Interfaces

New public methods using Swift-only types (`Result`, enums with associated values,
structs) require dual interfaces: `@nonobjc` Swift-preferred + `@available(swift,
obsoleted: 0.1) @objc` ObjC-compatible, both delegating to a shared `private`
implementation. See `.llms/skills/public-api-design.md` for the full pattern.

## Deployment Targets

| Target | Minimum iOS |
|--------|-------------|
| SDK modules (`FBSDKCoreKit`, `FBSDKLoginKit`, etc.) | 13.0 |
| Hackbook test app (`internal/testing/Hackbook`) | 12.0 |
| CoffeeShop test app (`internal/testing/CoffeeShop`) | 12.0 |

Do NOT use APIs newer than the target's minimum without `@available` checks.
In Hackbook specifically, avoid iOS 13+ APIs like `UIColor.label`,
`UIColor.secondaryLabel`, `monospacedSystemFont(ofSize:weight:)`, and iOS 14+
APIs like `defaultContentConfiguration()` / `contentConfiguration` — use
`textLabel` / `detailTextLabel` instead.

## Simulator Destinations

When building for iOS Simulator from the CLI, always query available
destinations first (`xcodebuild -scheme <Scheme> -showdestinations`) rather
than hardcoding device names. Device names change with each iOS/Xcode
generation (e.g., iOS 26 has `iPhone 17 Pro`, not `iPhone 16`).

## Build Settings

- Warnings are errors (`GCC_TREAT_WARNINGS_AS_ERRORS = YES`)
- `BUILD_LIBRARY_FOR_DISTRIBUTION = YES` — API stability required
- Use xcconfig files — never add settings directly to targets
- Swift 5.0, C++11, ARC enabled

## Module Dependency Boundaries

```
Basics (L0) → AEM (L1) → Core (L2) → Login / Share / Gaming (L3)
                                        Gaming also imports Share
```

| Source module | May import |
|---|---|
| `FBSDKCoreKit_Basics` | *(none)* |
| `FBAEMKit` | `FBSDKCoreKit_Basics` |
| `FBSDKCoreKit` | `FBSDKCoreKit_Basics`, `FBAEMKit` |
| `FBSDKLoginKit` | `FBSDKCoreKit`, `FBSDKCoreKit_Basics` |
| `FBSDKShareKit` | `FBSDKCoreKit`, `FBSDKCoreKit_Basics` |
| `FBSDKGamingServicesKit` | `FBSDKCoreKit`, `FBSDKCoreKit_Basics`, `FBSDKShareKit` |

Exception: `CoreKitConfigurator.swift` uses `@testable import FBAEMKit` for
composition-root wiring. System frameworks are always allowed.

## New Files

Use `./scripts/new-file.sh <Kit> <Path>` to scaffold source + test files. After:
run `./generate-projects.sh` and verify target membership in `project.yml` (both
Static and Dynamic targets; TV targets if cross-platform).

Before creating a new test double, check `TestTools/TestTools/` — shared doubles
like `TestSettings`, `TestGraphRequestFactory`, etc. already exist there.

## Do Not Modify

Never edit these files without explicit instruction:
- `Package.swift` binary checksums or remote URLs
- `.swiftformat`, `.swiftlint.yml` (tooling config)
- `build/` directory (generated artifacts)
- `*.xcframework` files (prebuilt binaries)

## Test Verification

After completing source changes, run `./scripts/test.sh <Kit>`. Changes to
`FBSDKCoreKit_Basics` or `FBSDKCoreKit` may break downstream — run
`./scripts/test.sh` (no args) for those. Fix failures before considering the
task done.

| Directory | Kit |
|-----------|-----|
| `FBSDKCoreKit_Basics/` | `BasicKit` |
| `FBAEMKit/` | `AEMKit` |
| `FBSDKCoreKit/` | `CoreKit` |
| `FBSDKLoginKit/` | `LoginKit` |
| `FBSDKShareKit/` | `ShareKit` |
| `FBSDKGamingServicesKit/` | `GamingKit` |
