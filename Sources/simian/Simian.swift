//
//  Simian.swift
//
//
//  Created by Jack Newcombe on 23/06/2024.
//

import Foundation

class Simian: SimianLogReporter {
    
    static let shared = Simian()
    
    private override init() {
        super.init()
    }
    
    var command: Command? {
        guard arguments.count > 1 else {
            return nil
        }
        let command = Command(rawValue: arguments[1])
        return command
    }
    
    func runCommand() {
        guard let command = command else {
            let allCommands = Command.allCases.map { $0.rawValue }.joined(separator: ", ")
            if arguments.count > 1 {
                logger.error("Command `\(arguments[1])` not found, command must be one of: \(allCommands)".red)
            } else {
                logger.error("Command was not provided - first argument must be a command from: \(allCommands)".red)
            }
            _logger.info("")
            printHelp()
            return
        }
        command.execute()
    }

    // MARK: shell helpers
    
    var arguments: [String] {
        ProcessInfo.processInfo.arguments
    }
    
    var commandArguments: [String: String?] {
        var commandArgs: [String: String?] = [:]
        guard arguments.count > 2 else {
            return commandArgs
        }
        let args = Array(arguments[2...])
        args.enumerated().forEach { (index, arg) in
            if arg.hasPrefix("-") {
                let value = args.count >= index && !args[index + 1].hasPrefix("-") ? args[index + 1] : nil
                commandArgs[arg] = value
            }
        }
        
        return commandArgs
    }
    
    private func printHelp() {
        _logger.info("""
📱 \("Simian".bold.cyan) - a tool for managing simulators

Commands:
    \("boot".bold) - Boot a simulator
    \("shutdown".bold) - Shut down a simulator
    \("list".bold) - List simulators by platform
    \("info".bold) - Get detailed information about a simulator

For more information 👉 https://github.com/jnewc/Simian
""")
    }
}

// MARK: Command enum

private let _logger = SimianLogReporter().logger

extension Simian {
    enum Command: String, CaseIterable {
        case boot
        case shutdown
        case info
        case list
        case help
        
        private var arguments: [String: String?] {
            Simian.shared.commandArguments
        }
        
        func execute() {
            do {
                switch self {
                case .boot:
                    let (key, value, platform) = try getDeviceArguments()
                    try SimctlHelper.shared.boot(key: key, value: value, platform: platform)
                case .shutdown:
                    if arguments.keys.contains("-all") {
                        try SimctlHelper.shared.bootAll()
                    } else {
                        let (key, value, platform) = try getDeviceArguments()
                        try SimctlHelper.shared.shutdown(key: key, value: value, platform: platform)
                    }
                case .info:
                    let (key, value, platform) = try getDeviceArguments()
                    try SimctlHelper.shared.info(key: key, value: value, platform: platform)
                case .list:
                    try SimctlHelper.shared.list()
                default:
                    Simian.shared.printHelp()
                }
            } catch let error as SimianError {
                _logger.error(error.description.red)
            } catch {
                _logger.error(error.localizedDescription.red)
            }
        }
        
        // MARK: Helpers
        
        private typealias DeviceArguments = (key: KeyPath<Device, String>, value: String, platform: String)
        
        private func getDeviceArguments() throws -> DeviceArguments {
            guard let platform = arguments["-platform"] as? String else {
                throw SimianError("'-platform' argument must be provided")
            }
            
            let key: KeyPath<Device, String>
            let value: String
            
            if let _value = arguments["-name"] as? String {
                key = \.name
                value = _value
            } else if let _value = arguments["-device"] as? String {
                key = \.deviceTypeIdentifier
                value = format(device: _value)
                _logger.debug("Using device type identifier: \(value)")
            } else {
                throw SimianError("One of '-device' or '-name' arguments must be provided")
            }
            
            return (key: key, value: value, platform: platform)
        }
        
        private func format(device: String) -> String {
            let matcher: Regex = #/[^a-zA-Z0-9]+/#
            let formattedDevice = device.replacing(matcher, with: "-")
            return "com.apple.CoreSimulator.SimDeviceType.\(formattedDevice)"
        }
    }
}
