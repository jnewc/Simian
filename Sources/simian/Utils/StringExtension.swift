//
//  StringExtension.swift
//
//  Created by Jack Newcombe on 13/11/2016.
//

import Foundation
import Regex

public extension String {

    // MARK: Properties

    /// String with all whitespace removed from beginning and end
    var trimmed: String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func trimming(charactersIn string: String) -> String {
        return trimmingCharacters(in: CharacterSet(charactersIn: string))
    }
    
    /// All characters in the word up to the first space
    var firstWord: String {
        return self.components(separatedBy: " ").first!
    }

    var secondWord: String {
        let components = self.components(separatedBy: " ")
        if components.count > 1 {
            return components[1]
        }
        return ""
    }

    /// All characters in the word following the last space
    var lastWord: String {
        return self.components(separatedBy: " ").last!
    }
    
    /// All characters in the word following the second to last space
    var secondLastWord: String {
        let components = self.components(separatedBy: " ")
        if (components.count > 1) {
            return components[components.count - 2]
        }
        return ""
    }
    
    var removingFirstWord: String {
        var components = components(separatedBy: " ")
        components.removeFirst()
        return components.joined(separator: " ")
    }

    func word(at index: Int) -> String {
        let components = self.components(separatedBy: " ")
        let _index = index >= 0 ? index : components.count + index
        if (components.count > _index) {
            return components[_index]
        }
        return ""
    }

    var lines: [String] {
        return self.components(separatedBy: "\n")
    }
    /// All characters in the word up to the first newline
    var firstLine: String? {
        return self.lines.first
    }
    
    var lastLine: String? {
        return self.lines.last
    }
    
    var isWhitespace: Bool {
        return "^[\\s+]+$".r?.matches(self) ?? false
    }

    /// All characters after the final backslash
    /// If no backslash is found, the original string is returned
    var filename: String {
        if self.contains("/") {
            return self.components(separatedBy: "/").last!
        }
        return self
    }

    // MARK: Functions
    
    func remove(_ input: String) -> String {
        var result = self
        for c in input {
            result = result.replacingOccurrences(of: String(c), with: "")
        }
        return result
    }

    func between(start: String, end: String) -> String? {

        let components = self.components(separatedBy: start)

        if start == end {
         return components.count == 3 ? components[1] : nil
        }

        if components.count != 2 { return nil }

        let endComponents = components[1].components(separatedBy: end)
        if endComponents.count != 2 { return nil }

        return endComponents.first!
    }

    func contains(oneOf strings: [String]) -> Bool {
        return strings.filter({ self.contains($0) }).count > 0
    }

    func pad(startWith string: String) -> String {
        return "\(string)\(self)"
    }

    func pad(endWith string: String) -> String {
        return "\(self)\(string)"
    }
    
    func pad(with string: String) -> String {
        return pad(startWith: pad(endWith: string))
    }
    
    func components(separatedByCharactersIn characters: String) -> [String] {
        return components(separatedBy: CharacterSet(charactersIn: characters))
    }

}

// MARK: Colors

extension String {
    
    public enum Color: Int, Codable {
        
        static var enabled = true
        
        case black = 30
        case red
        case green
        case yellow
        case blue
        case magenta
        case cyan
        case white
                
        case gray = 90
        case lightRed
        case lightGreen
        case lightYellow
        case lightBlue
        case lightMagenta
        case lightCyan
        case lightWhite
        
    }
    
    public enum BackgroundColor: Int, Codable {
        // Enabled via Color
        
        case black = 40
        case green
        case yellow
        case blue
        case magenta
        case cyan
        case white
    }
    
    public func apply(color: Color) -> String {
        apply(colorCode: color.rawValue)
    }
    
    public func apply(backgroundColor: BackgroundColor) -> String {
        apply(colorCode: backgroundColor.rawValue)
    }
    
    private func apply(colorCode: Int) -> String {
        guard Color.enabled else { return self }
        return "\u{1b}[\(colorCode)m\(self)\u{1b}[0m"
    }
    
    /// Remove all console styling
    public var clearAll: String {
        var string = self
        var codes: [String] = []
        for index in 0...255  { codes.append("\u{1b}[\(index)m")}

        codes.forEach {
            string = string.replacingOccurrences(of: $0, with: "")
        }

        return string
    }
    
    // MARK: Color Shortcuts
    
    public var black: String { apply(color: .black) }
    public var white: String { apply(color: .white) }
    public var red: String { apply(color: .red) }
    public var green: String { apply(color: .green) }
    public var blue: String { apply(color: .blue) }
    public var yellow: String { apply(color: .yellow) }
    public var magenta: String { apply(color: .magenta) }
    public var cyan: String { apply(color: .cyan) }
    public var gray: String { apply(color: .gray) }
    
    public var lightRed: String { apply(color: .lightRed) }
    public var lightGreen: String { apply(color: .lightGreen) }
    public var lightYellow: String { apply(color: .lightYellow) }
    public var lightBlue: String { apply(color: .lightBlue) }
    public var lightMagenta: String { apply(color: .lightMagenta) }
    public var lightCyan: String { apply(color: .lightCyan) }
    
    // MARK: Decorator shortcuts
    
    enum Style: Int {
        static var enabled = true
        
        case bold = 1
        case italic = 3
        case underline = 4
        case blink = 5
    }
    
    func apply(style: Style) -> String {
        guard Style.enabled else { return self }
        return "\u{1b}[\(style.rawValue)m\(self)\u{1b}[0m"
    }
    
    public var bold: String { "\u{1b}[1m\(self)\u{1b}[0m" }
    public var italic: String { "\u{1b}[3m\(self)\u{1b}[0m" }
    public var underline: String { "\u{1b}[4m\(self)\u{1b}[0m" }
}


// MARK: Substrings

extension Substring {
    var string: String {
        return String(self)
    }
}


// MARK: NatLang access

//private struct StringWithout {
//    let string: String
//
//    var trailingWhitespace: String {
//        return string
//    }
//}
//
//extension String {
//    var without: StringWithout {
//        return StringWithout(string: self)
//    }
//}
