//
//  Data+B16.swift
//  stellarsdk
//
//  From
//  https://github.com/metabolist/base16
//

import Foundation

public enum Base16EncodingError: Error {
    case invalidLength
    case invalidByteString(String)
    case invalidStringEncoding
}

public extension Data {
    enum Base16EncodingOptions {
        case uppercase
    }

    func base16EncodedString(options: [Base16EncodingOptions] = []) -> String {
        map { String(format: Self.format(options: options), $0) }.joined()
    }

    func base16EncodedData(options: [Base16EncodingOptions] = []) -> Data {
        Data(base16EncodedString(options: options).utf8)
    }

    init(base16Encoded string: String) throws {
        let stringLength = string.count

        guard stringLength % 2 == 0 else {
            throw Base16EncodingError.invalidLength
        }

        var data = [UInt8]()

        data.reserveCapacity(stringLength / 2)

        var i = string.startIndex

        while i != string.endIndex {
            let j = string.index(i, offsetBy: 2)
            let byteString = string[i..<j]

            guard let byte = UInt8(byteString, radix: 16) else {
                throw Base16EncodingError.invalidByteString(String(byteString))
            }

            data.append(byte)
            i = j
        }

        self = Data(data)
    }

    init(base16Encoded data: Data) throws {
        guard let string = String(data: data, encoding: .utf8) else {
            throw Base16EncodingError.invalidStringEncoding
        }

        try self.init(base16Encoded: string)
    }
}

private extension Data {
    static let lowercaseBase16Format = "%02.2hhx"
    static let uppercaseBase16Format = "%02.2hhX"

    static func format(options: [Base16EncodingOptions]) -> String {
        options.contains(.uppercase) ? uppercaseBase16Format : lowercaseBase16Format
    }
}

/*let data = Data([182, 239, 215, 173, 251, 168, 76, 252,
                 140, 7, 39, 163, 56, 255, 171, 35,
                 121, 205, 26, 252, 53, 166, 159, 67,
                 100, 70, 140, 79, 47, 26, 138, 209])

data.base16EncodedString() // returns "b6efd7adfba84cfc8c0727a338ffab2379cd1afc35a69f4364468c4f2f1a8ad1"
data.base16EncodedString(options: [.uppercase]) // returns "B6EFD7ADFBA84CFC8C0727A338FFAB2379CD1AFC35A69F4364468C4F2F1A8AD1"
data.base16EncodedData() // returns the same thing as `base16EncodedString()` as UTF-8 data
data.base16EncodedData(options: [.uppercase]) // returns the same thing as `base16EncodedString(options: [.uppercase])` as UTF-8 data

try Data(base16Encoded: "b6efd7adfba84cfc8c0727a338ffab2379cd1afc35a69f4364468c4f2f1a8ad1") // equivalent to `data` variable above
try Data(base16Encoded: "B6EFD7ADFBA84CFC8C0727A338FFAB2379CD1AFC35A69F4364468C4F2F1A8AD1") // equivalent to `data` variable above
// The above initializers also exist for Base16 encoded UTF-8 `Data`
*/
