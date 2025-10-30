//
//  Data+CRC.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 29/01/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/**
 CRC-CCITT (XModem)
 [http://www.lammertbies.nl/comm/info/crc-calculation.html]()
 
 [http://web.mit.edu/6.115/www/amulet/xmodem.htm]()
 */
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


extension UInt8 {
    func crc16() -> UInt16 {
        return CRCCCITTXModem(Data([self]))
    }
}


extension Data {
    func crc16() -> UInt16 {
        return CRCCCITTXModem(self)
    }
    
    func crcValid() -> Bool {
        return CRCCCITTXModem(subdata(in: 0..<count-CryptographicConstants.CRC16_SIZE)) == self.subdata(in: count-CryptographicConstants.CRC16_SIZE..<count).withUnsafeBytes { $0.pointee }
    }
    
    func crc16Data() -> Data {
        var crc = crc16()
        let crcData = Data(bytes: &crc, count: MemoryLayout.size(ofValue: crc))
        
        let checksumedData = NSMutableData(data: self)
        checksumedData.append(crcData)
        
        return checksumedData as Data
    }
    
}
