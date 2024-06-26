//
//  Model.swift
//  
//
//  Created by Jack Newcombe on 22/06/2024.
//

import Foundation

struct DeviceType: Decodable {
    let bundlePath: String
    let name: String
    let identifier: String
    let productFamily: String
}

struct CompleteDeviceType: Decodable {
    let bundlePath: String
    let name: String
    let identifier: String
    let productFamily: String
    let maxRuntimeVersion: UInt
    let maxRuntimeVersionString: String
    let modelIdentifier: String
    let minRuntimeVersionString: String
    let minRuntimeVersion: UInt
}

struct Runtime: Decodable {
    let bundlePath: String
    let buildversion: String
    let platform: String
    let runtimeRoot: String
    let identifier: String
    let version: String
    let isInternal: Bool
    let isAvailable: Bool
    let name: String
    let supportedDeviceTypes: [DeviceType]
}

struct Device: Decodable {
    let lastBootedAt: String?
    let dataPath: String
    let dataPathSize: UInt64
    let logPath: String
    let udid: String
    let isAvailable: Bool
    let availabilityError: String?
    let logPathSize: UInt64?
    let deviceTypeIdentifier: String
    let state: String
    let name: String
    
}

struct Devices: Decodable {
    
    struct DummyKey: CodingKey {
        var stringValue: String
        
        init?(stringValue: String) {
            self.stringValue = stringValue
        }
        
        var intValue: Int?
        
        init?(intValue: Int) {
            self.intValue = intValue
            self.stringValue = "\(intValue)"
        }
    }
    
    var map: [String: [Device]] = [:]
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DummyKey.self)
//        self.map = try container.decode([String : [Device]].self, forKey: .map)
        try container.allKeys.forEach { key in
            map[key.stringValue] = try container.decode([Device].self, forKey: key)
        }
    }
}

struct Simulators: Decodable {
    let devicetypes: [CompleteDeviceType]
    let runtimes: [Runtime]
    let devices: Devices
}
