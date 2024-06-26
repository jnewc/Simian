//
//  TableBuilder.swift
//
//
//  Created by Jack Newcombe on 26/06/2024.
//

import Foundation

public enum TableRow {
    case values(lines: [String])
    case separator
    
    
    public var lines: [String]? {
        switch self {
        case .values(let lines): return lines
        default: return nil
        }
    }
}

public struct ColumnConfig {
    public enum Alignment {
        case left
        case right
        case justify
    }
    
    public let alignment: Alignment
}

public class TableBuilder {
    
    let characters: TableCharacters
    
    public init(characters: TableCharacters = .doubleLined) {
        self.characters = characters
    }

    private func columnWidths(for data: [TableRow]) -> [Int] {
        
        let stringRows = data.compactMap({ $0.lines })
        let columns = stringRows.count
        
        let columnWidths = Array(repeating: 0, count: stringRows.first!.count)
        return (0..<columns).reduce(columnWidths) { result, column in
            let rowData = stringRows[column]
            var newResult = result
            rowData.forEach { value in
                let index = rowData.firstIndex(of: value)!
                let valueCount = value.clearAll.utf16.count
                if  valueCount > newResult[index] {
                    newResult[index] = valueCount
                }
            }
            return newResult
        }
    }
    
    
    private func separatorRow(columnWidths: [Int], left: String, right: String, character: String, separator: String) -> String {
        let bars = columnWidths.map { width in String(repeating: character, count: width + 2) }
        return "\(left)\(bars.joined(separator: separator))\(right)"
    }
    
    private func firstSeparatorRow(columnWidths: [Int]) -> String {
        return separatorRow(
            columnWidths: columnWidths,
            left: characters.cornerTopLeft,
            right: characters.cornerTopRight,
            character: characters.outerHorizontal,
            separator: characters.horizontalDown
        )
    }
    
    private func lastSeparatorRow(columnWidths: [Int]) -> String {
        return separatorRow(
            columnWidths: columnWidths,
            left: characters.cornerBottomLeft,
            right: characters.cornerBottomRight,
            character: characters.outerHorizontal,
            separator: characters.horizontalUp
        )
    }
    
    private func middleRow(columnWidths: [Int]) -> String {
        return separatorRow(
            columnWidths: columnWidths,
            left: characters.verticalLeft,
            right: characters.verticalRight,
            character: characters.horizontal,
            separator: characters.center
        )
    }

    private func valuesRow(columnWidths: [Int], values: [String], columns: [ColumnConfig]) -> String {
        
        let strings = values.enumerated().map { (index, string) -> String in
            let count = columnWidths[values.firstIndex(of: string)!]
            if string.clearAll.utf16.count > count {
                return " \(string) "
            }
            
            let width = count - string.clearAll.utf16.count
            let spaces = String(repeating: " ", count: width)
            
            switch (columns[safe: index]?.alignment ?? .left) {
            case .left:
                return " \(string)\(spaces) "
            case .right:
                return " \(spaces)\(string) "
            case .justify:
                let words = string.split(separator: " ")
                if words.count == 1 {
                    return " \(words[0])\(spaces) "
                }
                
                var widthCount = width + 1
                let spaceSize: Int = (width / (words.count - 1)) + 1

                var fullString = ""
                for word in words {
                    fullString += word
                    for _ in 0..<spaceSize {
                        if widthCount > 0 {
                            fullString += " "
                            widthCount -= 1
                        }
                    }
                }
                
                return " \(fullString) "
            }
        }
        
        let v = characters.vertical
        return "\(characters.outerVertical)\(strings.joined(separator: v))\(characters.outerVertical)"
        
    }
    
    public func build(with data: [TableRow], columns: [ColumnConfig] = []) -> String {
        
        var lines = [String]()
  
        let widths = columnWidths(for: data)
        
        lines.append(firstSeparatorRow(columnWidths: widths))
        
        data.forEach { row in
            switch row {
            case .separator:
                lines.append(middleRow(columnWidths: widths)); return
            case .values(let values):
                lines.append(valuesRow(columnWidths: widths, values: values, columns: columns))
            }
        }
        
        lines.append(lastSeparatorRow(columnWidths: widths))
        
        return lines.joined(separator: "\n")
    }
    
    // Helpers
    
    public static func build(from dict: [String: String]) -> String {
        let rows: [TableRow] = dict.map { k, v in TableRow.values(lines: [k, v]) }
        return TableBuilder().build(with: rows)
    }
    
}

extension Collection {

    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

public struct TableCharacters {
    
    let cornerTopLeft: String
    
    let cornerTopRight: String
    
    let cornerBottomLeft: String
    
    let cornerBottomRight: String
    
    let horizontalDown: String
    
    let horizontalUp: String
    
    let verticalLeft: String
    
    let verticalRight: String
    
    let horizontal: String
    
    let vertical: String
    
    let outerHorizontal: String
    
    let outerVertical: String
    
    let center: String
    
    public static let doubleLined = TableCharacters(
        cornerTopLeft: "╔",
        cornerTopRight: "╗",
        cornerBottomLeft: "╚",
        cornerBottomRight: "╝",
        horizontalDown: "╦",
        horizontalUp: "╩",
        verticalLeft: "╠",
        verticalRight: "╣",
        horizontal: "═",
        vertical: "║",
        outerHorizontal: "═",
        outerVertical: "║",
        center: "╬"
    )
    
    public static let doubleLinedWithSingleLinedInterior = TableCharacters(
        cornerTopLeft: "╔",
        cornerTopRight: "╗",
        cornerBottomLeft: "╚",
        cornerBottomRight: "╝",
        horizontalDown: "╤",
        horizontalUp: "╧",
        verticalLeft: "╟",
        verticalRight: "╢",
        horizontal: "─",
        vertical: "│",
        outerHorizontal: "═",
        outerVertical: "║",
        center: "┼"
    )
    
    public static let singleLined = TableCharacters(
        cornerTopLeft: "┌",
        cornerTopRight: "┐",
        cornerBottomLeft: "└",
        cornerBottomRight: "┘",
        horizontalDown: "┴",
        horizontalUp: "┬",
        verticalLeft: "├",
        verticalRight: "┤",
        horizontal: "─",
        vertical: "│",
        outerHorizontal: "─",
        outerVertical: "│",
        center: "┼"
    )
    
    public static let singleLinedCurved = TableCharacters(
        cornerTopLeft: "╭",
        cornerTopRight: "╮",
        cornerBottomLeft: "╰",
        cornerBottomRight: "╯",
        horizontalDown: "┴",
        horizontalUp: "┬",
        verticalLeft: "├",
        verticalRight: "┤",
        horizontal: "─",
        vertical: "│",
        outerHorizontal: "─",
        outerVertical: "│",
        center: "┼"
    )
    
    public static let empty = TableCharacters(
        cornerTopLeft: "",
        cornerTopRight: "",
        cornerBottomLeft: "",
        cornerBottomRight: "",
        horizontalDown: "",
        horizontalUp: "",
        verticalLeft: "",
        verticalRight: "",
        horizontal: "",
        vertical: "",
        outerHorizontal: "",
        outerVertical: "",
        center: ""
    )
}
