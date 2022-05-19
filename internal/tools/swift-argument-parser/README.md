# Swift Argument Parser

## Usage

Begin by declaring a type that defines the information
that you need to collect from the command line.
Decorate each stored property with one of `ArgumentParser`'s property wrappers,
declare conformance to `ParsableCommand`,
and implement your command's logic in the `run()` method.

```swift
import ArgumentParser

struct Repeat: ParsableCommand {
    @Flag(help: "Include a counter with each repetition.")
    var includeCounter = false

    @Option(name: .shortAndLong, help: "The number of times to repeat 'phrase'.")
    var count: Int?

    @Argument(help: "The phrase to repeat.")
    var phrase: String

    mutating func run() throws {
        let repeatCount = count ?? .max

        for i in 1...repeatCount {
            if includeCounter {
                print("\(i): \(phrase)")
            } else {
                print(phrase)
            }
        }
    }
}

Repeat.main()
```

You kick off execution by calling your type's static `main()` method.
The `ArgumentParser` library parses the command-line arguments,
instantiates your command type, and then either executes your `run()` method
or exits with a useful message.

`ArgumentParser` uses your properties' names and type information,
along with the details you provide using property wrappers,
to supply useful error messages and detailed help:

```
$ repeat hello --count 3
hello
hello
hello
$ repeat --count 3
Error: Missing expected argument 'phrase'.
Usage: repeat [--count <count>] [--include-counter] <phrase>
  See 'repeat --help' for more information.
$ repeat --help
USAGE: repeat [--count <count>] [--include-counter] <phrase>

ARGUMENTS:
  <phrase>                The phrase to repeat.

OPTIONS:
  --include-counter       Include a counter with each repetition.
  -c, --count <count>     The number of times to repeat 'phrase'.
  -h, --help              Show help for this command.
```

For more information and documentation about all supported options, see [the `Documentation` folder at the root of the repository](https://github.com/apple/swift-argument-parser/tree/master/Documentation).

## Examples

This repository includes a few examples of using the library:

- [`repeat`](Examples/repeat/main.swift) is the example shown above.
- [`roll`](Examples/roll/main.swift) is a simple utility implemented as a straight-line script.
- [`math`](Examples/math/main.swift) is an annotated example of using nested commands and subcommands.

You can also see examples of `ArgumentParser` adoption among Swift project tools:

- [`indexstore-db`](https://github.com/apple/indexstore-db/pull/72) is a simple utility with two commands.
- [`swift-format`](https://github.com/apple/swift-format/pull/154) uses some advanced features, like custom option values and hidden flags.

## Adding `ArgumentParser` as a Dependency

To use the `ArgumentParser` library in a SwiftPM project, 
add the following line to the dependencies in your `Package.swift` file:

```swift
.package(url: "https://github.com/apple/swift-argument-parser", from: "0.3.0"),
```

Because `ArgumentParser` is under active development,
source-stability is only guaranteed within minor versions (e.g. between `0.0.3` and `0.0.4`).
If you don't want potentially source-breaking package updates,
use this dependency specification instead:

```swift
.package(url: "https://github.com/apple/swift-argument-parser", .upToNextMinor(from: "0.3.0")),
```

Finally, include `"ArgumentParser"` as a dependency for your executable target:

```swift
let package = Package(
    // name, platforms, products, etc.
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.3.0"),
        // other dependencies
    ],
    targets: [
        .target(name: "<command-line-tool>", dependencies: [
            .product(name: "ArgumentParser", package: "swift-argument-parser"),
        ]),
        // other targets
    ]
)
```
