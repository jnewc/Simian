//
//  SimctlHelper.swift
//
//
//  Created by Jack Newcombe on 23/06/2024.
//

import Foundation
import Cosmic

struct SimianError: Swift.Error {
    let description: String
    
    init(_ description: String) {
        self.description = description
    }
    
}

class SimianLogReporter: LogReporter {
    class Logger: CompositeLogger {
        required init() {
            super.init()
            self.logLevel = .debug
//            formatters.append(λFormatter { msg, _, _ in "📱 \(msg)" })
            loggers.append(PrintLogger())
        }
    }
    
    typealias DefaultLoggerType = SimianLogReporter.Logger
}

class SimctlHelper: DefaultLogReporter {
    
    static let shared = SimctlHelper()
    
    func getSimulators() throws -> Simulators {
        let result = ShellHelper.executeSync(command: "xcrun simctl list -j", toFile: "testing.json")

        guard let data = result.standardOutput.joined(separator: "\n").data(using: .utf8) else {
            throw SimianError("Failed to collect sim info");
        }

        let model = try JSONDecoder().decode(Simulators.self, from: data)
        return model
    }
    
    func getDevice(key: KeyPath<Device, String>, value: String, platform: String) throws -> Device? {
        self.logger.debug("Getting simulator info ...")

        let simulators = try getSimulators()
        let runtime = try getRuntime(platform: platform, in: simulators)
        
        // Device from runtime
        self.logger.debug("Finding device for runtime ...")
        guard let allDevices = simulators.devices.map[runtime.identifier] else {
            throw SimianError("Could not find devices for runtime '\(platform)'. This shouldn't happen ...")
        }
        let devices = allDevices.filter { device in
            (device.isAvailable && device[keyPath: key] == value)
        }
        
        if devices.count > 1 {
            logger.info("Multiple devices found for path '\(key)' -> '\(value)' for platform version '\(platform)'. Using first ...")
        }
        guard let device = devices.first else {
            throw SimianError("""
No devices found for '\(key)' -> '\(value)' and platform version '\(platform)'.
Check the name you have provided matches one of the following devices for the platform:
\(allDevices.map { " - \($0.name)" }.filter { !($0.isEmpty || $0.isWhitespace) }.joined(separator: "\n"))
""")
        }
        
        return device
    }
    
    func boot(key: KeyPath<Device, String>, value: String, platform: String) throws {
        let device = try deviceIfReady(key: key, value: value, platform: platform)
        
        // Check device
        guard device.state != "Booted" else {
            throw SimianError("Device is already booted ✅")
        }
 
        // Boot device
        logger.debug("Booting device ...")
        let result = ShellHelper.executeSync(command: "xcrun simctl boot \(device.udid)")
        if result.result == 0 {
            logger.info("Booted \(device.name) (\(platform)) ✅")
        } else {
            let err = result.standardError.joined(separator: "\n")
            throw SimianError("""
Failed to boot device :-(

\(err.isEmpty ? "Unknown error (no error output was provided by simctl)" : "stderr: \(err)")
""")
        }
    }
    
    func bootAll() throws {
        try actionAll(action: boot)
    }
    
    func shutdown(key: KeyPath<Device, String>, value: String, platform: String) throws {
        let device = try deviceIfReady(key: key, value: value, platform: platform)
        
        // Check device
        guard device.state == "Booted" else {
            logger.info("Device isn't booted ✅")
            return
        }

        // Boot device
        logger.debug("Shutting down device ...")
        let result = ShellHelper.executeSync(command: "xcrun simctl shutdown \(device.udid)")
        if result.result == 0 {
            logger.info("Shut down \(device.name) (\(platform)) ✅")
        } else {
            logger.error("Failed to shutdown device :-(")
            let err = result.standardError.joined(separator: "\n")
            logger.error(err.isEmpty ? "Unknown error" : "stderr: \(err)")
        }
    }
    
    func shutdownAll() throws {
        try actionAll(action: shutdown)
    }
    
    func info(key: KeyPath<Device, String>, value: String, platform: String) throws {
        let device = try deviceIfReady(key: key, value: value, platform: platform)
        
        var dict: [String: String] = [:]
        dict["Name"] = device.name
        dict["UDID"] = device.udid
        dict["State"] = device.deviceTypeIdentifier
        dict["Is Available"] = "\(device.isAvailable)"
        dict["Last booted at"] = device.lastBootedAt ?? "N/A"
        dict["Data path"] = device.dataPath
        dict["Data path size"] = "\(device.dataPathSize)"
        
        logger.info("")
        dict.forEach { key, value in
            logger.info("\(key.apply(color: .blue)): \(value)")
        }
    }
    
    func list(platform: String? = nil) throws {
        let root = try getSimulators()

        var rows: [TableRow] = []
        
        rows.append(.values(lines: [
            "Runtime".bold,
            "Name".bold,
            "State".bold,
            "UDID".bold
        ]))
        
        rows.append(.separator)
                
        try root.devices.map.forEach { runtimeName, devices in
            let devices = devices.sorted { $0.name < $1.name }
            try devices.forEach { device in
                let row = TableRow.values(lines: [
                    (device.udid == devices.first?.udid ? try formatRuntimeName(runtimeName) : "").magenta,
                    device.name.cyan,
                    device.state.apply(color: device.state == "Booted" ? .green : .gray),
                    device.udid,
                ])
                rows.append(row)
            }
        }
        
        let builder = TableBuilder(characters: .empty)
        let table = builder.build(with: rows)
        
        logger.info(table)
    }
    
    // MARK: Helpers
    
    private func deviceIfReady(key: KeyPath<Device, String>, value: String, platform: String) throws -> Device {
        guard let device = try getDevice(key: key, value: value, platform: platform) else {
            throw SimianError("No device was found")
        }
        guard device.isAvailable else {
            throw SimianError("Device is not currently available 👎")
            
        }
        return device
    }
    
    private func getRuntime(platform: String, in simulators: Simulators) throws -> Runtime {
        // Get runtime
        logger.debug("Finding runtime ...")
        let runtimes = simulators.runtimes.filter { $0.name == "iOS \(platform)" }
        if runtimes.count > 1 {
            logger.warn("WARNING: multiple runtimes found for platform version '\(platform)'. Using first ...")
        }
        guard let runtime = runtimes.first else {
            throw SimianError("No runtimes found for platform version '\(platform)'")
        }
        return runtime
    }
    
    private func actionAll(action: (KeyPath<Device, String>, String, String) throws -> Void) throws {
        let simulators = try getSimulators()
        try simulators.devices.map.map { rt in rt.value.map { (rt.key, $0) } }.joined().forEach { (runtimeId, device) in
            guard let runtime = simulators.runtimes.first(where: { $0.identifier == runtimeId }) else {
                let available = simulators.runtimes.map { $0.identifier }.joined(separator: ", ")
                throw SimianError("Failed to get runtime with identifier '\(runtimeId)'. Available runtimes: \(available)")
            }
            try action(\.name, device.name, runtime.version)
        }
    }
    
    private func formatRuntimeName(_ name: String) throws -> String {
        let regex = #/(\d+)-(\d+)$/#
        guard let match = name.firstMatch(of: regex) else {
            throw SimianError("Failed to match runtime in '\(name)'")
        }
        let major = Int(match.output.1.string)!
        let minor = Int(match.output.2.string)!
        return "\(major).\(minor)"
    }
}
