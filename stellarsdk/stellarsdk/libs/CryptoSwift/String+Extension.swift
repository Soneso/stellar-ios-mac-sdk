//
//  CryptoSwift
//
//  Copyright (C) 2014-2017 Marcin Krzyżanowski <marcin@krzyzanowskim.com>
//  This software is provided 'as-is', without any express or implied warranty.
//
//  In no event will the authors be held liable for any damages arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,including commercial applications, and to alter it and redistribute it freely, subject to the following restrictions:
//
//  - The origin of this software must not be misrepresented; you must not claim that you wrote the original software. If you use this software in a product, an acknowledgment in the product documentation is required.
//  - Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
//  - This notice may not be removed or altered from any source or binary distribution.
//

/** String extension */
extension String {

    internal var bytes: Array<UInt8> {
        return data(using: String.Encoding.utf8, allowLossyConversion: true)?.bytes ?? Array(utf8)
    }

    internal func md5() -> String {
        return bytes.md5().toHexString()
    }

    internal func sha1() -> String {
        return bytes.sha1().toHexString()
    }

    internal func sha224() -> String {
        return bytes.sha224().toHexString()
    }

    internal func sha256() -> String {
        return bytes.sha256().toHexString()
    }

    internal func sha384() -> String {
        return bytes.sha384().toHexString()
    }

    internal func sha512() -> String {
        return bytes.sha512().toHexString()
    }

    internal func sha3(_ variant: SHA3.Variant) -> String {
        return bytes.sha3(variant).toHexString()
    }

    internal func crc32(seed: UInt32? = nil, reflect: Bool = true) -> String {
        return bytes.crc32(seed: seed, reflect: reflect).bytes().toHexString()
    }

    internal func crc16(seed: UInt16? = nil) -> String {
        return bytes.crc16(seed: seed).bytes().toHexString()
    }

    /// - parameter cipher: Instance of `Cipher`
    /// - returns: hex string of bytes
    internal func encrypt(cipher: Cipher) throws -> String {
        return try bytes.encrypt(cipher: cipher).toHexString()
    }

    /// - parameter cipher: Instance of `Cipher`
    /// - returns: base64 encoded string of encrypted bytes
    internal func encryptToBase64(cipher: Cipher) throws -> String? {
        return try bytes.encrypt(cipher: cipher).toBase64()
    }

    // decrypt() does not make sense for String

    /// - parameter authenticator: Instance of `Authenticator`
    /// - returns: hex string of string
    internal func authenticate<A: Authenticator>(with authenticator: A) throws -> String {
        return try bytes.authenticate(with: authenticator).toHexString()
    }
}
