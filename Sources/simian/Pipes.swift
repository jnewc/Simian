//
//  Pipes.swift
//  Purr
//
//  Created by Jack Newcombe on 13/04/2018.
//  Copyright © 2018 Jack Newcombe. All rights reserved.
//

import Foundation

typealias PipeCompletion = ([String]) -> Void
typealias TerminationCompletion = (Int) -> Void

/// Creates a Pipe for handling stdout
///
/// Returns: a pipe object with a handler that passes data to the parser
func setupPipes(task: Process,
                outputHandler: @escaping PipeCompletion = { _ in },
                errorHandler: @escaping PipeCompletion = { _ in },
                terminationHandler: @escaping TerminationCompletion = { _ in}) {
    
    let lockQueue = DispatchQueue(label: "Purr.XcodebuildRunner.DispatchQueue")

    var latest = ""
    let outputPipe = Pipe()
    outputPipe.fileHandleForReading.readabilityHandler = { pipe in
        lockQueue.sync {
           if let newOutput = String(data: pipe.availableData, encoding: .utf8) {
                guard newOutput.count > 0 else {
                    pipe.closeFile()
                    return
                }
                var fullOutput = (latest + newOutput).components(separatedBy: "\n")
                guard fullOutput.count > 1 else {
                    latest += newOutput
                    return
                }
                let last = fullOutput.removeLast()
                outputHandler(fullOutput)
                latest = last
            } else {
                print("Error decoding output data: \(pipe.availableData)")
            }
        }
        
    }
    task.standardOutput = outputPipe

    
    var latestError = ""
    let errorPipe = Pipe()
    errorPipe.fileHandleForReading.readabilityHandler = { pipe in
        lockQueue.sync {
            if let newOutput = String(data: pipe.availableData, encoding: .utf8) {
                guard newOutput.count > 0 else {
                    return
                }
                var fullOutput = (latestError + newOutput).components(separatedBy: CharacterSet(arrayLiteral: "\n", "\r"))
                let last = fullOutput.removeLast()
                errorHandler(fullOutput)
                latestError = last
            } else {
                print("Error decoding error data: \(pipe.availableData)")
            }
        }
    }
    task.standardError = errorPipe
    
    let _terminationHandler = { (task: Process) in
        lockQueue.sync {
//            if latest.count > 0 {
//                outputHandler(latest.components(separatedBy: "\n"))
//            }
            if latestError.count > 0 {
                errorHandler(latestError.components(separatedBy: "\n"))
            }
            terminationHandler(Int(task.terminationStatus))
        }
    }
    task.terminationHandler = _terminationHandler
}
