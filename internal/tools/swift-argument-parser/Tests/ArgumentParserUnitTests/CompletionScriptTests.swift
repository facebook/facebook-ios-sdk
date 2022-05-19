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

import XCTest
import ArgumentParserTestHelpers
@testable import ArgumentParser

final class CompletionScriptTests: XCTestCase {
}

extension CompletionScriptTests {
  struct Path: ExpressibleByArgument {
    var path: String
    
    init?(argument: String) {
      self.path = argument
    }
    
    static var defaultCompletionKind: CompletionKind {
      .file()
    }
  }
    
  enum Kind: String, ExpressibleByArgument, CaseIterable {
    case one, two, three = "custom-three"
  }
  
  struct Base: ParsableCommand {
    @Option(help: "The user's name.") var name: String
    @Option() var kind: Kind
    @Option(completion: .list(["1", "2", "3"])) var otherKind: Kind
    
    @Option() var path1: Path
    @Option() var path2: Path?
    @Option(completion: .list(["a", "b", "c"])) var path3: Path
  }

  func testBase_Zsh() throws {
    let script1 = try CompletionsGenerator(command: Base.self, shell: .zsh)
          .generateCompletionScript()
    XCTAssertEqual(zshBaseCompletions, script1)
    
    let script2 = try CompletionsGenerator(command: Base.self, shellName: "zsh")
          .generateCompletionScript()
    XCTAssertEqual(zshBaseCompletions, script2)
    
    let script3 = Base.completionScript(for: .zsh)
    XCTAssertEqual(zshBaseCompletions, script3)
  }

  func testBase_Bash() throws {
    let script1 = try CompletionsGenerator(command: Base.self, shell: .bash)
          .generateCompletionScript()

    XCTAssertEqual(bashBaseCompletions, script1)
    
    let script2 = try CompletionsGenerator(command: Base.self, shellName: "bash")
          .generateCompletionScript()
    XCTAssertEqual(bashBaseCompletions, script2)
    
    let script3 = Base.completionScript(for: .bash)
    XCTAssertEqual(bashBaseCompletions, script3)
  }

  func testBase_Fish() throws {
    let script1 = try CompletionsGenerator(command: Base.self, shell: .fish)
          .generateCompletionScript()
    XCTAssertEqual(fishBaseCompletions, script1)
    
    let script2 = try CompletionsGenerator(command: Base.self, shellName: "fish")
          .generateCompletionScript()
    XCTAssertEqual(fishBaseCompletions, script2)
    
    let script3 = Base.completionScript(for: .fish)
    XCTAssertEqual(fishBaseCompletions, script3)
  }
}

extension CompletionScriptTests {
  struct Custom: ParsableCommand {
    @Option(name: .shortAndLong, completion: .custom { _ in ["a", "b", "c"] })
    var one: String

    @Argument(completion: .custom { _ in ["d", "e", "f"] })
    var two: String

    @Option(name: .customShort("z"), completion: .custom { _ in ["x", "y", "z"] })
    var three: String
  }
  
  func verifyCustomOutput(
    _ arg: String,
    expectedOutput: String,
    file: StaticString = #file, line: UInt = #line
  ) throws {
    do {
      _ = try Custom.parse(["---completion", "--", arg])
      XCTFail("Didn't error as expected", file: (file), line: line)
    } catch let error as CommandError {
      guard case .completionScriptCustomResponse(let output) = error.parserError else {
        throw error
      }
      XCTAssertEqual(expectedOutput, output, file: (file), line: line)
    }
  }
  
  func testCustomCompletions() throws {
    try verifyCustomOutput("-o", expectedOutput: "a\nb\nc")
    try verifyCustomOutput("--one", expectedOutput: "a\nb\nc")
    try verifyCustomOutput("two", expectedOutput: "d\ne\nf")
    try verifyCustomOutput("-z", expectedOutput: "x\ny\nz")
    
    XCTAssertThrowsError(try verifyCustomOutput("--bad", expectedOutput: ""))
  }
}

extension CompletionScriptTests {
  struct Escaped: ParsableCommand {
    @Option(help: #"Escaped chars: '[]\."#)
    var one: String
  }

  func testEscaped_Zsh() throws {
    XCTAssertEqual(zshEscapedCompletion, Escaped.completionScript(for: .zsh))
  }
}

private let zshBaseCompletions = """
#compdef base
local context state state_descr line
_base_commandname=$words[1]
typeset -A opt_args

_base() {
    integer ret=1
    local -a args
    args+=(
        '--name[The user'"'"'s name.]:name:'
        '--kind:kind:(one two custom-three)'
        '--other-kind:other-kind:(1 2 3)'
        '--path1:path1:_files'
        '--path2:path2:_files'
        '--path3:path3:(a b c)'
        '(-h --help)'{-h,--help}'[Print help information.]'
    )
    _arguments -w -s -S $args[@] && ret=0

    return ret
}


_custom_completion() {
    local completions=("${(@f)$($*)}")
    _describe '' completions
}

_base
"""

private let bashBaseCompletions = """
#!/bin/bash

_base() {
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    COMPREPLY=()
    opts="--name --kind --other-kind --path1 --path2 --path3 -h --help"
    if [[ $COMP_CWORD == "1" ]]; then
        COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
        return
    fi
    case $prev in
        --name)
            
            return
        ;;
        --kind)
            COMPREPLY=( $(compgen -W "one two custom-three" -- "$cur") )
            return
        ;;
        --other-kind)
            COMPREPLY=( $(compgen -W "1 2 3" -- "$cur") )
            return
        ;;
        --path1)
            COMPREPLY=( $(compgen -f -- "$cur") )
            return
        ;;
        --path2)
            COMPREPLY=( $(compgen -f -- "$cur") )
            return
        ;;
        --path3)
            COMPREPLY=( $(compgen -W "a b c" -- "$cur") )
            return
        ;;
    esac
    COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
}


complete -F _base base
"""

private let zshEscapedCompletion = """
#compdef escaped
local context state state_descr line
_escaped_commandname=$words[1]
typeset -A opt_args

_escaped() {
    integer ret=1
    local -a args
    args+=(
        '--one[Escaped chars: '"'"'\\[\\]\\\\.]:one:'
        '(-h --help)'{-h,--help}'[Print help information.]'
    )
    _arguments -w -s -S $args[@] && ret=0

    return ret
}


_custom_completion() {
    local completions=("${(@f)$($*)}")
    _describe '' completions
}

_escaped
"""

private let fishBaseCompletions = """
function __fish_base_using_command
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
complete -c base -n '__fish_base_using_command base' -f -r -l name -d 'The user\\'s name.'
complete -c base -n '__fish_base_using_command base' -f -r -l kind
complete -c base -n '__fish_base_using_command base --kind' -f -k -a 'one two custom-three'
complete -c base -n '__fish_base_using_command base' -f -r -l other-kind
complete -c base -n '__fish_base_using_command base --other-kind' -f -k -a '1 2 3'
complete -c base -n '__fish_base_using_command base' -f -r -l path1
complete -c base -n '__fish_base_using_command base --path1' -f -a '(for i in *.{}; echo $i;end)'
complete -c base -n '__fish_base_using_command base' -f -r -l path2
complete -c base -n '__fish_base_using_command base --path2' -f -a '(for i in *.{}; echo $i;end)'
complete -c base -n '__fish_base_using_command base' -f -r -l path3
complete -c base -n '__fish_base_using_command base --path3' -f -k -a 'a b c'
"""
