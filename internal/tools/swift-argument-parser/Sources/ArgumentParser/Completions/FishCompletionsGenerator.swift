struct FishCompletionsGenerator {
  static func generateCompletionScript(_ type: ParsableCommand.Type) -> String {
    let programName = type._commandName
    let helper = """
    function __fish_\(programName)_using_command
        set cmd (commandline -opc)
        if [ (count $cmd) -eq (count $argv) ]
            for i in (seq (count $argv))
                if [ $cmd[$i] != $argv[$i] ]
                    return 1
                end
            end
            return 0
        end
        return 1
    end

    """

    let completions = generateCompletions(commandChain: [programName], [type])
        .joined(separator: "\n")

    return helper + completions
  }

  static func generateCompletions(commandChain: [String], _ commands: [ParsableCommand.Type])
      -> [String]
  {
    let type = commands.last!
    let isRootCommand = commands.count == 1
    let programName = commandChain[0]
    var subcommands = type.configuration.subcommands

    if !subcommands.isEmpty {
      if isRootCommand {
        subcommands.append(HelpCommand.self)
      }
    }

    let prefix = "complete -c \(programName) -n '__fish_\(programName)_using_command"
    /// We ask each suggestion to produce 2 pieces of information
    /// - Parameters
    ///   - ancestors: a list of "ancestor" which must be present in the current shell buffer for
    ///                this suggetion to be considered. This could be a combination of (nested)
    ///                subcommands and flags.
    ///   - suggestion: text for the actual suggestion
    /// - Returns: A completion expression
    func complete(ancestors: [String], suggestion: String) -> String {
      "\(prefix) \(ancestors.joined(separator: " "))' \(suggestion)"
    }

    let subcommandCompletions = subcommands.map { (subcommand: ParsableCommand.Type) -> String in
      let escapedAbstract = subcommand.configuration.abstract.fishEscape()
      let suggestion = "-f -a '\(subcommand._commandName)' -d '\(escapedAbstract)'"
      return complete(ancestors: commandChain, suggestion: suggestion)
    }

    let argumentCompletions = ArgumentSet(type)
      .flatMap { $0.argumentSegments(commandChain) }
      .map { complete(ancestors: $0, suggestion: $1) }

    let completionsFromSubcommands = subcommands.flatMap { subcommand in
      generateCompletions(commandChain: commandChain + [subcommand._commandName], [subcommand])
    }

    return argumentCompletions + subcommandCompletions + completionsFromSubcommands
  }
}

extension String {
  fileprivate func fishEscape() -> String {
    self.replacingOccurrences(of: "'", with: #"\'"#)
  }
}

extension Name {
  fileprivate var asFishSuggestion: String {
    switch self {
    case .long(let longName):
      return "-l \(longName)"
    case .short(let shortName):
      return "-s \(shortName)"
    case .longWithSingleDash(let dashedName):
      return "-o \(dashedName)"
    }
  }

  fileprivate var asFormattedFlag: String {
    switch self {
    case .long(let longName):
      return "--\(longName)"
    case .short(let shortName):
      return "-\(shortName)"
    case .longWithSingleDash(let dashedName):
      return "-\(dashedName)"
    }
  }
}

extension ArgumentDefinition {
  fileprivate func argumentSegments(_ commandChain: [String]) -> [([String], String)] {
    var results = [([String], String)]()
    var formattedFlags = [String]()
    var flags = [String]()
    switch self.kind {
    case .positional:
      break
    case .named(let names):
      flags = names.map { $0.asFishSuggestion }
      formattedFlags = names.map { $0.asFormattedFlag }
      if !flags.isEmpty {
        // add these flags to suggestions
        var suggestion = "-f\(isNullary ? "" : " -r") \(flags.joined(separator: " "))"
        if let abstract = help.help?.abstract, !abstract.isEmpty {
          suggestion += " -d '\(abstract.fishEscape())'"
        }

        results.append((commandChain, suggestion))
      }
    }

    if isNullary {
      return results
    }

    // each flag alternative gets its own completion suggestion
    for flag in formattedFlags {
      let ancestors = commandChain + [flag]
      switch self.completion.kind {
      case .default:
        break
      case .list(let list):
        results.append((ancestors, "-f -k -a '\(list.joined(separator: " "))'"))
      case .file(let extensions):
        let pattern = "*.{\(extensions.joined(separator: ","))}"
        results.append((ancestors, "-f -a '(for i in \(pattern); echo $i;end)'"))
      case .directory:
        results.append((ancestors, "-f -a '(__fish_complete_directories)'"))
      case .shellCommand(let shellCommand):
        results.append((ancestors, "-f -a '(\(shellCommand))'"))
      case .custom:
        let program = commandChain[0]
        let subcommands = commandChain.dropFirst().joined(separator: " ")
        let suggestion = "-f -a '(command \(program) ---completion \(subcommands) -- --custom (commandline -opc)[1..-1])'"
        results.append((ancestors, suggestion))
      }
    }

    return results
  }
}
