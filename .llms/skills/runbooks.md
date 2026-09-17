---
oncalls: ['sdk']
---

# Common-Task Runbooks

Step-by-step guides for multi-step workflows. Follow every step in order.

---

## Runbook A: Adding a New Public API Method

1. **Determine if dual interface is needed.** Does the method use Swift-only types
   (`Result`, enums with associated values, structs)? If yes → dual interface
   required. If the types are ObjC-compatible (classes, `NSObject` subclasses,
   primitives) → a single `@objc` method is sufficient.

2. **For dual interface:** follow the pattern in `.llms/skills/public-api-design.md`.

3. **For ObjC-only types:** a single `@objc` method is sufficient. No dual
   interface needed.

4. **Update `CHANGELOG.md`** — add an entry under the `[next]` section describing
   the new API.

---

## Runbook B: Adding a New Dependency to a Type

1. **Define a protocol** for the dependency. Use `-ing`/`-Providing`/`-Creating`
   suffix (e.g., `TokenRefreshing`, `DataProviding`, `RequestCreating`).
   Factory protocols use `*FactoryProtocol` (e.g., `GraphRequestFactoryProtocol`).

2. **Add the protocol property** to `ObjectDependencies` or `TypeDependencies` in
   the type's `DependentAsObject` / `DependentAsType` extension. Properties must be
   in **alphabetical order** by name.

3. **Wire the concrete implementation:**
   - **For types in CoreKit:** add wiring in `CoreKitConfigurator`
     (`FBSDKCoreKit/FBSDKCoreKit/Internal/Configuration/CoreKitConfigurator.swift`)
     using components from `CoreKitComponents`
     (`FBSDKCoreKit/FBSDKCoreKit/Internal/Configuration/CoreKitComponents.swift`).
   - **For types in other modules (Login, Share, Gaming):** wire via
     `defaultDependencies` in the type itself. See
     `FBSDKLoginKit/FBSDKLoginKit/LoginManager.swift:72-95` for the pattern.

4. **Create a test double** named `Test<Type>` in the module's
   `<Module>/<Module>Tests/Helpers/` directory.

5. **Update `setUp()`** in the relevant test file to inject the test double via
   `setDependencies()`.

6. **Run module tests:** `./scripts/test.sh <Kit>`

---

## Runbook C: Deprecating an API

1. **Add the deprecation annotation** to the old method or property:
   ```swift
   @available(
     *,
     deprecated,
     message: """
       This property is deprecated and will be removed in the next major release. \
       Use `newName` instead.
       """
   )
   ```

2. **Make the deprecated API delegate to the replacement** — no logic duplication.
   - For properties: deprecated computed property forwards to the new property.
   - For methods: deprecated method calls the replacement method.

   Reference: `FBSDKCoreKit/FBSDKCoreKit/Settings.swift:65-76`

3. **Run module tests:** `./scripts/test.sh <Kit>`
4. **Update `CHANGELOG.md`** — add a deprecation entry under the `[next]` section.
