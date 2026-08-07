//
//  Transaction+XdrJson.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 06.08.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import Foundation

/// XDR-JSON conversion for the transaction bodies the generator does not emit.
///
/// These three types are hand-maintained in this SDK because they carry signing and
/// envelope conveniences, so their conversions are written here. The JSON they produce is
/// the ordinary struct shape of
/// [SEP-0051](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0051.md)
/// §Struct: object keys in XDR declaration order, under the .x field names.
///
/// The extension point each of them ends with is a void-only union that this SDK stores as
/// a constant, so it renders as the arm string `v0` and reads back through the union's own
/// conversion.
extension TransactionV0XDR: XdrJsonCodable {
    public func toXdrJsonValue() throws -> XdrJsonValue {
        var members: [XdrJsonMember] = []
        members.append(XdrJsonMember(
            key: "source_account_ed25519",
            value: try XdrJson.hex(Data(self.sourceAccountEd25519), expectedLength: 32,
                                   type: "TransactionV0XDR", key: "source_account_ed25519")))
        members.append(XdrJsonMember(key: "fee", value: XdrJson.uint32(self.fee)))
        members.append(XdrJsonMember(key: "seq_num", value: XdrJson.int64(self.seqNum)))
        members.append(XdrJsonMember(
            key: "time_bounds",
            value: XdrJson.optional(try self.timeBounds.map { element in try element.toXdrJsonValue() })))
        members.append(XdrJsonMember(key: "memo", value: try self.memo.toXdrJsonValue()))
        members.append(XdrJsonMember(
            key: "operations",
            value: XdrJson.array(try self.operations.map { element in try element.toXdrJsonValue() })))
        members.append(XdrJsonMember(key: "ext", value: .string("v0")))
        return .object(members)
    }

    public static func fromXdrJsonValue(_ value: XdrJsonValue) throws -> TransactionV0XDR {
        let members = try XdrJson.object(
            value, type: "TransactionV0XDR",
            keys: ["source_account_ed25519", "fee", "seq_num", "time_bounds", "memo",
                   "operations", "ext"])

        let sourceAccountEd25519 = try XdrJson.hex(
            try XdrJson.field(members, key: "source_account_ed25519", type: "TransactionV0XDR"),
            expectedLength: 32, type: "TransactionV0XDR", key: "source_account_ed25519")
        let fee = try XdrJson.uint32(
            try XdrJson.field(members, key: "fee", type: "TransactionV0XDR"),
            type: "TransactionV0XDR", key: "fee")
        let seqNum = try XdrJson.int64(
            try XdrJson.field(members, key: "seq_num", type: "TransactionV0XDR"),
            type: "TransactionV0XDR", key: "seq_num")

        let timeBoundsValue = try XdrJson.field(members, key: "time_bounds", type: "TransactionV0XDR")
        let timeBounds: TimeBoundsXDR?
        if timeBoundsValue.isNull {
            timeBounds = nil
        } else {
            timeBounds = try TimeBoundsXDR.fromXdrJsonValue(timeBoundsValue)
        }

        let memo = try MemoXDR.fromXdrJsonValue(
            try XdrJson.field(members, key: "memo", type: "TransactionV0XDR"))
        let operationValues = try XdrJson.array(
            try XdrJson.field(members, key: "operations", type: "TransactionV0XDR"),
            type: "TransactionV0XDR", key: "operations")
        let operations = try operationValues.map { element in try OperationXDR.fromXdrJsonValue(element) }
        _ = try TransactionV0XDRExtXDR.fromXdrJsonValue(
            try XdrJson.field(members, key: "ext", type: "TransactionV0XDR"))

        return TransactionV0XDR(sourceAccountEd25519: [UInt8](sourceAccountEd25519), fee: fee,
                                seqNum: seqNum, timeBounds: timeBounds, memo: memo,
                                operations: operations)
    }
}

extension TransactionV0XDR {
    /// Restores every field as read, which the public initializer cannot: that one derives
    /// the fee from an operation count rather than taking it.
    init(sourceAccountEd25519: [UInt8], fee: UInt32, seqNum: Int64, timeBounds: TimeBoundsXDR?,
         memo: MemoXDR, operations: [OperationXDR]) {
        self.sourceAccountEd25519 = sourceAccountEd25519
        self.fee = fee
        self.seqNum = seqNum
        self.timeBounds = timeBounds
        self.memo = memo
        self.operations = operations
        self.reserved = 0
    }
}

extension TransactionXDR: XdrJsonCodable {
    public func toXdrJsonValue() throws -> XdrJsonValue {
        var members: [XdrJsonMember] = []
        members.append(XdrJsonMember(key: "source_account",
                                     value: try self.sourceAccount.toXdrJsonValue()))
        members.append(XdrJsonMember(key: "fee", value: XdrJson.uint32(self.fee)))
        members.append(XdrJsonMember(key: "seq_num", value: XdrJson.int64(self.seqNum)))
        members.append(XdrJsonMember(key: "cond", value: try self.cond.toXdrJsonValue()))
        members.append(XdrJsonMember(key: "memo", value: try self.memo.toXdrJsonValue()))
        members.append(XdrJsonMember(
            key: "operations",
            value: XdrJson.array(try self.operations.map { element in try element.toXdrJsonValue() })))
        members.append(XdrJsonMember(key: "ext", value: try self.ext.toXdrJsonValue()))
        return .object(members)
    }

    public static func fromXdrJsonValue(_ value: XdrJsonValue) throws -> TransactionXDR {
        let members = try XdrJson.object(
            value, type: "TransactionXDR",
            keys: ["source_account", "fee", "seq_num", "cond", "memo", "operations", "ext"])

        let sourceAccount = try MuxedAccountXDR.fromXdrJsonValue(
            try XdrJson.field(members, key: "source_account", type: "TransactionXDR"))
        let fee = try XdrJson.uint32(
            try XdrJson.field(members, key: "fee", type: "TransactionXDR"),
            type: "TransactionXDR", key: "fee")
        let seqNum = try XdrJson.int64(
            try XdrJson.field(members, key: "seq_num", type: "TransactionXDR"),
            type: "TransactionXDR", key: "seq_num")
        let cond = try PreconditionsXDR.fromXdrJsonValue(
            try XdrJson.field(members, key: "cond", type: "TransactionXDR"))
        let memo = try MemoXDR.fromXdrJsonValue(
            try XdrJson.field(members, key: "memo", type: "TransactionXDR"))
        let operationValues = try XdrJson.array(
            try XdrJson.field(members, key: "operations", type: "TransactionXDR"),
            type: "TransactionXDR", key: "operations")
        let operations = try operationValues.map { element in try OperationXDR.fromXdrJsonValue(element) }
        let ext = try TransactionExtXDR.fromXdrJsonValue(
            try XdrJson.field(members, key: "ext", type: "TransactionXDR"))

        var transaction = TransactionXDR(sourceAccount: sourceAccount, seqNum: seqNum, cond: cond,
                                         memo: memo, operations: operations, maxOperationFee: 0,
                                         ext: ext)
        transaction.fee = fee
        return transaction
    }
}

extension FeeBumpTransactionXDR: XdrJsonCodable {
    public func toXdrJsonValue() throws -> XdrJsonValue {
        var members: [XdrJsonMember] = []
        members.append(XdrJsonMember(key: "fee_source",
                                     value: try self.sourceAccount.toXdrJsonValue()))
        members.append(XdrJsonMember(key: "fee",
                                     value: XdrJson.int64(Int64(bitPattern: self.fee))))
        members.append(XdrJsonMember(key: "inner_tx", value: try self.innerTx.toXdrJsonValue()))
        members.append(XdrJsonMember(key: "ext", value: .string("v0")))
        return .object(members)
    }

    public static func fromXdrJsonValue(_ value: XdrJsonValue) throws -> FeeBumpTransactionXDR {
        let members = try XdrJson.object(
            value, type: "FeeBumpTransactionXDR",
            keys: ["fee_source", "fee", "inner_tx", "ext"])

        let sourceAccount = try MuxedAccountXDR.fromXdrJsonValue(
            try XdrJson.field(members, key: "fee_source", type: "FeeBumpTransactionXDR"))
        let fee = UInt64(bitPattern: try XdrJson.int64(
            try XdrJson.field(members, key: "fee", type: "FeeBumpTransactionXDR"),
            type: "FeeBumpTransactionXDR", key: "fee"))
        let innerTx = try FeeBumpTransactionXDRInnerTxXDR.fromXdrJsonValue(
            try XdrJson.field(members, key: "inner_tx", type: "FeeBumpTransactionXDR"))
        _ = try FeeBumpTransactionXDRExtXDR.fromXdrJsonValue(
            try XdrJson.field(members, key: "ext", type: "FeeBumpTransactionXDR"))

        return FeeBumpTransactionXDR(sourceAccount: sourceAccount, innerTx: innerTx, fee: fee)
    }
}
