---
oncalls: ['sdk']
apply_to_path: '.*Tests.*\.swift'
---

# Testing Conventions

## Class Declaration
- All test classes **must** be `final`.

## Implicitly Unwrapped Optionals (IUOs)
- Test properties set in `setUp()` use implicitly unwrapped optionals.
- Wrap them in swiftlint disable/enable comments:
```swift
// swiftlint:disable implicitly_unwrapped_optional
var loginManager: LoginManager!
var settings: TestSettings!
// swiftlint:enable implicitly_unwrapped_optional
```

## setUp() and Dependency Injection
- `setUp()` must create all test doubles and inject dependencies via `setDependencies()`.
- Call `super.setUp()` first.

## Imports
- Use `@testable import` for the module under test.
- Import `TestTools` for shared test doubles.
- Imports must be sorted, with `@testable` imports first.

## Test Double Naming
- Pattern: `Test<RealType>` (e.g., `TestSettings`, `TestGraphRequestFactory`).
- Live in `<Module>Tests/Helpers/` or in the shared `TestTools` module.

## Sample Data
- Use `Sample*` factory types: `SampleAccessTokens`, `SampleError`, `SampleURLs`.

## Assertions on Interactions
- Test doubles use `captured*` properties to record interactions:
```swift
XCTAssertEqual(factory.capturedGraphPath, "/me")
XCTAssertTrue(delegate.capturedDidComplete)
```

## File Location
- Module-specific tests: `<Module>/<Module>Tests/`
- Module-specific helpers: `<Module>/<Module>Tests/Helpers/`
- Shared test doubles: `TestTools/TestTools/`
