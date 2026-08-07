# frozen_string_literal: true

require 'set'

# Type-level SEP-0051 (XDR-JSON) conversions for the types the mapping rules do not reach.
#
# SEP-0051 gives a handful of Stellar types a form that no structural rule produces: the
# account, contract, pool, claimable-balance and signer types render as strkeys, the asset
# codes render as trimmed escaped text, and the four integer-parts structs render as one
# base-10 decimal. Each such type supplies its own conversion body here and the generator
# emits it in place of the structural one.
#
# Bodies are Swift source at the indentation a function body takes inside a generated
# extension; the generator adds the surrounding declaration and the outer indentation.
module Sep51JsonOverrides
  # Types whose XDR-JSON form is a single JSON string rather than an object or a keyed arm,
  # so they carry no derived field or arm names. tools/sep-51-oracle/emitted_names.rb reads
  # this list to know which types to exclude from the name diff, and checks that each one
  # has genuinely stopped emitting an object.
  STRING_RENDERED = %w[
    PublicKey
    MuxedAccountXDR
    MuxedAccountMed25519XDR
    MuxedAccountXDRMed25519XDR
    SCAddressXDR
    SignerKeyXDR
    Ed25519SignedPayload
    ClaimableBalanceIDXDR
    AllowTrustOpAssetXDR
    Int128PartsXDR
    UInt128PartsXDR
    Int256PartsXDR
    UInt256PartsXDR
  ].freeze

  # Conversions for generated struct and union types, replacing the structural body.
  NOMINAL = {
    'SCAddressXDR' => {
      emit: <<~SWIFT,
        switch self {
        case .account(let account):
          return try account.toXdrJsonValue()
        case .contract(let contract):
          return try ContractIDXDRJsonCodec.toXdrJsonValue(contract, type: "SCAddressXDR", key: "contract")
        case .muxedAccount(let muxedAccount):
          return try muxedAccount.toXdrJsonValue()
        case .claimableBalanceId(let balance):
          return try balance.toXdrJsonValue()
        case .liquidityPoolId(let pool):
          return try PoolIDXDRJsonCodec.toXdrJsonValue(pool, type: "SCAddressXDR", key: "liquidity_pool")
        }
      SWIFT
      read: <<~SWIFT
        let text = try XdrJson.string(value, type: "SCAddressXDR")
        switch text.first {
        case "G":
          return .account(try PublicKey.fromXdrJsonValue(value))
        case "C":
          return .contract(try ContractIDXDRJsonCodec.fromXdrJsonValue(value, type: "SCAddressXDR", key: "contract"))
        case "M":
          return .muxedAccount(try MuxedAccountMed25519XDR.fromXdrJsonValue(value))
        case "B":
          return .claimableBalanceId(try ClaimableBalanceIDXDR.fromXdrJsonValue(value))
        case "L":
          return .liquidityPoolId(try PoolIDXDRJsonCodec.fromXdrJsonValue(value, type: "SCAddressXDR", key: "liquidity_pool"))
        default:
          throw XdrJsonError.invalidValue(
            type: "SCAddressXDR", key: nil,
            message: "not an account, contract, muxed account, claimable balance " +
                     "or liquidity pool strkey: \\(XdrJson.preview(text))")
        }
      SWIFT
    },

    'SignerKeyXDR' => {
      emit: <<~SWIFT,
        switch self {
        case .ed25519(let key):
          return .string(try XdrJson.strKey(key.wrapped, expectedLength: 32,
                                            type: "SignerKeyXDR", key: "ed25519") { try $0.encodeEd25519PublicKey() })
        case .preAuthTx(let key):
          return .string(try XdrJson.strKey(key.wrapped, expectedLength: 32,
                                            type: "SignerKeyXDR", key: "pre_auth_tx") { try $0.encodePreAuthTx() })
        case .hashX(let key):
          return .string(try XdrJson.strKey(key.wrapped, expectedLength: 32,
                                            type: "SignerKeyXDR", key: "hash_x") { try $0.encodeSha256Hash() })
        case .signedPayload(let payload):
          return try payload.toXdrJsonValue()
        }
      SWIFT
      read: <<~SWIFT
        let text = try XdrJson.string(value, type: "SignerKeyXDR")
        switch text.first {
        case "G":
          return .ed25519(Uint256XDR(try XdrJson.strKeyBytes(text, expectedLength: 32,
                                                             type: "SignerKeyXDR", key: "ed25519") { try $0.decodeEd25519PublicKey() }))
        case "T":
          return .preAuthTx(Uint256XDR(try XdrJson.strKeyBytes(text, expectedLength: 32,
                                                               type: "SignerKeyXDR", key: "pre_auth_tx") { try $0.decodePreAuthTx() }))
        case "X":
          return .hashX(Uint256XDR(try XdrJson.strKeyBytes(text, expectedLength: 32,
                                                           type: "SignerKeyXDR", key: "hash_x") { try $0.decodeSha256Hash() }))
        case "P":
          return .signedPayload(try Ed25519SignedPayload.fromXdrJsonValue(value))
        default:
          throw XdrJsonError.invalidValue(
            type: "SignerKeyXDR", key: nil,
            message: "not an account, pre-authorized transaction, hash or signed payload " +
                     "strkey: \\(XdrJson.preview(text))")
        }
      SWIFT
    },

    'Ed25519SignedPayload' => {
      emit: <<~SWIFT,
        guard !self.payload.isEmpty else {
          throw XdrJsonError.unrepresentable(
            type: "Ed25519SignedPayload",
            message: "a signed payload of zero length has no strkey the ecosystem accepts")
        }
        guard self.payload.count <= 64 else {
          throw XdrJsonError.invalidValue(
            type: "Ed25519SignedPayload", key: "payload",
            message: "expected at most 64 bytes, got \\(self.payload.count)")
        }
        guard self.ed25519.wrapped.count == 32 else {
          throw XdrJsonError.invalidValue(
            type: "Ed25519SignedPayload", key: "ed25519",
            message: "expected 32 bytes, got \\(self.ed25519.wrapped.count)")
        }
        let encoded = Data(try XDREncoder.encode(self))
        return .string(try XdrJson.strKey(encoded, expectedLength: encoded.count,
                                          type: "Ed25519SignedPayload", key: nil) { try $0.encodeSignedPayload() })
      SWIFT
      read: <<~SWIFT
        let text = try XdrJson.string(value, type: "Ed25519SignedPayload")
        let decoded: Ed25519SignedPayload
        do {
          decoded = try text.decodeSignedPayload()
        } catch {
          throw XdrJsonError.invalidValue(
            type: "Ed25519SignedPayload", key: nil,
            message: "not a signed payload strkey: \\(XdrJson.preview(text))")
        }
        guard !decoded.payload.isEmpty else {
          throw XdrJsonError.unrepresentable(
            type: "Ed25519SignedPayload",
            message: "a signed payload of zero length has no strkey the ecosystem accepts")
        }
        guard decoded.payload.count <= 64 else {
          throw XdrJsonError.invalidValue(
            type: "Ed25519SignedPayload", key: "payload",
            message: "expected at most 64 bytes, got \\(decoded.payload.count)")
        }
        return decoded
      SWIFT
    },

    'ClaimableBalanceIDXDR' => {
      emit: <<~SWIFT,
        switch self {
        case .claimableBalanceIDTypeV0(let hash):
          guard hash.wrapped.count == 32 else {
            throw XdrJsonError.invalidValue(
              type: "ClaimableBalanceIDXDR", key: "v0",
              message: "expected 32 bytes, got \\(hash.wrapped.count)")
          }
          var raw = Data([UInt8(ClaimableBalanceIDType.claimableBalanceIDTypeV0.rawValue)])
          raw.append(hash.wrapped)
          return .string(try XdrJson.strKey(raw, expectedLength: 33,
                                            type: "ClaimableBalanceIDXDR", key: nil) { try $0.encodeClaimableBalanceId() })
        }
      SWIFT
      read: <<~SWIFT
        let text = try XdrJson.string(value, type: "ClaimableBalanceIDXDR")
        let raw = try XdrJson.strKeyBytes(text, expectedLength: 33,
                                          type: "ClaimableBalanceIDXDR", key: nil) { try $0.decodeClaimableBalanceId() }
        let discriminant = Int32(raw[raw.startIndex])
        guard discriminant == ClaimableBalanceIDType.claimableBalanceIDTypeV0.rawValue else {
          throw XdrJsonError.invalidValue(
            type: "ClaimableBalanceIDXDR", key: nil,
            message: "unknown claimable balance type \\(discriminant)")
        }
        return .claimableBalanceIDTypeV0(HashXDR(Data(raw.dropFirst())))
      SWIFT
    },

    # SEP-0051 §AssetCode renders this union as a bare string rather than as a keyed arm,
    # so the discriminant is recovered from the decoded length: four bytes or fewer is the
    # four-character arm, five to twelve the twelve-character one. The five-byte floor the
    # twelve-character arm keeps on output is what makes that boundary unambiguous.
    'AllowTrustOpAssetXDR' => {
      emit: <<~SWIFT,
        switch self {
        case .alphanum4(let code):
          return try AssetCode4XDRJsonCodec.toXdrJsonValue(code, type: "AllowTrustOpAssetXDR",
                                                           key: "credit_alphanum4")
        case .alphanum12(let code):
          return try AssetCode12XDRJsonCodec.toXdrJsonValue(code, type: "AllowTrustOpAssetXDR",
                                                            key: "credit_alphanum12")
        }
      SWIFT
      read: <<~SWIFT
        let raw = try XdrJson.unescapeString(value, type: "AllowTrustOpAssetXDR")
        if raw.count <= 4 {
          return .alphanum4(AssetCode4XDR(XdrJson.rightPad(raw, to: 4)))
        }
        guard raw.count <= 12 else {
          throw XdrJsonError.invalidValue(
            type: "AllowTrustOpAssetXDR", key: nil,
            message: "expected at most 12 bytes, got \\(raw.count)")
        }
        return .alphanum12(AssetCode12XDR(XdrJson.rightPad(raw, to: 12)))
      SWIFT
    },

    # The med25519 account packs the ed25519 key ahead of the identifier, the reverse of the
    # XDR body, which is the order MuxedAccountMed25519XDRInverted already models.
    'MuxedAccountXDRMed25519XDR' => {
      emit: <<~SWIFT,
        guard self.ed25519.wrapped.count == 32 else {
          throw XdrJsonError.invalidValue(
            type: "MuxedAccountXDRMed25519XDR", key: "ed25519",
            message: "expected 32 bytes, got \\(self.ed25519.wrapped.count)")
        }
        let inverted = MuxedAccountMed25519XDRInverted(
          id: self.id, sourceAccountEd25519: [UInt8](self.ed25519.wrapped))
        let encoded = Data(try XDREncoder.encode(inverted))
        return .string(try XdrJson.strKey(encoded, expectedLength: 40,
                                          type: "MuxedAccountXDRMed25519XDR", key: nil) { try $0.encodeMEd25519AccountId() })
      SWIFT
      read: <<~SWIFT
        let text = try XdrJson.string(value, type: "MuxedAccountXDRMed25519XDR")
        let raw = try XdrJson.strKeyBytes(text, expectedLength: 40,
                                          type: "MuxedAccountXDRMed25519XDR", key: nil) { try $0.decodeMed25519PublicKey() }
        let inverted = try XDRDecoder.decode(MuxedAccountMed25519XDRInverted.self, data: [UInt8](raw))
        return MuxedAccountXDRMed25519XDR(
          id: inverted.id, ed25519: Uint256XDR(Data(inverted.sourceAccountEd25519)))
      SWIFT
    },

    'Int128PartsXDR' => {
      emit: <<~SWIFT,
        return XdrJson.wideDecimal(
          XdrWideInteger.data128(hi: UInt64(bitPattern: self.hi), lo: self.lo), signed: true)
      SWIFT
      read: <<~SWIFT
        let bytes = try XdrJson.wideDecimal(value, bitSize: 128, signed: true, type: "Int128PartsXDR")
        let parts = XdrWideInteger.parts128(from: bytes)
        return Int128PartsXDR(hi: Int64(bitPattern: parts.hi), lo: parts.lo)
      SWIFT
    },

    'UInt128PartsXDR' => {
      emit: <<~SWIFT,
        return XdrJson.wideDecimal(
          XdrWideInteger.data128(hi: self.hi, lo: self.lo), signed: false)
      SWIFT
      read: <<~SWIFT
        let bytes = try XdrJson.wideDecimal(value, bitSize: 128, signed: false, type: "UInt128PartsXDR")
        let parts = XdrWideInteger.parts128(from: bytes)
        return UInt128PartsXDR(hi: parts.hi, lo: parts.lo)
      SWIFT
    },

    'Int256PartsXDR' => {
      emit: <<~SWIFT,
        return XdrJson.wideDecimal(
          XdrWideInteger.data256(hiHi: UInt64(bitPattern: self.hiHi), hiLo: self.hiLo,
                                 loHi: self.loHi, loLo: self.loLo), signed: true)
      SWIFT
      read: <<~SWIFT
        let bytes = try XdrJson.wideDecimal(value, bitSize: 256, signed: true, type: "Int256PartsXDR")
        let parts = XdrWideInteger.parts256(from: bytes)
        return Int256PartsXDR(hiHi: Int64(bitPattern: parts.hiHi), hiLo: parts.hiLo,
                              loHi: parts.loHi, loLo: parts.loLo)
      SWIFT
    },

    'UInt256PartsXDR' => {
      emit: <<~SWIFT,
        return XdrJson.wideDecimal(
          XdrWideInteger.data256(hiHi: self.hiHi, hiLo: self.hiLo,
                                 loHi: self.loHi, loLo: self.loLo), signed: false)
      SWIFT
      read: <<~SWIFT
        let bytes = try XdrJson.wideDecimal(value, bitSize: 256, signed: false, type: "UInt256PartsXDR")
        let parts = XdrWideInteger.parts256(from: bytes)
        return UInt256PartsXDR(hiHi: parts.hiHi, hiLo: parts.hiLo,
                               loHi: parts.loHi, loLo: parts.loLo)
      SWIFT
    }
  }.freeze

  # Conversions for typedefs, replacing the body derived from the typedef's declaration.
  #
  # These are the sites where keying on the declared XDR name earns its keep: ContractID,
  # PoolID and Hash are the same Swift type and have three different wire forms, and
  # AssetCode4, Thresholds and SignatureHint likewise.
  #
  # A body goes into the overload that carries its caller's context, so it reports against
  # the `type` and `key` parameters rather than against the typedef's own name. The two that
  # delegate to `PublicKey` are the exception the delegation itself creates: the failure is
  # raised inside a nominal type that names itself.
  TYPEDEF = {
    'AccountIDXDR' => {
      emit: <<~SWIFT,
        return try value.toXdrJsonValue()
      SWIFT
      read: <<~SWIFT
        return try PublicKey.fromXdrJsonValue(value)
      SWIFT
    },

    'NodeIDXDR' => {
      emit: <<~SWIFT,
        return try value.toXdrJsonValue()
      SWIFT
      read: <<~SWIFT
        return try PublicKey.fromXdrJsonValue(value)
      SWIFT
    },

    'ContractIDXDR' => {
      emit: <<~SWIFT,
        return .string(try XdrJson.strKey(value.wrapped, expectedLength: 32,
                                          type: type, key: key) { try $0.encodeContractId() })
      SWIFT
      read: <<~SWIFT
        let text = try XdrJson.string(value, type: type, key: key)
        return ContractIDXDR(try XdrJson.strKeyBytes(text, expectedLength: 32,
                                                     type: type, key: key) { try $0.decodeContractId() })
      SWIFT
    },

    'PoolIDXDR' => {
      emit: <<~SWIFT,
        return .string(try XdrJson.strKey(value.wrapped, expectedLength: 32,
                                          type: type, key: key) { try $0.encodeLiquidityPoolId() })
      SWIFT
      read: <<~SWIFT
        let text = try XdrJson.string(value, type: type, key: key)
        return PoolIDXDR(try XdrJson.strKeyBytes(text, expectedLength: 32,
                                                 type: type, key: key) { try $0.decodeLiquidityPoolId() })
      SWIFT
    },

    # Trailing NUL bytes are removed on output and restored on input. The four-character
    # code trims to nothing, so an all-NUL code renders as the empty string.
    'AssetCode4XDR' => {
      emit: <<~SWIFT,
        guard value.wrapped.count == 4 else {
          throw XdrJsonError.invalidValue(
            type: type, key: key,
            message: "expected 4 bytes, got \\(value.wrapped.count)")
        }
        return XdrJson.escapedString(XdrJson.trimTrailingNulls(value.wrapped, keepingAtLeast: 0))
      SWIFT
      read: <<~SWIFT
        let raw = try XdrJson.unescapeString(value, type: type, key: key)
        guard raw.count <= 4 else {
          throw XdrJsonError.invalidValue(
            type: type, key: key,
            message: "expected at most 4 bytes, got \\(raw.count)")
        }
        return AssetCode4XDR(XdrJson.rightPad(raw, to: 4))
      SWIFT
    },

    # The twelve-character code keeps a floor of five bytes after trimming, which is what
    # keeps the two AssetCode arms distinguishable when the union renders as a bare string.
    'AssetCode12XDR' => {
      emit: <<~SWIFT,
        guard value.wrapped.count == 12 else {
          throw XdrJsonError.invalidValue(
            type: type, key: key,
            message: "expected 12 bytes, got \\(value.wrapped.count)")
        }
        return XdrJson.escapedString(XdrJson.trimTrailingNulls(value.wrapped, keepingAtLeast: 5))
      SWIFT
      read: <<~SWIFT
        let raw = try XdrJson.unescapeString(value, type: type, key: key)
        guard raw.count <= 12 else {
          throw XdrJsonError.invalidValue(
            type: type, key: key,
            message: "expected at most 12 bytes, got \\(raw.count)")
        }
        return AssetCode12XDR(XdrJson.rightPad(raw, to: 12))
      SWIFT
    }
  }.freeze

  module_function

  # The types tools/sep-51-oracle/emitted_names.rb excludes from the name diff.
  def type_names = STRING_RENDERED

  def nominal(swift_name) = NOMINAL[swift_name]

  def typedef(swift_name) = TYPEDEF[swift_name]
end
