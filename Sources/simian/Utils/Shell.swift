//
//  Shell.swift
//  Purr
//
//  Created by Jack Newcombe on 13/04/2018.
//  Copyright © 2018 Jack Newcombe. All rights reserved.
//

import Foundation

fileprivate enum Signal: Int32 {
    case HUP    = 1
    case INT    = 2
    case QUIT   = 3
    case ABRT   = 6
    case KILL   = 9
    case ALRM   = 14
    case TERM   = 15
}

public struct ShellResult {
    
    let result: Int
    
    let standardOutput: [String]
    
    let standardError: [String]
    
    var succeeded: Bool {
        return result == 0
    }
    
}

public typealias ShellCompletion = (ShellResult) -> Void
public typealias OutputCompletion = ([String]) -> Void

public protocol Shell {
    @discardableResult func execute(options: [String]) -> Int?
    @discardableResult func execute(options: [String], isSync: Bool) -> Int?
}

public class ShellHelper {
    /// Helper function for asynchronous command execution
    ///
    /// - Parameters:
    ///   - command: The command (including arguments)
    ///   - completion: The completion to be called after the command has executed
    public static func execute(command: String,
                               toFile filePath: String? = nil,
                               completion: @escaping ShellCompletion = { _ in },
                               onOutput: @escaping OutputCompletion = { _ in },
                               onError: @escaping OutputCompletion = { _ in }) {
        let shell = DefaultShell()
        setCompletions(shell: shell, filePath: filePath, completion: completion, onOutput: onOutput, onError: onError)
        shell.execute(options: command.components(separatedBy: .whitespacesAndNewlines), isSync: false)
    }
    
    @discardableResult
    public static func executeSync(command: String,
                                   toFile filePath: String? = nil,
                                   completion: @escaping ShellCompletion = { _ in },
                                   onOutput: @escaping OutputCompletion = { _ in },
                                   onError: @escaping OutputCompletion = { _ in }) -> ShellResult {
        let shell = DefaultShell()

        setCompletions(shell: shell, filePath: filePath, completion: completion, onOutput: onOutput, onError: onError)
        
        let result = shell.execute(options: command.components(separatedBy: .whitespacesAndNewlines), isSync: true)
        
        if let filePath = filePath {
            let string = shell.standardOutput.joined(separator: "\n")
            try? FileManager.default.removeItem(atPath: filePath)
            FileManager.default.createFile(atPath: filePath, contents: string.data(using: .utf8)!)
        }
        
        return ShellResult(result: result ?? -1, standardOutput: shell.standardOutput, standardError: shell.errorOutput)
    }
    
    private static func setCompletions(shell: DefaultShell,
                                       filePath: String?,
                                       completion: @escaping ShellCompletion,
                                       onOutput: @escaping OutputCompletion,
                                       onError: @escaping OutputCompletion) {
        shell.onStandardOutput = { result in
            onOutput(result)
        }
        shell.onStandardError = { result in
            onError(result)
        }
    }
}

public final class DefaultShell: Shell {

    let lockQueue = DispatchQueue(label: "Purr.Shell")
    
    private(set) public var standardOutput: [String] = []

    private(set) public var errorOutput: [String] = []
    
    public var onCompleted: ShellCompletion?
    
    public var onStandardOutput: OutputCompletion?
    
    public var onStandardError: OutputCompletion?

    init() {
    }
    
    /// Executes the xcodebuild command.
    ///
    /// Parses standard and error output and output, and passes it to
    /// all configured reporters
    ///
    /// - Parameters:
    ///   - options: a list of options to pass to xcodebuild
    ///   - commands: a list of build commands to pass to xcodebuild
    @discardableResult public func execute(options: [String], isSync: Bool) -> Int? {
        
        let task = Process()
        task.launchPath = "/usr/bin/env"
        task.arguments = options

        var env = ProcessInfo.processInfo.environment
        env["PATH"]? += ":/usr/local/bin"
        task.environment = env
        setupPipes(task: task, 
                   outputHandler: outputHandler,
                   errorHandler: errorHandler,
                   terminationHandler: terminationHandler)
                
        do {
            try task.run();
        } catch {
            print("Shell failed: \(error.localizedDescription)")
        }
        
        if isSync {
            task.waitUntilExit()
            return Int(task.terminationStatus)
        } else {
        }
        
        return nil
    }
    
    public func execute(options: [String]) -> Int? {
        return execute(options: options, isSync: true)
    }
    
    func outputHandler(lines: [String]) {
        onStandardOutput?(lines)
        standardOutput.append(contentsOf: lines)
    }
    
    func errorHandler(lines: [String]) {
        onStandardError?(lines)
        errorOutput.append(contentsOf: lines)
    }
    
    func terminationHandler(result: Int) {
        if let onCompleted = onCompleted {
            let result = ShellResult(result: result, standardOutput: standardOutput, standardError: errorOutput)
            onCompleted(result)
        }
    }
}
