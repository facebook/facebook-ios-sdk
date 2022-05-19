# CHANGELOG

<!-- 
Add new items at the end of the relevant section under **Unreleased**.
-->

This project follows semantic versioning. While still in major version `0`,
source-stability is only guaranteed within minor versions (e.g. between
`0.0.3` and `0.0.4`). If you want to guard against potentially source-breaking
package updates, you can specify your package dependency using
`.upToNextMinor(from: "0.3.0")` as the requirement.

## [Unreleased]

*No changes yet.*

---

## [0.3.1] - 2020-09-02

### Fixes

- An option or flag can now declare a name with both single- and double-
  dash prefixes, such as `-my-flag` and `--my-flag`. Specify both names in the
  `name` parameter when declaring your property:
  
  ```swift
  @Flag(name: [.long, .customLong("my-flag", withSingleDash: true)])
  var myFlag = false
  ```

- Parsing performance improvements.

---

## [0.3.0] - 2020-08-15

### Additions

- Shell completions scripts are now available for Fish.

### Changes

- Array properties without a default value are now treated as required for the
  user of a command-line tool. In previous versions of the library, these
  properties defaulted to an empty array; a deprecation was introduced for this
  behavior in version 0.2.0.

  *Migration:* Specify an empty array as the default value for properties that
  should not require user input:

  ```swift
  // old
  @Option var names: [String]
  // new
  @Option var names: [String] = []
  ```

The 0.3.0 release includes contributions from [dduan], [MPLew-is], 
[natecook1000], and [thomasvl]. Thank you!

## [0.2.2] - 2020-08-05

### Fixes

- Zsh completion scripts have improved documentation and better support
  multi-word completion strings, escaped characters, non-standard executable
  locations, and empty help strings.

The 0.2.2 release includes contributions from [interstateone], 
[miguelangel-dev], [natecook1000], [stuartcarnie], and [Wevah]. Thank you!

## [0.2.1] - 2020-07-30

### Additions

- You can now generate Bash and Zsh shell completion scripts for commands, 
  either by using the `--generate-completion-script` flag when running a 
  command, or by calling the static `completionScript(for:)` method on a root 
  `ParsableCommand` type. See the [guide to completion scripts][comp-guide] for 
  information on customizing and installing the completion script for your 
  command.

### Fixes

- Property wrappers without parameters can now be written without parentheses
  — e.g. `@Flag var verbose = false`.
- When displaying default values for array properties, the help screen now 
  correctly uses the element type's `ExpressibleByArgument` conformance to 
  generate the description.
- Running a project that defines a command as its own subcommand now fails with
  a useful error message.

The 0.2.1 release includes contributions from [natecook1000], [NicFontana],
[schlagelk], [sharplet], and [Wevah]. Thank you!

[comp-guide]: https://github.com/apple/swift-argument-parser/blob/master/Documentation/07%20Completion%20Scripts.md

## [0.2.0] - 2020-06-23

### Additions

- You can now specify default values for array properties of parsable types.
  The default values are overridden if the user provides at least one value
  as part of the command-line arguments.

### Changes

- This release of `swift-argument-parser` requires Swift 5.2.
- Default values for all properties are now written using default initialization
  syntax, including some values that were previously implicit, such as empty
  arrays and `false` for Boolean flags.
  
  *Migration:* Specify default values using typical Swift default value syntax
  to remove the deprecation warnings:
  
  ```swift
  // old
  @Flag var verbose: Bool
  // new
  @Flag var verbose = false
  ```
  
  **_Important:_** There is a semantic change for flags with inversions that do
  not have a default value. In previous releases, these flags had a default
  value of `false`; starting in 0.2.0, these flags will have no default, and
  will therefore be required by the user. Specify a default value of `false` to
  retain the old behavior.

### Fixes

- Options with multiple names now consistently show the first-declared name
  in usage and help screens.
- Default subcommands are indicated in the help screen.
- User errors with options are now shown before positional argument errors,
  eliminating some false negative reports.
- CMake compatibility fixes.

The 0.2.0 release includes contributions from [artemnovichkov], [compnerd], 
[ibrahimoktay], [john-mueller], [MPLew-is], [natecook1000], and [owenv]. 
Thank you!

## [0.1.0] - 2020-06-03

### Additions

- Error messages and help screens now include information about how to request
  more help.
- CMake builds now support installation.

### Changes

- The `static func main()` method on `ParsableCommand` no longer returns
  `Never`. This allows `ParsableCommand` types to be designated as the entry
  point for a Swift executable by using the `@main` attribute.
  
  *Migration:* For most uses, this change is source compatible. If you have
  used `main()` where a `() -> Never` function is explicitly required, you'll
  need to change your usage or capture the method in another function.

- `Optional` no longer conforms to `ExpressibleByArgument`, to avoid some
  property declarations that don't make sense. 

  *Migration:* This is source-compatible for all property declarations, with
  deprecations for optional properties that define an explicit default. If
  you're using optional values where an `ExpressibleByArgument` type is
  expected, such as a generic function, you will need to change your usage
  or provide an explicit override.

- `ParsableCommand`'s `run()` method requirement is now a `mutating` method,
  allowing mutations to a command's properties, such as sorting an array of
  arguments, without additional copying.
  
  *Migration:* No changes are required for commands that are executed through
  the `main()` method. If you manually parse a command and then call its
  `run()` method, you may need to change the command from a constant to a
  variable.

### Removals

- The `@Flag` initializers that were deprecated in version 0.0.6 are now
  marked as unavailable.

### Fixes

- `@Option` properties of an optional type that use a `transform` closure now
  correctly indicate their optionality in the usage string.
- Correct wrapping and indentation are maintained for abstracts and discussions 
  with short lines.
- Empty abstracts no longer add extra blank lines to the help screen.
- Help requests are still honored even when a parsed command fails validation.
- The `--` terminator isn't consumed when parsing a command, so that it can be
  parsed as a value when a subcommand includes an `.unconditionalRemaining`
  argument array.
- CMake builds work correctly again.

The 0.1.0 release includes contributions from [aleksey-mashanov], [BradLarson],
[compnerd], [erica], [ibrahimoktay], and [natecook1000]. Thank you!

## [0.0.6] - 2020-05-14

### Additions

- Command definition validation now checks for name collisions between options
  and flags.
- `ValidationError.message` is now publicly accessible.
- Added an `EnumerableFlag` protocol for `CaseIterable` types that are used to
  provide the names for flags. When declaring conformance to `EnumerableFlag`,
  you can override the name specification and help text for individual flags.
  See [#65] for more detail.
- When a command that requires arguments is called with no arguments at all, 
  the error message includes the full help text instead of the short usage
  string. This is intended to provide a better experience for first-time users.
- Added a `helpMessage()` method for generating the help text for a command
  or subcommand.

### Deprecations

- `@Flag` properties that use `CaseIterable`/`String` types as their values
  are deprecated, and the related `@Flag` initializers will be removed 
  in a future version. 
  
  *Migration:* Add `EnumerableFlag` conformance to the type of these kinds of
  `@Flag` properties.

### Fixes

- Errors thrown while parsing in a `transform` closure are printed correclty
  instead of a general `Invalid state` error.
- Improvements to the guides and in the error message when attempting to access
  a value from an argument/option/flag definition.
- Fixed issues in the CMake and Windows build configurations.
- You can now use an `=` to join a value with an option's short name when calling
  a command. This previously only worked for long names.

The 0.0.6 release includes contributions from [compnerd], [john-mueller], 
[natecook1000], [owenv], [rjstelling], and [toddthomas]. Thank you!

## [0.0.5] - 2020-04-15

### Additions

- You can now specify a version string in a `ParsableCommand`'s configuration.
  The generated tool will then automatically respond to a `--version` flag.
- Command definitions are now validated at runtime in debug mode, to check
  issues that can't be detected during compilation.

### Fixes

- Deprecation warnings during compilation on Linux have been removed.
- The `validate()` method is now called on each command in the matched command
  stack, instead of only the last command in the stack.

The 0.0.5 release includes contributions from [kennyyork], [natecook1000],
[sgl0v], and [YuAo]. Thank you!

## [0.0.4] - 2020-03-23

### Fixes

- Removed usage of 5.2-only syntax.

## [0.0.3] - 2020-03-22

### Additions

- You can specify the `.unconditionalRemaining` parsing strategy for arrays of
  positional arguments to accept dash-prefixed input, like
  `example --one two -three`.
- You can now provide a default value for a positional argument.
- You can now customize the display of default values in the extended help for
  an `ExpressibleByArgument` type.
- You can call the static `exitCode(for:)` method on any command to retrieve the
  exit code for a given error.

### Fixes

- Supporting targets are now prefixed to prevent conflicts with other libraries.
- The extension providing `init?(argument:)` to `RawRepresentable` types is now
  properly constrained.
- The parser no longer treats passing the same exclusive flag more than once as
  an error.
- `ParsableArguments` types that are declared as `@OptionGroup` properties on
  commands can now also be declared on subcommands. Previosuly, the parent 
  command's declaration would prevent subcommands from seeing the user-supplied 
  arguments.
- Default values are rendered correctly for properties with `Optional` types.
- The output of help requests is now printed during the "exit" phase of execution, 
  instead of during the "run" phase.
- Usage strings now correctly show that optional positional arguments aren't 
  required.
- Extended help now omits extra line breaks when displaying arguments or commands
  with long names that don't provide help text.

The 0.0.3 release includes contributions from [compnerd], [elliottwilliams],
[glessard], [griffin-stewie], [iainsmith], [Lantua], [miguelangel-dev],
[natecook1000], [sjavora], and [YuAo]. Thank you!

## [0.0.2] - 2020-03-06

### Additions

- The `EX_USAGE` exit code is now used for validation errors.
- The parser provides near-miss suggestions when a user provides an unknown
  option.
- `ArgumentParser` now builds on Windows.
- You can throw an `ExitCode` error to exit without printing any output.
- You can now create optional Boolean flags with inversions that default to 
  `nil`:
  ```swift
  @Flag(inversion: .prefixedNo) var takeMyShot: Bool?
  ```
- You can now specify exclusivity for case-iterable flags and for Boolean flags
  with inversions.

### Fixes

- Cleaned up a wide variety of documentation typos and shortcomings.
- Improved different kinds of error messages:
  - Duplicate exclusive flags now show the duplicated arguments.
  - Subcommand validation errors print the correct usage string.
- In the help screen:
  - Removed the extra space before the default value for arguments without
    descriptions.
  - Removed the default value note when the default value is an empty string.
  - Default values are now shown for Boolean options.
  - Case-iterable flags are now grouped correctly.
  - Case-iterable flags with default values now show the default value.
  - Arguments from parent commands that are included via `@OptionGroup` in 
    subcommands are no longer duplicated.
- Case-iterable flags created with the `.chooseFirst` exclusivity parameter now 
  correctly ignore additional flags.

The 0.0.2 release includes contributions from [AliSoftware], [buttaface], 
[compnerd], [dduan], [glessard], [griffin-stewie], [IngmarStein], 
[jonathanpenn], [klaaspieter], [natecook1000], [Sajjon], [sjavora], 
[Wildchild9], and [zntfdr]. Thank you!

## [0.0.1] - 2020-02-27

- `ArgumentParser` initial release.

---

This changelog's format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

<!-- Link references for releases -->

[Unreleased]: https://github.com/apple/swift-argument-parser/compare/0.3.1...HEAD
[0.3.1]: https://github.com/apple/swift-argument-parser/compare/0.3.0...0.3.1
[0.3.0]: https://github.com/apple/swift-argument-parser/compare/0.2.2...0.3.0
[0.2.2]: https://github.com/apple/swift-argument-parser/compare/0.2.1...0.2.2
[0.2.1]: https://github.com/apple/swift-argument-parser/compare/0.2.0...0.2.1
[0.2.0]: https://github.com/apple/swift-argument-parser/compare/0.1.0...0.2.0
[0.1.0]: https://github.com/apple/swift-argument-parser/compare/0.0.6...0.1.0
[0.0.6]: https://github.com/apple/swift-argument-parser/compare/0.0.5...0.0.6
[0.0.5]: https://github.com/apple/swift-argument-parser/compare/0.0.4...0.0.5
[0.0.4]: https://github.com/apple/swift-argument-parser/compare/0.0.3...0.0.4
[0.0.3]: https://github.com/apple/swift-argument-parser/compare/0.0.2...0.0.3
[0.0.2]: https://github.com/apple/swift-argument-parser/compare/0.0.1...0.0.2
[0.0.1]: https://github.com/apple/swift-argument-parser/releases/tag/0.0.1

<!-- Link references for pull requests -->

[#65]: https://github.com/apple/swift-argument-parser/pull/65

<!-- Link references for contributors -->

[aleksey-mashanov]: https://github.com/apple/swift-argument-parser/commits?author=aleksey-mashanov
[AliSoftware]: https://github.com/apple/swift-argument-parser/commits?author=AliSoftware
[artemnovichkov]: https://github.com/apple/swift-argument-parser/commits?author=artemnovichkov
[BradLarson]: https://github.com/apple/swift-argument-parser/commits?author=BradLarson
[buttaface]: https://github.com/apple/swift-argument-parser/commits?author=buttaface
[compnerd]: https://github.com/apple/swift-argument-parser/commits?author=compnerd
[dduan]: https://github.com/apple/swift-argument-parser/commits?author=dduan
[elliottwilliams]: https://github.com/apple/swift-argument-parser/commits?author=elliottwilliams
[erica]: https://github.com/apple/swift-argument-parser/commits?author=erica
[glessard]: https://github.com/apple/swift-argument-parser/commits?author=glessard
[griffin-stewie]: https://github.com/apple/swift-argument-parser/commits?author=griffin-stewie
[iainsmith]: https://github.com/apple/swift-argument-parser/commits?author=iainsmith
[ibrahimoktay]: https://github.com/apple/swift-argument-parser/commits?author=ibrahimoktay
[IngmarStein]: https://github.com/apple/swift-argument-parser/commits?author=IngmarStein
[interstateone]: https://github.com/apple/swift-argument-parser/commits?author=interstateone
[john-mueller]: https://github.com/apple/swift-argument-parser/commits?author=john-mueller
[jonathanpenn]: https://github.com/apple/swift-argument-parser/commits?author=jonathanpenn
[kennyyork]: https://github.com/apple/swift-argument-parser/commits?author=kennyyork
[klaaspieter]: https://github.com/apple/swift-argument-parser/commits?author=klaaspieter
[Lantua]: https://github.com/apple/swift-argument-parser/commits?author=Lantua
[miguelangel-dev]: https://github.com/apple/swift-argument-parser/commits?author=miguelangel-dev
[MPLew-is]: https://github.com/apple/swift-argument-parser/commits?author=MPLew-is
[natecook1000]: https://github.com/apple/swift-argument-parser/commits?author=natecook1000
[NicFontana]: https://github.com/apple/swift-argument-parser/commits?author=NicFontana
[owenv]: https://github.com/apple/swift-argument-parser/commits?author=owenv
[rjstelling]: https://github.com/apple/swift-argument-parser/commits?author=rjstelling
[Sajjon]: https://github.com/apple/swift-argument-parser/commits?author=Sajjon
[schlagelk]: https://github.com/apple/swift-argument-parser/commits?author=schlagelk
[sgl0v]: https://github.com/apple/swift-argument-parser/commits?author=sgl0v
[sharplet]: https://github.com/apple/swift-argument-parser/commits?author=sharplet
[sjavora]: https://github.com/apple/swift-argument-parser/commits?author=sjavora
[stuartcarnie]: https://github.com/apple/swift-argument-parser/commits?author=stuartcarnie
[thomasvl]: https://github.com/apple/swift-argument-parser/commits?author=thomasvl
[toddthomas]: https://github.com/apple/swift-argument-parser/commits?author=toddthomas
[Wevah]: https://github.com/apple/swift-argument-parser/commits?author=Wevah
[Wildchild9]: https://github.com/apple/swift-argument-parser/commits?author=Wildchild9
[YuAo]: https://github.com/apple/swift-argument-parser/commits?author=YuAo
[zntfdr]: https://github.com/apple/swift-argument-parser/commits?author=zntfdr
