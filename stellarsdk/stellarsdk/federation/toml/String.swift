/*
 * Copyright 2016-2018 JD Fergason
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Foundation

func getUnicodeChar(unicode: String) throws -> String {
    // check if it's a valid character
    let code = Int(strtoul(unicode, nil, 16))

    if code < 0x0 || (code > 0xD7FF && code < 0xE000) || code > 0x10FFFF {
        throw TomlError.InvalidUnicodeCharacter(code)
    }

    return String(describing: UnicodeScalar(code)!)
}

func checkEscape(char: Character, escape: inout Bool) throws -> (String, Int) {
    var unicodeSize = -1
    var s: String = ""

    switch char {
        case "n":
            s = "\n"
            escape = false
        case "\\":
            s = "\\"
            escape = false
        case "\"":
            s = "\""
            escape = false
        case "f":
            s = "\u{000C}"
            escape = false
        case "b":
            s = "\u{0008}"
            escape = false
        case "t":
            s = "\t"
            escape = false
        case "r":
            s = "\r"
            escape = false
        case "u":
            unicodeSize = 4
        case "U":
            unicodeSize = 8
        default:
            throw TomlError.InvalidEscapeSequence("\\" + String(describing: char))
    }

    return (s, unicodeSize)
}

extension String {
    func trim() -> String {
        return self.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
    }

    func stripLineContinuation() -> String {
        var s = self
        let regex = try! NSRegularExpression(pattern: "\\\\(\\s+)",
            options: [.dotMatchesLineSeparators])
        let matches = regex.matches(in: s, options: [],
            range: NSMakeRange(0, s.utf16.count))
        let nss = NSString(string: s)

        for match in matches {
            let m0 = nss.substring(with: match.range(at: 0))
            s = s.replacingOccurrences(of: m0, with: "")
        }

        return s
    }

    func replaceEscapeSequences() throws -> String {
        var s = "" // new string that is being constructed
        var escape = false
        var unicode = ""
        var unicodeSize = -1

        for char in self {
            if escape {
                if unicodeSize == 0 {
                    s += try getUnicodeChar(unicode: unicode)
                    s += String(describing: char)

                    escape = false
                    unicodeSize = -1
                    unicode = ""
                } else if unicodeSize > 0 {
                    unicodeSize -= 1
                    unicode += String(describing: char)
                } else {
                    let (newChar, size) = try checkEscape(char: char, escape: &escape)
                    s += newChar
                    unicodeSize = size
                }
            } else if char == "\\" {
                escape = true
            } else {
                s += String(describing: char)
            }
        }

        if unicodeSize == 0 {
            s += try getUnicodeChar(unicode: unicode)
        }

        return s
    }
}

// Mark: String related array extensions

func quoted(_ value: String) -> String {
    if let _ = value.match(".*[\\u0020-\\u002B\\u002E-\\u002F\\u003A-\\u0040" +
        "\\u005B-\\u005E\\u0060\\u007B-\\uFFFF]+.*") {
        return "\"\(value)\""
    }

    return value
}

/**
    Escape the string according to the rules of a single line Toml string

    - Parameters string: The string to escape

    - Returns: Escaped version of the string
*/
func escape(string: String) -> String {
    var result: String
    let escapeMap = ["\n": "\\n", "\r": "\\r", "\t": "\\t", "\"": "\\\""]

    // must escape \ first because it is the escape character
    result = string.replacingOccurrences(of: "\\", with: "\\\\")
    for (key, val) in escapeMap {
        result = result.replacingOccurrences(of: key, with: val)
    }

    return result
}
