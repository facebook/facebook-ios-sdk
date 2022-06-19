// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import Foundation

protocol CommandLineString {
    var commandLineString: String { get }
}

extension String: CommandLineString {
    var commandLineString: String { self }
}

struct CommandLine: CommandLineString {
    let command: Command
    let action: Action?
    let options: [Option]
    let arguments: [Argument]
    let environmentVariables: [EnvironmentVariable]

    var commandLineString: String {
        commandString +
            optionsLines +
            argumentsLine +
            variablesLine
    }

    private var commandString: String {
        [command, action?.commandLineString]
            .compactMap { $0 }
            .__commandLine_asLine
    }

    private var optionsLines: String {
        options
            .map(\.commandLineString)
            .joined()
    }

    private var argumentsLine: String {
        arguments
            .map(\.commandLineString)
            .__commandLine_asLine
            .__commandLine_indented
    }

    private var variablesLine: String {
        environmentVariables
            .map(\.commandLineString)
            .joined(separator: .__commandLine_space)
            .__commandLine_indented
    }
}

extension CommandLine {
    typealias Action = String
    typealias Argument = String
    typealias Command = String

    struct Option: CommandLineString {
        let name: String
        let arguments: [Argument]

        init(name: String, arguments: [Argument] = []) {
            self.name = name
            self.arguments = arguments
                .map { argument in
                    let containsWhitespace = argument.unicodeScalars
                        .contains {
                            CharacterSet.whitespacesAndNewlines.contains($0)
                        }
                    return containsWhitespace ? "\"\(argument)\"" : argument
                }
        }

        var commandLineString: String {
            ([name] + arguments.map(\.commandLineString))
                .__commandLine_asLine
                .__commandLine_indented
        }
    }

    struct EnvironmentVariable: CommandLineString {
        let name: String
        let value: String?

        var commandLineString: String {
            name + "=" + (value ?? "")
        }
    }
}

extension String {
    private static let __commandLine_indentation = "\t"
    private static let __commandLine_end = "\\\n"
    static let __commandLine_space = " "

    var __commandLine_indented: String {
        Self.__commandLine_indentation + self
    }

    var __commandLine_wrapped: String {
        self + Self.__commandLine_end
    }
}

extension Array where Element == String {
    var __commandLine_asLine: String {
        joined(separator: .__commandLine_space)
            .__commandLine_wrapped
    }
}
