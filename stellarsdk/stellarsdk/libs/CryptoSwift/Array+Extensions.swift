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

internal extension Array where Element == UInt8 {

    func toHexString() -> String {
        return `lazy`.reduce("") {
            var s = String($1, radix: 16)
            if s.count == 1 {
                s = "0" + s
            }
            return $0 + s
        }
    }
}

internal extension Array where Element == UInt8 {

    func md5() -> [Element] {
        return Digest.md5(self)
    }

    func sha1() -> [Element] {
        return Digest.sha1(self)
    }

    func sha224() -> [Element] {
        return Digest.sha224(self)
    }

    func sha256() -> [Element] {
        return Digest.sha256(self)
    }

    func sha384() -> [Element] {
        return Digest.sha384(self)
    }

    func sha512() -> [Element] {
        return Digest.sha512(self)
    }

    func sha2(_ variant: SHA2.Variant) -> [Element] {
        return Digest.sha2(self, variant: variant)
    }

    func sha3(_ variant: SHA3.Variant) -> [Element] {
        return Digest.sha3(self, variant: variant)
    }

    func crc32(seed: UInt32? = nil, reflect: Bool = true) -> UInt32 {
        return Checksum.crc32(self, seed: seed, reflect: reflect)
    }

    func crc16(seed: UInt16? = nil) -> UInt16 {
        return Checksum.crc16(self, seed: seed)
    }

    func encrypt(cipher: Cipher) throws -> [Element] {
        return try cipher.encrypt(slice)
    }

    func decrypt(cipher: Cipher) throws -> [Element] {
        return try cipher.decrypt(slice)
    }

    func authenticate<A: Authenticator>(with authenticator: A) throws -> [Element] {
        return try authenticator.authenticate(self)
    }
}
