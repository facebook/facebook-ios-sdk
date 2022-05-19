//===----------------------------------------------------------*- swift -*-===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

struct BashCompletionsGenerator {
  /// Generates a Bash completion script for the given command.
  static func generateCompletionScript(_ type: ParsableCommand.Type) -> String {
    // TODO: Add a check to see if the command is installed where we expect?
    let initialFunctionName = [type].completionFunctionName()
    return """
    #!/bin/bash

    \(generateCompletionFunction([type]))

    complete -F \(initialFunctionName) \(type._commandName)
    """
  }

  /// Generates a Bash completion function for the last command in the given list.
  fileprivate static func generateCompletionFunction(_ commands: [ParsableCommand.Type]) -> String {
    let type = commands.last!
    let functionName = commands.completionFunctionName()
    
    // The root command gets a different treatment for the parsing index.
    let isRootCommand = commands.count == 1
    let dollarOne = isRootCommand ? "1" : "$1"
    let subcommandArgument = isRootCommand ? "2" : "$(($1+1))"
  
    // Include 'help' in the list of subcommands for the root command.
    var subcommands = type.configuration.subcommands
    if !subcommands.isEmpty && isRootCommand {
      subcommands.append(HelpCommand.self)
    }

    // Generate the words that are available at the "top level" of this
    // command — these are the dash-prefixed names of options and flags as well
    // as all the subcommand names.
    let completionWords = generateArgumentWords(commands)
      + subcommands.map { $0._commandName }
      // FIXME: These shouldn't be hard-coded, since they're overridable
      + ["-h", "--help"]
    
    // Generate additional top-level completions — these are completion lists
    // or custom function-based word lists from positional arguments.
    let additionalCompletions = generateArgumentCompletions(commands)
    
    // Start building the resulting function code.
    var result = "\(functionName)() {\n"

    // The function that represents the root command has some additional setup
    // that other command functions don't need.
    if isRootCommand {
      result += """
        cur="${COMP_WORDS[COMP_CWORD]}"
        prev="${COMP_WORDS[COMP_CWORD-1]}"
        COMPREPLY=()

        """.indentingEachLine(by: 4)
    }

    // Start by declaring a local var for the top-level completions.
    // Return immediately if the completion matching hasn't moved further.
    result += "    opts=\"\(completionWords.joined(separator: " "))\"\n"
    for line in additionalCompletions {
      result += "    opts=\"$opts \(line)\"\n"
    }

    result += """
        if [[ $COMP_CWORD == "\(dollarOne)" ]]; then
            COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
            return
        fi

    """

    // Generate the case pattern-matching statements for option values.
    // If there aren't any, skip the case block altogether.
    let optionHandlers = generateOptionHandlers(commands)
    if !optionHandlers.isEmpty {
      result += """
      case $prev in
      \(optionHandlers.indentingEachLine(by: 4))
      esac
      """.indentingEachLine(by: 4) + "\n"
    }

    // Build out completions for the subcommands.
    if !subcommands.isEmpty {
      // Subcommands have their own case statement that delegates out to
      // the subcommand completion functions.
      result += "    case ${COMP_WORDS[\(dollarOne)]} in\n"
      for subcommand in subcommands {
        result += """
          (\(subcommand._commandName))
              \(functionName)_\(subcommand._commandName) \(subcommandArgument)
              return
              ;;
          
          """
          .indentingEachLine(by: 8)
      }
      result += "    esac\n"
    }
    
    // Finish off the function.
    result += """
        COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
    }

    """

    return result +
      subcommands
        .map { generateCompletionFunction(commands + [$0]) }
        .joined()
  }

  /// Returns the option and flag names that can be top-level completions.
  fileprivate static func generateArgumentWords(_ commands: [ParsableCommand.Type]) -> [String] {
    ArgumentSet(commands.last!)
      .flatMap { $0.bashCompletionWords() }
  }

  /// Returns additional top-level completions from positional arguments.
  ///
  /// These consist of completions that are defined as `.list` or `.custom`.
  fileprivate static func generateArgumentCompletions(_ commands: [ParsableCommand.Type]) -> [String] {
    ArgumentSet(commands.last!)
      .compactMap { arg -> String? in
        guard arg.isPositional else { return nil }

        switch arg.completion.kind {
        case .default, .file, .directory:
          return nil
        case .list(let list):
          return list.joined(separator: " ")
        case .shellCommand(let command):
          return "$(\(command))"
        case .custom:
          // Generate a call back into the command to retrieve a completions list
          let commandName = commands.first!._commandName
          let subcommandNames = commands.dropFirst().map { $0._commandName }.joined(separator: " ")
          // TODO: Make this work for @Arguments
          let argumentName = arg.preferredNameForSynopsis?.synopsisString
                ?? arg.help.keys.first?.rawValue ?? "---"
          
          return """
            $(\(commandName) ---completion \(subcommandNames) -- \(argumentName) "$COMP_WORDS")
            """
        }
      }
  }

  /// Returns the case-matching statements for supplying completions after an option or flag.
  fileprivate static func generateOptionHandlers(_ commands: [ParsableCommand.Type]) -> String {
    ArgumentSet(commands.last!)
      .compactMap { arg -> String? in
        let words = arg.bashCompletionWords()
        if words.isEmpty { return nil }

        // Flags don't take a value, so we don't provide follow-on completions.
        if arg.isNullary { return nil }
        
        return """
        \(arg.bashCompletionWords().joined(separator: "|")))
        \(arg.bashValueCompletion(commands).indentingEachLine(by: 4))
            return
        ;;
        """
      }
      .joined(separator: "\n")
  }
}

extension ArgumentDefinition {
  /// Returns the different completion names for this argument.
  fileprivate func bashCompletionWords() -> [String] {
    names.map { $0.synopsisString }
  }

  /// Returns the bash completions that can follow this argument's `--name`.
  fileprivate func bashValueCompletion(_ commands: [ParsableCommand.Type]) -> String {
    switch completion.kind {
    case .default:
      return ""
      
    case .file(_):
      // TODO: Use '_filedir' when available
      // FIXME: Use the extensions array
      return #"COMPREPLY=( $(compgen -f -- "$cur") )"#

    case .directory:
      return #"COMPREPLY=( $(compgen -d -- "$cur") )"#
      
    case .list(let list):
      return #"COMPREPLY=( $(compgen -W "\#(list.joined(separator: " "))" -- "$cur") )"#
    
    case .shellCommand(let command):
      return "COMPREPLY=( $(\(command)) )"
        
    case .custom:
      // Generate a call back into the command to retrieve a completions list
      let commandName = commands.first!._commandName      
      return #"COMPREPLY=( $(compgen -W "$(\#(commandName) \#(customCompletionCall(commands)) "$COMP_WORDS")" -- "$cur") )"#
    }
  }
}
