//
//  Data+CRC.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 29/01/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Computes CRC-CCITT checksum using XModem variant.
///
/// This implementation follows the CRC-CCITT (XModem) standard used in Stellar's
/// StrKey encoding for error detection.
///
/// See:
/// - [CRC Calculation](http://www.lammertbies.nl/comm/info/crc-calculation.html)
/// - [XModem Protocol](http://web.mit.edu/6.115/www/amulet/xmodem.htm)
private func CRCCCITTXModem(_ bytes: Data) -> UInt16 {
    var crc: UInt16 = CryptographicConstants.CRC16_INITIAL

    for byte in bytes {
        crc ^= UInt16(byte) << 8

        for _ in 0..<CryptographicConstants.CRC16_ITERATIONS {
            if crc & CryptographicConstants.CRC16_HIGH_BIT_MASK != 0 {
                crc = crc << 1 ^ CryptographicConstants.CRC16_POLYNOMIAL
            } else {
                crc = crc << 1
            }
        }
    }

    return crc
}


/// Extension providing CRC16 checksum functionality for UInt8.
extension UInt8 {
    /// Computes the CRC16 checksum of this byte.
    ///
    /// - Returns: CRC16 checksum value
    func crc16() -> UInt16 {
        return CRCCCITTXModem(Data([self]))
    }
}

/// Extension providing CRC16 checksum functionality for Data.
///
/// These methods are used in Stellar's StrKey encoding to add and verify checksums
/// for error detection in encoded keys and addresses.
extension Data {
    /// Computes the CRC16 checksum of the data.
    ///
    /// - Returns: CRC16 checksum value
    func crc16() -> UInt16 {
        return CRCCCITTXModem(self)
    }

    /// Validates the CRC16 checksum of the data.
    ///
    /// Assumes the last 2 bytes of the data are the checksum and verifies it against
    /// the computed checksum of the remaining bytes.
    ///
    /// - Returns: True if the checksum is valid, false otherwise
    func crcValid() -> Bool {
        return CRCCCITTXModem(subdata(in: 0..<count-CryptographicConstants.CRC16_SIZE)) == self.subdata(in: count-CryptographicConstants.CRC16_SIZE..<count).withUnsafeBytes { $0.pointee }
    }

    /// Appends CRC16 checksum to the data.
    ///
    /// Computes the CRC16 checksum and appends it to the end of the data.
    /// This is used in StrKey encoding.
    ///
    /// - Returns: Data with appended checksum
    func crc16Data() -> Data {
        var crc = crc16()
        let crcData = Data(bytes: &crc, count: MemoryLayout.size(ofValue: crc))

        let checksumedData = NSMutableData(data: self)
        checksumedData.append(crcData)

        return checksumedData as Data
    }

}
