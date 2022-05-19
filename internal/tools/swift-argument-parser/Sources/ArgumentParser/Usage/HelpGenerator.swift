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

internal struct HelpGenerator {
  static var helpIndent = 2
  static var labelColumnWidth = 26
  static var systemScreenWidth: Int {
    _screenWidthOverride ?? _terminalSize().width
  }
  
  internal static var _screenWidthOverride: Int? = nil
  
  struct Usage {
    var components: [String]
    
    func rendered(screenWidth: Int) -> String {
      components
        .joined(separator: "\n")
    }
  }
  
  struct Section {
    struct Element: Hashable {
      var label: String
      var abstract: String = ""
      var discussion: String = ""
      
      var paddedLabel: String {
        String(repeating: " ", count: HelpGenerator.helpIndent) + label
      }
      
      func rendered(screenWidth: Int) -> String {
        let paddedLabel = self.paddedLabel
        let wrappedAbstract = self.abstract
          .wrapped(to: screenWidth, wrappingIndent: HelpGenerator.labelColumnWidth)
        let wrappedDiscussion = self.discussion.isEmpty
          ? ""
          : self.discussion.wrapped(to: screenWidth, wrappingIndent: HelpGenerator.helpIndent * 4) + "\n"
        let renderedAbstract: String = {
          guard !abstract.isEmpty else { return "" }
          if paddedLabel.count < HelpGenerator.labelColumnWidth {
            // Render after padded label.
            return String(wrappedAbstract.dropFirst(paddedLabel.count))
          } else {
            // Render in a new line.
            return "\n" + wrappedAbstract
          }
        }()
        return paddedLabel
          + renderedAbstract + "\n"
          + wrappedDiscussion
      }
    }
    
    enum Header: CustomStringConvertible, Equatable {
      case positionalArguments
      case subcommands
      case options
      
      var description: String {
        switch self {
        case .positionalArguments:
          return "Arguments"
        case .subcommands:
          return "Subcommands"
        case .options:
          return "Options"
        }
      }
    }
    
    var header: Header
    var elements: [Element]
    var discussion: String = ""
    var isSubcommands: Bool = false
    
    func rendered(screenWidth: Int) -> String {
      guard !elements.isEmpty else { return "" }
      
      let renderedElements = elements.map { $0.rendered(screenWidth: screenWidth) }.joined()
      return "\(String(describing: header).uppercased()):\n"
        + renderedElements
    }
  }
  
  struct DiscussionSection {
    var title: String = ""
    var content: String
  }
  
  var commandStack: [ParsableCommand.Type]
  var abstract: String
  var usage: Usage
  var sections: [Section]
  var discussionSections: [DiscussionSection]
  
  init(commandStack: [ParsableCommand.Type]) {
    guard let currentCommand = commandStack.last else {
      fatalError()
    }
    
    let currentArgSet = ArgumentSet(currentCommand)
    self.commandStack = commandStack

    // Build the tool name and subcommand name from the command configuration
    var toolName = commandStack.map { $0._commandName }.joined(separator: " ")
    if let superName = commandStack.first!.configuration._superCommandName {
      toolName = "\(superName) \(toolName)"
    }

    var usageString = UsageGenerator(toolName: toolName, definition: [currentArgSet]).synopsis
    if !currentCommand.configuration.subcommands.isEmpty {
      if usageString.last != " " { usageString += " " }
      usageString += "<subcommand>"
    }
    
    self.abstract = currentCommand.configuration.abstract
    if !currentCommand.configuration.discussion.isEmpty {
      if !self.abstract.isEmpty {
        self.abstract += "\n"
      }
      self.abstract += "\n\(currentCommand.configuration.discussion)"
    }
    
    self.usage = Usage(components: [usageString])
    self.sections = HelpGenerator.generateSections(commandStack: commandStack)
    self.discussionSections = []
  }
  
  init(_ type: ParsableArguments.Type) {
    self.init(commandStack: [type.asCommand])
  }

  static func generateSections(commandStack: [ParsableCommand.Type]) -> [Section] {
    var positionalElements: [Section.Element] = []
    var optionElements: [Section.Element] = []
    /// Used to keep track of elements already seen from parent commands.
    var alreadySeenElements = Set<Section.Element>()

    for commandType in commandStack {
      let args = Array(ArgumentSet(commandType))
      
      var i = 0
      while i < args.count {
        defer { i += 1 }
        let arg = args[i]
        
        guard arg.help.help?.shouldDisplay != false else { continue }
        
        let synopsis: String
        let description: String
        
        if args[i].help.isComposite {
          // If this argument is composite, we have a group of arguments to
          // output together.
          var groupedArgs = [arg]
          let defaultValue = arg.help.defaultValue.map { "(default: \($0))" } ?? ""
          while i < args.count - 1 && args[i + 1].help.keys == arg.help.keys {
            groupedArgs.append(args[i + 1])
            i += 1
          }

          var synopsisString = ""
          for arg in groupedArgs {
            if !synopsisString.isEmpty { synopsisString.append("/") }
            synopsisString.append("\(arg.synopsisForHelp ?? "")")
          }
          synopsis = synopsisString

          var descriptionString: String?
          for arg in groupedArgs {
            if let desc = arg.help.help?.abstract {
              descriptionString = desc
              break
            }
          }
          description = [descriptionString, defaultValue]
            .compactMap { $0 }
            .joined(separator: " ")
        } else {
          let defaultValue = arg.help.defaultValue.flatMap { $0.isEmpty ? nil : "(default: \($0))" } ?? ""
          synopsis = arg.synopsisForHelp ?? ""
          description = [arg.help.help?.abstract, defaultValue]
            .compactMap { $0 }
            .joined(separator: " ")
        }
        
        let element = Section.Element(label: synopsis, abstract: description, discussion: arg.help.help?.discussion ?? "")
        if !alreadySeenElements.contains(element) {
          alreadySeenElements.insert(element)
          if case .positional = arg.kind {
            positionalElements.append(element)
          } else {
            optionElements.append(element)
          }
        }
      }
    }
    
    if commandStack.contains(where: { !$0.configuration.version.isEmpty }) {
      optionElements.append(.init(label: "--version", abstract: "Show the version."))
    }

    let helpLabels = commandStack
      .first!
      .getHelpNames()
      .map { $0.synopsisString }
      .joined(separator: ", ")
    if !helpLabels.isEmpty {
      optionElements.append(.init(label: helpLabels, abstract: "Show help information."))
    }

    let configuration = commandStack.last!.configuration
    let subcommandElements: [Section.Element] =
      configuration.subcommands.compactMap { command in
        guard command.configuration.shouldDisplay else { return nil }
        var label = command._commandName
        if command == configuration.defaultSubcommand {
            label += " (default)"
        }
        return Section.Element(
          label: label,
          abstract: command.configuration.abstract)
    }
    
    return [
      Section(header: .positionalArguments, elements: positionalElements),
      Section(header: .options, elements: optionElements),
      Section(header: .subcommands, elements: subcommandElements),
    ]
  }
  
  func usageMessage(screenWidth: Int? = nil) -> String {
    let screenWidth = screenWidth ?? HelpGenerator.systemScreenWidth
    return "Usage: \(usage.rendered(screenWidth: screenWidth))"
  }
  
  var includesSubcommands: Bool {
    guard let subcommandSection = sections.first(where: { $0.header == .subcommands })
      else { return false }
    return !subcommandSection.elements.isEmpty
  }
  
  func rendered(screenWidth: Int? = nil) -> String {
    let screenWidth = screenWidth ?? HelpGenerator.systemScreenWidth
    let renderedSections = sections
      .map { $0.rendered(screenWidth: screenWidth) }
      .filter { !$0.isEmpty }
      .joined(separator: "\n")
    let renderedAbstract = abstract.isEmpty
      ? ""
      : "OVERVIEW: \(abstract)".wrapped(to: screenWidth) + "\n\n"
    
    var helpSubcommandMessage: String = ""
    if includesSubcommands {
      var names = commandStack.map { $0._commandName }
      if let superName = commandStack.first!.configuration._superCommandName {
        names.insert(superName, at: 0)
      }
      names.insert("help", at: 1)

      helpSubcommandMessage = """

          See '\(names.joined(separator: " ")) <subcommand>' for detailed help.
        """
    }
    
    return """
    \(renderedAbstract)\
    USAGE: \(usage.rendered(screenWidth: screenWidth))
    
    \(renderedSections)\(helpSubcommandMessage)
    """
  }
}

internal extension ParsableCommand {
  static func getHelpNames() -> [Name] {
    return self.configuration
      .helpNames
      .makeNames(InputKey(rawValue: "help"))
      .sorted(by: >)
  }
}

#if canImport(Glibc)
import Glibc
func ioctl(_ a: Int32, _ b: Int32, _ p: UnsafeMutableRawPointer) -> Int32 {
  ioctl(CInt(a), UInt(b), p)
}
#elseif canImport(Darwin)
import Darwin
#elseif canImport(MSVCRT)
import MSVCRT
import WinSDK
#endif

func _terminalSize() -> (width: Int, height: Int) {
#if os(Windows)
  var csbi: CONSOLE_SCREEN_BUFFER_INFO = CONSOLE_SCREEN_BUFFER_INFO()

  GetConsoleScreenBufferInfo(GetStdHandle(STD_OUTPUT_HANDLE), &csbi)
  return (width: Int(csbi.srWindow.Right - csbi.srWindow.Left) + 1,
          height: Int(csbi.srWindow.Bottom - csbi.srWindow.Top) + 1)
#else
  var w = winsize()
  let err = ioctl(STDOUT_FILENO, TIOCGWINSZ, &w)
  let width = Int(w.ws_col)
  let height = Int(w.ws_row)
  guard err == 0 else { return (80, 25) }
  return (width: width > 0 ? width : 80,
          height: height > 0 ? height : 25)
#endif
}
