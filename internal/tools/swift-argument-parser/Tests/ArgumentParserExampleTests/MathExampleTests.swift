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
import ArgumentParser
import ArgumentParserTestHelpers

final class MathExampleTests: XCTestCase {
  func testMath_Simple() throws {
    AssertExecuteCommand(command: "math 1 2 3 4 5", expected: "15")
    AssertExecuteCommand(command: "math multiply 1 2 3 4 5", expected: "120")
  }
  
  func testMath_Help() throws {
    let helpText = """
        OVERVIEW: A utility for performing maths.

        USAGE: math <subcommand>

        OPTIONS:
          --version               Show the version.
          -h, --help              Show help information.

        SUBCOMMANDS:
          add (default)           Print the sum of the values.
          multiply                Print the product of the values.
          stats                   Calculate descriptive statistics.

          See 'math help <subcommand>' for detailed help.
        """
    
    AssertExecuteCommand(command: "math -h", expected: helpText)
    AssertExecuteCommand(command: "math --help", expected: helpText)
    AssertExecuteCommand(command: "math help", expected: helpText)
  }
  
  func testMath_AddHelp() throws {
    let helpText = """
        OVERVIEW: Print the sum of the values.

        USAGE: math add [--hex-output] [<values> ...]

        ARGUMENTS:
          <values>                A group of integers to operate on.

        OPTIONS:
          -x, --hex-output        Use hexadecimal notation for the result.
          --version               Show the version.
          -h, --help              Show help information.
        """
    
    AssertExecuteCommand(command: "math add -h", expected: helpText)
    AssertExecuteCommand(command: "math add --help", expected: helpText)
    AssertExecuteCommand(command: "math help add", expected: helpText)
  }
  
  func testMath_StatsMeanHelp() throws {
    let helpText = """
        OVERVIEW: Print the average of the values.

        USAGE: math stats average [--kind <kind>] [<values> ...]

        ARGUMENTS:
          <values>                A group of floating-point values to operate on.

        OPTIONS:
          --kind <kind>           The kind of average to provide. (default: mean)
          --version               Show the version.
          -h, --help              Show help information.
        """
    
    AssertExecuteCommand(command: "math stats average -h", expected: helpText)
    AssertExecuteCommand(command: "math stats average --help", expected: helpText)
    AssertExecuteCommand(command: "math help stats average", expected: helpText)
  }
  
  func testMath_StatsQuantilesHelp() throws {
    let helpText = """
        OVERVIEW: Print the quantiles of the values (TBD).

        USAGE: math stats quantiles [<values> ...]

        ARGUMENTS:
          <values>                A group of floating-point values to operate on.

        OPTIONS:
          --version               Show the version.
          -h, --help              Show help information.
        """
    
    // The "quantiles" subcommand's run() method is unimplemented, so it
    // just generates the help text.
    AssertExecuteCommand(command: "math stats quantiles", expected: helpText)
    
    AssertExecuteCommand(command: "math stats quantiles -h", expected: helpText)
    AssertExecuteCommand(command: "math stats quantiles --help", expected: helpText)
    AssertExecuteCommand(command: "math help stats quantiles", expected: helpText)
  }
  
  func testMath_CustomValidation() throws {
    AssertExecuteCommand(
      command: "math stats average --kind mode",
      expected: """
            Error: Please provide at least one value to calculate the mode.
            Usage: math stats average [--kind <kind>] [<values> ...]
              See 'math stats average --help' for more information.
            """,
      exitCode: .validationFailure)
  }
  
  func testMath_Versions() throws {
    AssertExecuteCommand(
      command: "math --version",
      expected: "1.0.0")
    AssertExecuteCommand(
      command: "math stats --version",
      expected: "1.0.0")
    AssertExecuteCommand(
      command: "math stats average --version",
      expected: "1.5.0-alpha")
  }

  func testMath_ExitCodes() throws {
    AssertExecuteCommand(
      command: "math stats quantiles --test-success-exit-code",
      expected: "",
      exitCode: .success)
    AssertExecuteCommand(
      command: "math stats quantiles --test-failure-exit-code",
      expected: "",
      exitCode: .failure)
    AssertExecuteCommand(
      command: "math stats quantiles --test-validation-exit-code",
      expected: "",
      exitCode: .validationFailure)
    AssertExecuteCommand(
      command: "math stats quantiles --test-custom-exit-code 42",
      expected: "",
      exitCode: ExitCode(42))
  }
  
  func testMath_Fail() throws {
    AssertExecuteCommand(
      command: "math --foo",
      expected: """
            Error: Unknown option '--foo'
            Usage: math add [--hex-output] [<values> ...]
              See 'math add --help' for more information.
            """,
      exitCode: .validationFailure)
    
    AssertExecuteCommand(
      command: "math ZZZ",
      expected: """
            Error: The value 'ZZZ' is invalid for '<values>'
            Usage: math add [--hex-output] [<values> ...]
              See 'math add --help' for more information.
            """,
      exitCode: .validationFailure)
  }
}

// MARK: - Completion Script

extension MathExampleTests {
  func testMath_CompletionScript() {
    AssertExecuteCommand(
      command: "math --generate-completion-script=bash",
      expected: bashCompletionScriptText)
    AssertExecuteCommand(
      command: "math --generate-completion-script bash",
      expected: bashCompletionScriptText)
    AssertExecuteCommand(
      command: "math --generate-completion-script=zsh",
      expected: zshCompletionScriptText)
    AssertExecuteCommand(
      command: "math --generate-completion-script zsh",
      expected: zshCompletionScriptText)
    AssertExecuteCommand(
      command: "math --generate-completion-script=fish",
      expected: fishCompletionScriptText)
    AssertExecuteCommand(
      command: "math --generate-completion-script fish",
      expected: fishCompletionScriptText)
  }
  
  func testMath_CustomCompletion() {
    AssertExecuteCommand(
      command: "math ---completion stats quantiles -- --custom",
      expected: """
        hello
        helicopter
        heliotrope
        """)
    
    AssertExecuteCommand(
      command: "math ---completion stats quantiles -- --custom h",
      expected: """
        hello
        helicopter
        heliotrope
        """)
  
    AssertExecuteCommand(
      command: "math ---completion stats quantiles -- --custom a",
      expected: """
        aardvark
        aaaaalbert
        """)
  }
}

private let bashCompletionScriptText = """
#!/bin/bash

_math() {
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    COMPREPLY=()
    opts="add multiply stats help -h --help"
    if [[ $COMP_CWORD == "1" ]]; then
        COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
        return
    fi
    case ${COMP_WORDS[1]} in
        (add)
            _math_add 2
            return
            ;;
        (multiply)
            _math_multiply 2
            return
            ;;
        (stats)
            _math_stats 2
            return
            ;;
        (help)
            _math_help 2
            return
            ;;
    esac
    COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
}
_math_add() {
    opts="--hex-output -x -h --help"
    if [[ $COMP_CWORD == "$1" ]]; then
        COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
        return
    fi
    COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
}
_math_multiply() {
    opts="--hex-output -x -h --help"
    if [[ $COMP_CWORD == "$1" ]]; then
        COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
        return
    fi
    COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
}
_math_stats() {
    opts="average stdev quantiles -h --help"
    if [[ $COMP_CWORD == "$1" ]]; then
        COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
        return
    fi
    case ${COMP_WORDS[$1]} in
        (average)
            _math_stats_average $(($1+1))
            return
            ;;
        (stdev)
            _math_stats_stdev $(($1+1))
            return
            ;;
        (quantiles)
            _math_stats_quantiles $(($1+1))
            return
            ;;
    esac
    COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
}
_math_stats_average() {
    opts="--kind -h --help"
    if [[ $COMP_CWORD == "$1" ]]; then
        COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
        return
    fi
    case $prev in
        --kind)
            COMPREPLY=( $(compgen -W "mean median mode" -- "$cur") )
            return
        ;;
    esac
    COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
}
_math_stats_stdev() {
    opts="-h --help"
    if [[ $COMP_CWORD == "$1" ]]; then
        COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
        return
    fi
    COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
}
_math_stats_quantiles() {
    opts="--test-success-exit-code --test-failure-exit-code --test-validation-exit-code --test-custom-exit-code --file --directory --shell --custom -h --help"
    opts="$opts alphabet alligator branch braggart"
    opts="$opts $(math ---completion stats quantiles -- customArg "$COMP_WORDS")"
    if [[ $COMP_CWORD == "$1" ]]; then
        COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
        return
    fi
    case $prev in
        --test-custom-exit-code)
            
            return
        ;;
        --file)
            COMPREPLY=( $(compgen -f -- "$cur") )
            return
        ;;
        --directory)
            COMPREPLY=( $(compgen -d -- "$cur") )
            return
        ;;
        --shell)
            COMPREPLY=( $(head -100 /usr/share/dict/words | tail -50) )
            return
        ;;
        --custom)
            COMPREPLY=( $(compgen -W "$(math ---completion stats quantiles -- --custom "$COMP_WORDS")" -- "$cur") )
            return
        ;;
    esac
    COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
}
_math_help() {
    opts="-h --help"
    if [[ $COMP_CWORD == "$1" ]]; then
        COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
        return
    fi
    COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
}


complete -F _math math
"""

private let zshCompletionScriptText = """
#compdef math
local context state state_descr line
_math_commandname=$words[1]
typeset -A opt_args

_math() {
    integer ret=1
    local -a args
    args+=(
        '(-h --help)'{-h,--help}'[Print help information.]'
        '(-): :->command'
        '(-)*:: :->arg'
    )
    _arguments -w -s -S $args[@] && ret=0
    case $state in
        (command)
            local subcommands
            subcommands=(
                'add:Print the sum of the values.'
                'multiply:Print the product of the values.'
                'stats:Calculate descriptive statistics.'
                'help:Show subcommand help information.'
            )
            _describe "subcommand" subcommands
            ;;
        (arg)
            case ${words[1]} in
                (add)
                    _math_add
                    ;;
                (multiply)
                    _math_multiply
                    ;;
                (stats)
                    _math_stats
                    ;;
                (help)
                    _math_help
                    ;;
            esac
            ;;
    esac

    return ret
}

_math_add() {
    integer ret=1
    local -a args
    args+=(
        '(--hex-output -x)'{--hex-output,-x}'[Use hexadecimal notation for the result.]'
        ':values:'
        '(-h --help)'{-h,--help}'[Print help information.]'
    )
    _arguments -w -s -S $args[@] && ret=0

    return ret
}

_math_multiply() {
    integer ret=1
    local -a args
    args+=(
        '(--hex-output -x)'{--hex-output,-x}'[Use hexadecimal notation for the result.]'
        ':values:'
        '(-h --help)'{-h,--help}'[Print help information.]'
    )
    _arguments -w -s -S $args[@] && ret=0

    return ret
}

_math_stats() {
    integer ret=1
    local -a args
    args+=(
        '(-h --help)'{-h,--help}'[Print help information.]'
        '(-): :->command'
        '(-)*:: :->arg'
    )
    _arguments -w -s -S $args[@] && ret=0
    case $state in
        (command)
            local subcommands
            subcommands=(
                'average:Print the average of the values.'
                'stdev:Print the standard deviation of the values.'
                'quantiles:Print the quantiles of the values (TBD).'
            )
            _describe "subcommand" subcommands
            ;;
        (arg)
            case ${words[1]} in
                (average)
                    _math_stats_average
                    ;;
                (stdev)
                    _math_stats_stdev
                    ;;
                (quantiles)
                    _math_stats_quantiles
                    ;;
            esac
            ;;
    esac

    return ret
}

_math_stats_average() {
    integer ret=1
    local -a args
    args+=(
        '--kind[The kind of average to provide.]:kind:(mean median mode)'
        ':values:'
        '(-h --help)'{-h,--help}'[Print help information.]'
    )
    _arguments -w -s -S $args[@] && ret=0

    return ret
}

_math_stats_stdev() {
    integer ret=1
    local -a args
    args+=(
        ':values:'
        '(-h --help)'{-h,--help}'[Print help information.]'
    )
    _arguments -w -s -S $args[@] && ret=0

    return ret
}

_math_stats_quantiles() {
    integer ret=1
    local -a args
    args+=(
        ':one-of-four:(alphabet alligator branch braggart)'
        ':custom-arg:{_custom_completion $_math_commandname ---completion stats quantiles -- customArg $words}'
        ':values:'
        '--test-success-exit-code'
        '--test-failure-exit-code'
        '--test-validation-exit-code'
        '--test-custom-exit-code:test-custom-exit-code:'
        '--file:file:_files -g '"'"'*.txt *.md'"'"''
        '--directory:directory:_files -/'
        '--shell:shell:{local -a list; list=(${(f)"$(head -100 /usr/share/dict/words | tail -50)"}); _describe '''' list}'
        '--custom:custom:{_custom_completion $_math_commandname ---completion stats quantiles -- --custom $words}'
        '(-h --help)'{-h,--help}'[Print help information.]'
    )
    _arguments -w -s -S $args[@] && ret=0

    return ret
}

_math_help() {
    integer ret=1
    local -a args
    args+=(
        ':subcommands:'
        '(-h --help)'{-h,--help}'[Print help information.]'
    )
    _arguments -w -s -S $args[@] && ret=0

    return ret
}


_custom_completion() {
    local completions=("${(@f)$($*)}")
    _describe '' completions
}

_math
"""

private let fishCompletionScriptText = """
function __fish_math_using_command
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
complete -c math -n '__fish_math_using_command math' -f -a 'add' -d 'Print the sum of the values.'
complete -c math -n '__fish_math_using_command math' -f -a 'multiply' -d 'Print the product of the values.'
complete -c math -n '__fish_math_using_command math' -f -a 'stats' -d 'Calculate descriptive statistics.'
complete -c math -n '__fish_math_using_command math' -f -a 'help' -d 'Show subcommand help information.'
complete -c math -n '__fish_math_using_command math add' -f -l hex-output -s x -d 'Use hexadecimal notation for the result.'
complete -c math -n '__fish_math_using_command math multiply' -f -l hex-output -s x -d 'Use hexadecimal notation for the result.'
complete -c math -n '__fish_math_using_command math stats' -f -a 'average' -d 'Print the average of the values.'
complete -c math -n '__fish_math_using_command math stats' -f -a 'stdev' -d 'Print the standard deviation of the values.'
complete -c math -n '__fish_math_using_command math stats' -f -a 'quantiles' -d 'Print the quantiles of the values (TBD).'
complete -c math -n '__fish_math_using_command math stats' -f -a 'help' -d 'Show subcommand help information.'
complete -c math -n '__fish_math_using_command math stats average' -f -r -l kind -d 'The kind of average to provide.'
complete -c math -n '__fish_math_using_command math stats average --kind' -f -k -a 'mean median mode'
complete -c math -n '__fish_math_using_command math stats quantiles' -f -l test-success-exit-code
complete -c math -n '__fish_math_using_command math stats quantiles' -f -l test-failure-exit-code
complete -c math -n '__fish_math_using_command math stats quantiles' -f -l test-validation-exit-code
complete -c math -n '__fish_math_using_command math stats quantiles' -f -r -l test-custom-exit-code
complete -c math -n '__fish_math_using_command math stats quantiles' -f -r -l file
complete -c math -n '__fish_math_using_command math stats quantiles --file' -f -a '(for i in *.{txt,md}; echo $i;end)'
complete -c math -n '__fish_math_using_command math stats quantiles' -f -r -l directory
complete -c math -n '__fish_math_using_command math stats quantiles --directory' -f -a '(__fish_complete_directories)'
complete -c math -n '__fish_math_using_command math stats quantiles' -f -r -l shell
complete -c math -n '__fish_math_using_command math stats quantiles --shell' -f -a '(head -100 /usr/share/dict/words | tail -50)'
complete -c math -n '__fish_math_using_command math stats quantiles' -f -r -l custom
complete -c math -n '__fish_math_using_command math stats quantiles --custom' -f -a '(command math ---completion stats quantiles -- --custom (commandline -opc)[1..-1])'
"""
