//
// GENERATED FILE - DO NOT EDIT
//
// This file was produced by tools/xdr-generator/test/emit_json_tests.rb. It maps the
// type names carried by stellarsdkUnitTests/sep/xdr_json/corpus.json onto the SEP-0051
// (XDR-JSON) conversion of the corresponding Swift type, in both directions, crossing
// the binary codec so one corpus entry pins the JSON text and the XDR bytes together.
// To regenerate, run:
//
//     make xdr-generate-tests
//
// Any manual edits will be overwritten on the next run.
//

import Foundation
import stellarsdk

/// A corpus entry the dispatch cannot serve. Both switches throw rather than skip: a
/// type quietly stepped over is a type the corpus never tested.
enum Sep51CorpusDispatchError: Error, CustomStringConvertible {
    case unknownType(String)
    case malformedBase64(String)

    var description: String {
        switch self {
        case .unknownType(let iosType):
            return "SEP-0051 corpus: no XDR-JSON dispatch for \(iosType). "
                + "Run make xdr-generate-tests."
        case .malformedBase64(let iosType):
            return "SEP-0051 corpus: the xdr of a \(iosType) entry is not valid base64."
        }
    }
}

enum GeneratedXdrJsonCorpusDispatch {

    /// Reads the base64 XDR with the binary codec and emits the value's XDR-JSON text.
    static func json(forType iosType: String, xdrBase64: String) throws -> String {
        guard let data = Data(base64Encoded: xdrBase64) else {
            throw Sep51CorpusDispatchError.malformedBase64(iosType)
        }
        switch iosType {
        case "AccountEntryExtV1XDR":
            let value = try XDRDecoder.decode(AccountEntryExtV1XDR.self, data: data)
            return try value.toXdrJson()
        case "AccountEntryExtV2XDR":
            let value = try XDRDecoder.decode(AccountEntryExtV2XDR.self, data: data)
            return try value.toXdrJson()
        case "AccountEntryExtXDR":
            let value = try XDRDecoder.decode(AccountEntryExtXDR.self, data: data)
            return try value.toXdrJson()
        case "AccountEntryExtensionV1":
            let value = try XDRDecoder.decode(AccountEntryExtensionV1.self, data: data)
            return try value.toXdrJson()
        case "AccountEntryExtensionV2":
            let value = try XDRDecoder.decode(AccountEntryExtensionV2.self, data: data)
            return try value.toXdrJson()
        case "AccountEntryExtensionV3":
            let value = try XDRDecoder.decode(AccountEntryExtensionV3.self, data: data)
            return try value.toXdrJson()
        case "AccountEntryXDR":
            let value = try XDRDecoder.decode(AccountEntryXDR.self, data: data)
            return try value.toXdrJson()
        case "AccountFlags":
            let value = try XDRDecoder.decode(AccountFlags.self, data: data)
            return try value.toXdrJson()
        case "AccountIDXDR":
            let value = try XDRDecoder.decode(AccountIDXDR.self, data: data)
            return try AccountIDXDRJsonCodec.toXdrJson(value)
        case "AccountMergeResultCode":
            let value = try XDRDecoder.decode(AccountMergeResultCode.self, data: data)
            return try value.toXdrJson()
        case "AccountMergeResultXDR":
            let value = try XDRDecoder.decode(AccountMergeResultXDR.self, data: data)
            return try value.toXdrJson()
        case "AllowTrustOpAssetXDR":
            let value = try XDRDecoder.decode(AllowTrustOpAssetXDR.self, data: data)
            return try value.toXdrJson()
        case "AllowTrustOperationXDR":
            let value = try XDRDecoder.decode(AllowTrustOperationXDR.self, data: data)
            return try value.toXdrJson()
        case "AllowTrustResultCode":
            let value = try XDRDecoder.decode(AllowTrustResultCode.self, data: data)
            return try value.toXdrJson()
        case "AllowTrustResultXDR":
            let value = try XDRDecoder.decode(AllowTrustResultXDR.self, data: data)
            return try value.toXdrJson()
        case "Alpha12XDR":
            let value = try XDRDecoder.decode(Alpha12XDR.self, data: data)
            return try value.toXdrJson()
        case "Alpha4XDR":
            let value = try XDRDecoder.decode(Alpha4XDR.self, data: data)
            return try value.toXdrJson()
        case "AssetCode12XDR":
            let value = try XDRDecoder.decode(AssetCode12XDR.self, data: data)
            return try AssetCode12XDRJsonCodec.toXdrJson(value)
        case "AssetCode4XDR":
            let value = try XDRDecoder.decode(AssetCode4XDR.self, data: data)
            return try AssetCode4XDRJsonCodec.toXdrJson(value)
        case "AssetType":
            let value = try XDRDecoder.decode(AssetType.self, data: data)
            return try value.toXdrJson()
        case "AssetXDR":
            let value = try XDRDecoder.decode(AssetXDR.self, data: data)
            return try value.toXdrJson()
        case "AuthCertXDR":
            let value = try XDRDecoder.decode(AuthCertXDR.self, data: data)
            return try value.toXdrJson()
        case "AuthXDR":
            let value = try XDRDecoder.decode(AuthXDR.self, data: data)
            return try value.toXdrJson()
        case "AuthenticatedMessageXDR":
            let value = try XDRDecoder.decode(AuthenticatedMessageXDR.self, data: data)
            return try value.toXdrJson()
        case "AuthenticatedMessageXDRV0XDR":
            let value = try XDRDecoder.decode(AuthenticatedMessageXDRV0XDR.self, data: data)
            return try value.toXdrJson()
        case "BeginSponsoringFutureReservesOpXDR":
            let value = try XDRDecoder.decode(BeginSponsoringFutureReservesOpXDR.self, data: data)
            return try value.toXdrJson()
        case "BeginSponsoringFutureReservesResultCode":
            let value = try XDRDecoder.decode(BeginSponsoringFutureReservesResultCode.self, data: data)
            return try value.toXdrJson()
        case "BeginSponsoringFutureReservesResultXDR":
            let value = try XDRDecoder.decode(BeginSponsoringFutureReservesResultXDR.self, data: data)
            return try value.toXdrJson()
        case "BinaryFuseFilterTypeXDR":
            let value = try XDRDecoder.decode(BinaryFuseFilterTypeXDR.self, data: data)
            return try value.toXdrJson()
        case "BucketEntryTypeXDR":
            let value = try XDRDecoder.decode(BucketEntryTypeXDR.self, data: data)
            return try value.toXdrJson()
        case "BucketEntryXDR":
            let value = try XDRDecoder.decode(BucketEntryXDR.self, data: data)
            return try value.toXdrJson()
        case "BucketListTypeXDR":
            let value = try XDRDecoder.decode(BucketListTypeXDR.self, data: data)
            return try value.toXdrJson()
        case "BucketMetadataXDR":
            let value = try XDRDecoder.decode(BucketMetadataXDR.self, data: data)
            return try value.toXdrJson()
        case "BucketMetadataXDRExtXDR":
            let value = try XDRDecoder.decode(BucketMetadataXDRExtXDR.self, data: data)
            return try value.toXdrJson()
        case "BumpSequenceOperationXDR":
            let value = try XDRDecoder.decode(BumpSequenceOperationXDR.self, data: data)
            return try value.toXdrJson()
        case "BumpSequenceResultCode":
            let value = try XDRDecoder.decode(BumpSequenceResultCode.self, data: data)
            return try value.toXdrJson()
        case "BumpSequenceResultXDR":
            let value = try XDRDecoder.decode(BumpSequenceResultXDR.self, data: data)
            return try value.toXdrJson()
        case "ChangeTrustAssetXDR":
            let value = try XDRDecoder.decode(ChangeTrustAssetXDR.self, data: data)
            return try value.toXdrJson()
        case "ChangeTrustOperationXDR":
            let value = try XDRDecoder.decode(ChangeTrustOperationXDR.self, data: data)
            return try value.toXdrJson()
        case "ChangeTrustResultCode":
            let value = try XDRDecoder.decode(ChangeTrustResultCode.self, data: data)
            return try value.toXdrJson()
        case "ChangeTrustResultXDR":
            let value = try XDRDecoder.decode(ChangeTrustResultXDR.self, data: data)
            return try value.toXdrJson()
        case "ClaimAtomType":
            let value = try XDRDecoder.decode(ClaimAtomType.self, data: data)
            return try value.toXdrJson()
        case "ClaimAtomXDR":
            let value = try XDRDecoder.decode(ClaimAtomXDR.self, data: data)
            return try value.toXdrJson()
        case "ClaimClaimableBalanceOpXDR":
            let value = try XDRDecoder.decode(ClaimClaimableBalanceOpXDR.self, data: data)
            return try value.toXdrJson()
        case "ClaimClaimableBalanceResultCode":
            let value = try XDRDecoder.decode(ClaimClaimableBalanceResultCode.self, data: data)
            return try value.toXdrJson()
        case "ClaimClaimableBalanceResultXDR":
            let value = try XDRDecoder.decode(ClaimClaimableBalanceResultXDR.self, data: data)
            return try value.toXdrJson()
        case "ClaimLiquidityAtomXDR":
            let value = try XDRDecoder.decode(ClaimLiquidityAtomXDR.self, data: data)
            return try value.toXdrJson()
        case "ClaimOfferAtomV0XDR":
            let value = try XDRDecoder.decode(ClaimOfferAtomV0XDR.self, data: data)
            return try value.toXdrJson()
        case "ClaimOfferAtomXDR":
            let value = try XDRDecoder.decode(ClaimOfferAtomXDR.self, data: data)
            return try value.toXdrJson()
        case "ClaimPredicateType":
            let value = try XDRDecoder.decode(ClaimPredicateType.self, data: data)
            return try value.toXdrJson()
        case "ClaimPredicateXDR":
            let value = try XDRDecoder.decode(ClaimPredicateXDR.self, data: data)
            return try value.toXdrJson()
        case "ClaimableBalanceEntryExtXDR":
            let value = try XDRDecoder.decode(ClaimableBalanceEntryExtXDR.self, data: data)
            return try value.toXdrJson()
        case "ClaimableBalanceEntryExtensionV1":
            let value = try XDRDecoder.decode(ClaimableBalanceEntryExtensionV1.self, data: data)
            return try value.toXdrJson()
        case "ClaimableBalanceEntryExtensionV1ExtXDR":
            let value = try XDRDecoder.decode(ClaimableBalanceEntryExtensionV1ExtXDR.self, data: data)
            return try value.toXdrJson()
        case "ClaimableBalanceEntryXDR":
            let value = try XDRDecoder.decode(ClaimableBalanceEntryXDR.self, data: data)
            return try value.toXdrJson()
        case "ClaimableBalanceFlags":
            let value = try XDRDecoder.decode(ClaimableBalanceFlags.self, data: data)
            return try value.toXdrJson()
        case "ClaimableBalanceIDType":
            let value = try XDRDecoder.decode(ClaimableBalanceIDType.self, data: data)
            return try value.toXdrJson()
        case "ClaimableBalanceIDXDR":
            let value = try XDRDecoder.decode(ClaimableBalanceIDXDR.self, data: data)
            return try value.toXdrJson()
        case "ClaimantType":
            let value = try XDRDecoder.decode(ClaimantType.self, data: data)
            return try value.toXdrJson()
        case "ClaimantV0XDR":
            let value = try XDRDecoder.decode(ClaimantV0XDR.self, data: data)
            return try value.toXdrJson()
        case "ClaimantXDR":
            let value = try XDRDecoder.decode(ClaimantXDR.self, data: data)
            return try value.toXdrJson()
        case "ClawbackClaimableBalanceOpXDR":
            let value = try XDRDecoder.decode(ClawbackClaimableBalanceOpXDR.self, data: data)
            return try value.toXdrJson()
        case "ClawbackClaimableBalanceResultCode":
            let value = try XDRDecoder.decode(ClawbackClaimableBalanceResultCode.self, data: data)
            return try value.toXdrJson()
        case "ClawbackClaimableBalanceResultXDR":
            let value = try XDRDecoder.decode(ClawbackClaimableBalanceResultXDR.self, data: data)
            return try value.toXdrJson()
        case "ClawbackOpXDR":
            let value = try XDRDecoder.decode(ClawbackOpXDR.self, data: data)
            return try value.toXdrJson()
        case "ClawbackResultCode":
            let value = try XDRDecoder.decode(ClawbackResultCode.self, data: data)
            return try value.toXdrJson()
        case "ClawbackResultXDR":
            let value = try XDRDecoder.decode(ClawbackResultXDR.self, data: data)
            return try value.toXdrJson()
        case "ConfigSettingContractBandwidthV0XDR":
            let value = try XDRDecoder.decode(ConfigSettingContractBandwidthV0XDR.self, data: data)
            return try value.toXdrJson()
        case "ConfigSettingContractComputeV0XDR":
            let value = try XDRDecoder.decode(ConfigSettingContractComputeV0XDR.self, data: data)
            return try value.toXdrJson()
        case "ConfigSettingContractEventsV0XDR":
            let value = try XDRDecoder.decode(ConfigSettingContractEventsV0XDR.self, data: data)
            return try value.toXdrJson()
        case "ConfigSettingContractExecutionLanesV0XDR":
            let value = try XDRDecoder.decode(ConfigSettingContractExecutionLanesV0XDR.self, data: data)
            return try value.toXdrJson()
        case "ConfigSettingContractHistoricalDataV0XDR":
            let value = try XDRDecoder.decode(ConfigSettingContractHistoricalDataV0XDR.self, data: data)
            return try value.toXdrJson()
        case "ConfigSettingContractLedgerCostExtV0":
            let value = try XDRDecoder.decode(ConfigSettingContractLedgerCostExtV0.self, data: data)
            return try value.toXdrJson()
        case "ConfigSettingContractLedgerCostV0XDR":
            let value = try XDRDecoder.decode(ConfigSettingContractLedgerCostV0XDR.self, data: data)
            return try value.toXdrJson()
        case "ConfigSettingContractParallelComputeV0":
            let value = try XDRDecoder.decode(ConfigSettingContractParallelComputeV0.self, data: data)
            return try value.toXdrJson()
        case "ConfigSettingEntryXDR":
            let value = try XDRDecoder.decode(ConfigSettingEntryXDR.self, data: data)
            return try value.toXdrJson()
        case "ConfigSettingID":
            let value = try XDRDecoder.decode(ConfigSettingID.self, data: data)
            return try value.toXdrJson()
        case "ConfigSettingSCPTiming":
            let value = try XDRDecoder.decode(ConfigSettingSCPTiming.self, data: data)
            return try value.toXdrJson()
        case "ConfigUpgradeSetKeyXDR":
            let value = try XDRDecoder.decode(ConfigUpgradeSetKeyXDR.self, data: data)
            return try value.toXdrJson()
        case "ConfigUpgradeSetXDR":
            let value = try XDRDecoder.decode(ConfigUpgradeSetXDR.self, data: data)
            return try value.toXdrJson()
        case "ConstantProductXDR":
            let value = try XDRDecoder.decode(ConstantProductXDR.self, data: data)
            return try value.toXdrJson()
        case "ContractCodeCostInputsXDR":
            let value = try XDRDecoder.decode(ContractCodeCostInputsXDR.self, data: data)
            return try value.toXdrJson()
        case "ContractCodeEntryExt":
            let value = try XDRDecoder.decode(ContractCodeEntryExt.self, data: data)
            return try value.toXdrJson()
        case "ContractCodeEntryExtV1":
            let value = try XDRDecoder.decode(ContractCodeEntryExtV1.self, data: data)
            return try value.toXdrJson()
        case "ContractCodeEntryXDR":
            let value = try XDRDecoder.decode(ContractCodeEntryXDR.self, data: data)
            return try value.toXdrJson()
        case "ContractCostParamEntryXDR":
            let value = try XDRDecoder.decode(ContractCostParamEntryXDR.self, data: data)
            return try value.toXdrJson()
        case "ContractCostParamsXDR":
            let value = try XDRDecoder.decode(ContractCostParamsXDR.self, data: data)
            return try value.toXdrJson()
        case "ContractCostType":
            let value = try XDRDecoder.decode(ContractCostType.self, data: data)
            return try value.toXdrJson()
        case "ContractDataDurability":
            let value = try XDRDecoder.decode(ContractDataDurability.self, data: data)
            return try value.toXdrJson()
        case "ContractDataEntryXDR":
            let value = try XDRDecoder.decode(ContractDataEntryXDR.self, data: data)
            return try value.toXdrJson()
        case "ContractEventBodyV0XDR":
            let value = try XDRDecoder.decode(ContractEventBodyV0XDR.self, data: data)
            return try value.toXdrJson()
        case "ContractEventBodyXDR":
            let value = try XDRDecoder.decode(ContractEventBodyXDR.self, data: data)
            return try value.toXdrJson()
        case "ContractEventType":
            let value = try XDRDecoder.decode(ContractEventType.self, data: data)
            return try value.toXdrJson()
        case "ContractEventXDR":
            let value = try XDRDecoder.decode(ContractEventXDR.self, data: data)
            return try value.toXdrJson()
        case "ContractExecutableExternalRefXDR":
            let value = try XDRDecoder.decode(ContractExecutableExternalRefXDR.self, data: data)
            return try value.toXdrJson()
        case "ContractExecutableType":
            let value = try XDRDecoder.decode(ContractExecutableType.self, data: data)
            return try value.toXdrJson()
        case "ContractExecutableXDR":
            let value = try XDRDecoder.decode(ContractExecutableXDR.self, data: data)
            return try value.toXdrJson()
        case "ContractIDPreimageFromAddressXDR":
            let value = try XDRDecoder.decode(ContractIDPreimageFromAddressXDR.self, data: data)
            return try value.toXdrJson()
        case "ContractIDPreimageType":
            let value = try XDRDecoder.decode(ContractIDPreimageType.self, data: data)
            return try value.toXdrJson()
        case "ContractIDPreimageXDR":
            let value = try XDRDecoder.decode(ContractIDPreimageXDR.self, data: data)
            return try value.toXdrJson()
        case "ContractIDXDR":
            let value = try XDRDecoder.decode(ContractIDXDR.self, data: data)
            return try ContractIDXDRJsonCodec.toXdrJson(value)
        case "CreateAccountOperationXDR":
            let value = try XDRDecoder.decode(CreateAccountOperationXDR.self, data: data)
            return try value.toXdrJson()
        case "CreateAccountResultCode":
            let value = try XDRDecoder.decode(CreateAccountResultCode.self, data: data)
            return try value.toXdrJson()
        case "CreateAccountResultXDR":
            let value = try XDRDecoder.decode(CreateAccountResultXDR.self, data: data)
            return try value.toXdrJson()
        case "CreateClaimableBalanceOpXDR":
            let value = try XDRDecoder.decode(CreateClaimableBalanceOpXDR.self, data: data)
            return try value.toXdrJson()
        case "CreateClaimableBalanceResultCode":
            let value = try XDRDecoder.decode(CreateClaimableBalanceResultCode.self, data: data)
            return try value.toXdrJson()
        case "CreateClaimableBalanceResultXDR":
            let value = try XDRDecoder.decode(CreateClaimableBalanceResultXDR.self, data: data)
            return try value.toXdrJson()
        case "CreateContractArgsXDR":
            let value = try XDRDecoder.decode(CreateContractArgsXDR.self, data: data)
            return try value.toXdrJson()
        case "CreateContractV2ArgsXDR":
            let value = try XDRDecoder.decode(CreateContractV2ArgsXDR.self, data: data)
            return try value.toXdrJson()
        case "CreatePassiveOfferOperationXDR":
            let value = try XDRDecoder.decode(CreatePassiveOfferOperationXDR.self, data: data)
            return try value.toXdrJson()
        case "CryptoKeyType":
            let value = try XDRDecoder.decode(CryptoKeyType.self, data: data)
            return try value.toXdrJson()
        case "Curve25519PublicXDR":
            let value = try XDRDecoder.decode(Curve25519PublicXDR.self, data: data)
            return try value.toXdrJson()
        case "Curve25519SecretXDR":
            let value = try XDRDecoder.decode(Curve25519SecretXDR.self, data: data)
            return try value.toXdrJson()
        case "DataEntryXDR":
            let value = try XDRDecoder.decode(DataEntryXDR.self, data: data)
            return try value.toXdrJson()
        case "DataEntryXDRExtXDR":
            let value = try XDRDecoder.decode(DataEntryXDRExtXDR.self, data: data)
            return try value.toXdrJson()
        case "DataValueXDR":
            let value = try XDRDecoder.decode(DataValueXDR.self, data: data)
            return try DataValueXDRJsonCodec.toXdrJson(value)
        case "DecoratedSignatureXDR":
            let value = try XDRDecoder.decode(DecoratedSignatureXDR.self, data: data)
            return try value.toXdrJson()
        case "DependentTxClusterXDR":
            let value = try XDRDecoder.decode(DependentTxClusterXDR.self, data: data)
            return try value.toXdrJson()
        case "DiagnosticEventXDR":
            let value = try XDRDecoder.decode(DiagnosticEventXDR.self, data: data)
            return try value.toXdrJson()
        case "DontHaveXDR":
            let value = try XDRDecoder.decode(DontHaveXDR.self, data: data)
            return try value.toXdrJson()
        case "DurationXDR":
            let value = try XDRDecoder.decode(DurationXDR.self, data: data)
            return try DurationXDRJsonCodec.toXdrJson(value)
        case "Ed25519SignedPayload":
            let value = try XDRDecoder.decode(Ed25519SignedPayload.self, data: data)
            return try value.toXdrJson()
        case "EncodedLedgerKeyXDR":
            let value = try XDRDecoder.decode(EncodedLedgerKeyXDR.self, data: data)
            return try EncodedLedgerKeyXDRJsonCodec.toXdrJson(value)
        case "EncryptedBodyXDR":
            let value = try XDRDecoder.decode(EncryptedBodyXDR.self, data: data)
            return try EncryptedBodyXDRJsonCodec.toXdrJson(value)
        case "EndSponsoringFutureReservesResultCode":
            let value = try XDRDecoder.decode(EndSponsoringFutureReservesResultCode.self, data: data)
            return try value.toXdrJson()
        case "EndSponsoringFutureReservesResultXDR":
            let value = try XDRDecoder.decode(EndSponsoringFutureReservesResultXDR.self, data: data)
            return try value.toXdrJson()
        case "EnvelopeType":
            let value = try XDRDecoder.decode(EnvelopeType.self, data: data)
            return try value.toXdrJson()
        case "ErrorCodeXDR":
            let value = try XDRDecoder.decode(ErrorCodeXDR.self, data: data)
            return try value.toXdrJson()
        case "ErrorXDR":
            let value = try XDRDecoder.decode(ErrorXDR.self, data: data)
            return try value.toXdrJson()
        case "EvictionIteratorXDR":
            let value = try XDRDecoder.decode(EvictionIteratorXDR.self, data: data)
            return try value.toXdrJson()
        case "ExtendFootprintTTLOpXDR":
            let value = try XDRDecoder.decode(ExtendFootprintTTLOpXDR.self, data: data)
            return try value.toXdrJson()
        case "ExtendFootprintTTLResultCode":
            let value = try XDRDecoder.decode(ExtendFootprintTTLResultCode.self, data: data)
            return try value.toXdrJson()
        case "ExtendFootprintTTLResultXDR":
            let value = try XDRDecoder.decode(ExtendFootprintTTLResultXDR.self, data: data)
            return try value.toXdrJson()
        case "ExtensionPoint":
            let value = try XDRDecoder.decode(ExtensionPoint.self, data: data)
            return try value.toXdrJson()
        case "FeeBumpTransactionEnvelopeXDR":
            let value = try XDRDecoder.decode(FeeBumpTransactionEnvelopeXDR.self, data: data)
            return try value.toXdrJson()
        case "FeeBumpTransactionXDR":
            let value = try XDRDecoder.decode(FeeBumpTransactionXDR.self, data: data)
            return try value.toXdrJson()
        case "FeeBumpTransactionXDRExtXDR":
            let value = try XDRDecoder.decode(FeeBumpTransactionXDRExtXDR.self, data: data)
            return try value.toXdrJson()
        case "FeeBumpTransactionXDRInnerTxXDR":
            let value = try XDRDecoder.decode(FeeBumpTransactionXDRInnerTxXDR.self, data: data)
            return try value.toXdrJson()
        case "FloodAdvertXDR":
            let value = try XDRDecoder.decode(FloodAdvertXDR.self, data: data)
            return try value.toXdrJson()
        case "FloodDemandXDR":
            let value = try XDRDecoder.decode(FloodDemandXDR.self, data: data)
            return try value.toXdrJson()
        case "FreezeBypassTxsDeltaXDR":
            let value = try XDRDecoder.decode(FreezeBypassTxsDeltaXDR.self, data: data)
            return try value.toXdrJson()
        case "FreezeBypassTxsXDR":
            let value = try XDRDecoder.decode(FreezeBypassTxsXDR.self, data: data)
            return try value.toXdrJson()
        case "FrozenLedgerKeysDeltaXDR":
            let value = try XDRDecoder.decode(FrozenLedgerKeysDeltaXDR.self, data: data)
            return try value.toXdrJson()
        case "FrozenLedgerKeysXDR":
            let value = try XDRDecoder.decode(FrozenLedgerKeysXDR.self, data: data)
            return try value.toXdrJson()
        case "GeneralizedTransactionSetXDR":
            let value = try XDRDecoder.decode(GeneralizedTransactionSetXDR.self, data: data)
            return try value.toXdrJson()
        case "HashIDPreimageContractIDXDR":
            let value = try XDRDecoder.decode(HashIDPreimageContractIDXDR.self, data: data)
            return try value.toXdrJson()
        case "HashIDPreimageSorobanAuthorizationWithAddressXDR":
            let value = try XDRDecoder.decode(HashIDPreimageSorobanAuthorizationWithAddressXDR.self, data: data)
            return try value.toXdrJson()
        case "HashIDPreimageSorobanAuthorizationXDR":
            let value = try XDRDecoder.decode(HashIDPreimageSorobanAuthorizationXDR.self, data: data)
            return try value.toXdrJson()
        case "HashIDPreimageXDR":
            let value = try XDRDecoder.decode(HashIDPreimageXDR.self, data: data)
            return try value.toXdrJson()
        case "HashXDR":
            let value = try XDRDecoder.decode(HashXDR.self, data: data)
            return try HashXDRJsonCodec.toXdrJson(value)
        case "HelloXDR":
            let value = try XDRDecoder.decode(HelloXDR.self, data: data)
            return try value.toXdrJson()
        case "HmacSha256KeyXDR":
            let value = try XDRDecoder.decode(HmacSha256KeyXDR.self, data: data)
            return try value.toXdrJson()
        case "HmacSha256MacXDR":
            let value = try XDRDecoder.decode(HmacSha256MacXDR.self, data: data)
            return try value.toXdrJson()
        case "HostFunctionType":
            let value = try XDRDecoder.decode(HostFunctionType.self, data: data)
            return try value.toXdrJson()
        case "HostFunctionXDR":
            let value = try XDRDecoder.decode(HostFunctionXDR.self, data: data)
            return try value.toXdrJson()
        case "HotArchiveBucketEntryTypeXDR":
            let value = try XDRDecoder.decode(HotArchiveBucketEntryTypeXDR.self, data: data)
            return try value.toXdrJson()
        case "HotArchiveBucketEntryXDR":
            let value = try XDRDecoder.decode(HotArchiveBucketEntryXDR.self, data: data)
            return try value.toXdrJson()
        case "IPAddrTypeXDR":
            let value = try XDRDecoder.decode(IPAddrTypeXDR.self, data: data)
            return try value.toXdrJson()
        case "InflationPayoutXDR":
            let value = try XDRDecoder.decode(InflationPayoutXDR.self, data: data)
            return try value.toXdrJson()
        case "InflationResultCode":
            let value = try XDRDecoder.decode(InflationResultCode.self, data: data)
            return try value.toXdrJson()
        case "InflationResultXDR":
            let value = try XDRDecoder.decode(InflationResultXDR.self, data: data)
            return try value.toXdrJson()
        case "InnerTransactionResultBodyXDR":
            let value = try XDRDecoder.decode(InnerTransactionResultBodyXDR.self, data: data)
            return try value.toXdrJson()
        case "InnerTransactionResultPair":
            let value = try XDRDecoder.decode(InnerTransactionResultPair.self, data: data)
            return try value.toXdrJson()
        case "InnerTransactionResultXDR":
            let value = try XDRDecoder.decode(InnerTransactionResultXDR.self, data: data)
            return try value.toXdrJson()
        case "InnerTransactionResultXDRExtXDR":
            let value = try XDRDecoder.decode(InnerTransactionResultXDRExtXDR.self, data: data)
            return try value.toXdrJson()
        case "Int128PartsXDR":
            let value = try XDRDecoder.decode(Int128PartsXDR.self, data: data)
            return try value.toXdrJson()
        case "Int256PartsXDR":
            let value = try XDRDecoder.decode(Int256PartsXDR.self, data: data)
            return try value.toXdrJson()
        case "Int32XDR":
            let value = try XDRDecoder.decode(Int32XDR.self, data: data)
            return try Int32XDRJsonCodec.toXdrJson(value)
        case "Int64XDR":
            let value = try XDRDecoder.decode(Int64XDR.self, data: data)
            return try Int64XDRJsonCodec.toXdrJson(value)
        case "InvokeContractArgsXDR":
            let value = try XDRDecoder.decode(InvokeContractArgsXDR.self, data: data)
            return try value.toXdrJson()
        case "InvokeHostFunctionOpXDR":
            let value = try XDRDecoder.decode(InvokeHostFunctionOpXDR.self, data: data)
            return try value.toXdrJson()
        case "InvokeHostFunctionResultCode":
            let value = try XDRDecoder.decode(InvokeHostFunctionResultCode.self, data: data)
            return try value.toXdrJson()
        case "InvokeHostFunctionResultXDR":
            let value = try XDRDecoder.decode(InvokeHostFunctionResultXDR.self, data: data)
            return try value.toXdrJson()
        case "InvokeHostFunctionSuccessPreImageXDR":
            let value = try XDRDecoder.decode(InvokeHostFunctionSuccessPreImageXDR.self, data: data)
            return try value.toXdrJson()
        case "LedgerBoundsXDR":
            let value = try XDRDecoder.decode(LedgerBoundsXDR.self, data: data)
            return try value.toXdrJson()
        case "LedgerCloseMetaBatchXDR":
            let value = try XDRDecoder.decode(LedgerCloseMetaBatchXDR.self, data: data)
            return try value.toXdrJson()
        case "LedgerCloseMetaExtV1XDR":
            let value = try XDRDecoder.decode(LedgerCloseMetaExtV1XDR.self, data: data)
            return try value.toXdrJson()
        case "LedgerCloseMetaExtXDR":
            let value = try XDRDecoder.decode(LedgerCloseMetaExtXDR.self, data: data)
            return try value.toXdrJson()
        case "LedgerCloseMetaV0XDR":
            let value = try XDRDecoder.decode(LedgerCloseMetaV0XDR.self, data: data)
            return try value.toXdrJson()
        case "LedgerCloseMetaV1XDR":
            let value = try XDRDecoder.decode(LedgerCloseMetaV1XDR.self, data: data)
            return try value.toXdrJson()
        case "LedgerCloseMetaV2XDR":
            let value = try XDRDecoder.decode(LedgerCloseMetaV2XDR.self, data: data)
            return try value.toXdrJson()
        case "LedgerCloseMetaXDR":
            let value = try XDRDecoder.decode(LedgerCloseMetaXDR.self, data: data)
            return try value.toXdrJson()
        case "LedgerCloseValueSignatureXDR":
            let value = try XDRDecoder.decode(LedgerCloseValueSignatureXDR.self, data: data)
            return try value.toXdrJson()
        case "LedgerEntryChangeType":
            let value = try XDRDecoder.decode(LedgerEntryChangeType.self, data: data)
            return try value.toXdrJson()
        case "LedgerEntryChangeXDR":
            let value = try XDRDecoder.decode(LedgerEntryChangeXDR.self, data: data)
            return try value.toXdrJson()
        case "LedgerEntryChangesXDR":
            let value = try XDRDecoder.decode(LedgerEntryChangesXDR.self, data: data)
            return try value.toXdrJson()
        case "LedgerEntryDataXDR":
            let value = try XDRDecoder.decode(LedgerEntryDataXDR.self, data: data)
            return try value.toXdrJson()
        case "LedgerEntryExtXDR":
            let value = try XDRDecoder.decode(LedgerEntryExtXDR.self, data: data)
            return try value.toXdrJson()
        case "LedgerEntryExtensionV1":
            let value = try XDRDecoder.decode(LedgerEntryExtensionV1.self, data: data)
            return try value.toXdrJson()
        case "LedgerEntryExtensionV1ExtXDR":
            let value = try XDRDecoder.decode(LedgerEntryExtensionV1ExtXDR.self, data: data)
            return try value.toXdrJson()
        case "LedgerEntryType":
            let value = try XDRDecoder.decode(LedgerEntryType.self, data: data)
            return try value.toXdrJson()
        case "LedgerEntryXDR":
            let value = try XDRDecoder.decode(LedgerEntryXDR.self, data: data)
            return try value.toXdrJson()
        case "LedgerFootprintXDR":
            let value = try XDRDecoder.decode(LedgerFootprintXDR.self, data: data)
            return try value.toXdrJson()
        case "LedgerHeaderExtensionV1XDR":
            let value = try XDRDecoder.decode(LedgerHeaderExtensionV1XDR.self, data: data)
            return try value.toXdrJson()
        case "LedgerHeaderExtensionV1XDRExtXDR":
            let value = try XDRDecoder.decode(LedgerHeaderExtensionV1XDRExtXDR.self, data: data)
            return try value.toXdrJson()
        case "LedgerHeaderFlagsXDR":
            let value = try XDRDecoder.decode(LedgerHeaderFlagsXDR.self, data: data)
            return try value.toXdrJson()
        case "LedgerHeaderHistoryEntryXDR":
            let value = try XDRDecoder.decode(LedgerHeaderHistoryEntryXDR.self, data: data)
            return try value.toXdrJson()
        case "LedgerHeaderHistoryEntryXDRExtXDR":
            let value = try XDRDecoder.decode(LedgerHeaderHistoryEntryXDRExtXDR.self, data: data)
            return try value.toXdrJson()
        case "LedgerHeaderXDR":
            let value = try XDRDecoder.decode(LedgerHeaderXDR.self, data: data)
            return try value.toXdrJson()
        case "LedgerHeaderXDRExtXDR":
            let value = try XDRDecoder.decode(LedgerHeaderXDRExtXDR.self, data: data)
            return try value.toXdrJson()
        case "LedgerKeyAccountXDR":
            let value = try XDRDecoder.decode(LedgerKeyAccountXDR.self, data: data)
            return try value.toXdrJson()
        case "LedgerKeyClaimableBalanceXDR":
            let value = try XDRDecoder.decode(LedgerKeyClaimableBalanceXDR.self, data: data)
            return try value.toXdrJson()
        case "LedgerKeyConfigSettingXDR":
            let value = try XDRDecoder.decode(LedgerKeyConfigSettingXDR.self, data: data)
            return try value.toXdrJson()
        case "LedgerKeyContractCodeXDR":
            let value = try XDRDecoder.decode(LedgerKeyContractCodeXDR.self, data: data)
            return try value.toXdrJson()
        case "LedgerKeyContractDataXDR":
            let value = try XDRDecoder.decode(LedgerKeyContractDataXDR.self, data: data)
            return try value.toXdrJson()
        case "LedgerKeyDataXDR":
            let value = try XDRDecoder.decode(LedgerKeyDataXDR.self, data: data)
            return try value.toXdrJson()
        case "LedgerKeyLiquidityPoolXDR":
            let value = try XDRDecoder.decode(LedgerKeyLiquidityPoolXDR.self, data: data)
            return try value.toXdrJson()
        case "LedgerKeyOfferXDR":
            let value = try XDRDecoder.decode(LedgerKeyOfferXDR.self, data: data)
            return try value.toXdrJson()
        case "LedgerKeyTTLXDR":
            let value = try XDRDecoder.decode(LedgerKeyTTLXDR.self, data: data)
            return try value.toXdrJson()
        case "LedgerKeyTrustLineXDR":
            let value = try XDRDecoder.decode(LedgerKeyTrustLineXDR.self, data: data)
            return try value.toXdrJson()
        case "LedgerKeyXDR":
            let value = try XDRDecoder.decode(LedgerKeyXDR.self, data: data)
            return try value.toXdrJson()
        case "LedgerSCPMessagesXDR":
            let value = try XDRDecoder.decode(LedgerSCPMessagesXDR.self, data: data)
            return try value.toXdrJson()
        case "LedgerUpgradeTypeXDR":
            let value = try XDRDecoder.decode(LedgerUpgradeTypeXDR.self, data: data)
            return try value.toXdrJson()
        case "LedgerUpgradeXDR":
            let value = try XDRDecoder.decode(LedgerUpgradeXDR.self, data: data)
            return try value.toXdrJson()
        case "LiabilitiesXDR":
            let value = try XDRDecoder.decode(LiabilitiesXDR.self, data: data)
            return try value.toXdrJson()
        case "LiquidityPoolBodyXDR":
            let value = try XDRDecoder.decode(LiquidityPoolBodyXDR.self, data: data)
            return try value.toXdrJson()
        case "LiquidityPoolConstantProductParametersXDR":
            let value = try XDRDecoder.decode(LiquidityPoolConstantProductParametersXDR.self, data: data)
            return try value.toXdrJson()
        case "LiquidityPoolDepositOpXDR":
            let value = try XDRDecoder.decode(LiquidityPoolDepositOpXDR.self, data: data)
            return try value.toXdrJson()
        case "LiquidityPoolDepositResulCode":
            let value = try XDRDecoder.decode(LiquidityPoolDepositResulCode.self, data: data)
            return try value.toXdrJson()
        case "LiquidityPoolDepositResultXDR":
            let value = try XDRDecoder.decode(LiquidityPoolDepositResultXDR.self, data: data)
            return try value.toXdrJson()
        case "LiquidityPoolEntryXDR":
            let value = try XDRDecoder.decode(LiquidityPoolEntryXDR.self, data: data)
            return try value.toXdrJson()
        case "LiquidityPoolParametersXDR":
            let value = try XDRDecoder.decode(LiquidityPoolParametersXDR.self, data: data)
            return try value.toXdrJson()
        case "LiquidityPoolType":
            let value = try XDRDecoder.decode(LiquidityPoolType.self, data: data)
            return try value.toXdrJson()
        case "LiquidityPoolWithdrawOpXDR":
            let value = try XDRDecoder.decode(LiquidityPoolWithdrawOpXDR.self, data: data)
            return try value.toXdrJson()
        case "LiquidityPoolWithdrawResulCode":
            let value = try XDRDecoder.decode(LiquidityPoolWithdrawResulCode.self, data: data)
            return try value.toXdrJson()
        case "LiquidityPoolWithdrawResultXDR":
            let value = try XDRDecoder.decode(LiquidityPoolWithdrawResultXDR.self, data: data)
            return try value.toXdrJson()
        case "ManageDataOperationXDR":
            let value = try XDRDecoder.decode(ManageDataOperationXDR.self, data: data)
            return try value.toXdrJson()
        case "ManageDataResultCode":
            let value = try XDRDecoder.decode(ManageDataResultCode.self, data: data)
            return try value.toXdrJson()
        case "ManageDataResultXDR":
            let value = try XDRDecoder.decode(ManageDataResultXDR.self, data: data)
            return try value.toXdrJson()
        case "ManageOfferEffect":
            let value = try XDRDecoder.decode(ManageOfferEffect.self, data: data)
            return try value.toXdrJson()
        case "ManageOfferResultCode":
            let value = try XDRDecoder.decode(ManageOfferResultCode.self, data: data)
            return try value.toXdrJson()
        case "ManageOfferResultXDR":
            let value = try XDRDecoder.decode(ManageOfferResultXDR.self, data: data)
            return try value.toXdrJson()
        case "ManageOfferSuccessResultOfferXDR":
            let value = try XDRDecoder.decode(ManageOfferSuccessResultOfferXDR.self, data: data)
            return try value.toXdrJson()
        case "ManageOfferSuccessResultXDR":
            let value = try XDRDecoder.decode(ManageOfferSuccessResultXDR.self, data: data)
            return try value.toXdrJson()
        case "MemoType":
            let value = try XDRDecoder.decode(MemoType.self, data: data)
            return try value.toXdrJson()
        case "MemoXDR":
            let value = try XDRDecoder.decode(MemoXDR.self, data: data)
            return try value.toXdrJson()
        case "MessageTypeXDR":
            let value = try XDRDecoder.decode(MessageTypeXDR.self, data: data)
            return try value.toXdrJson()
        case "MuxedAccountMed25519XDR":
            let value = try XDRDecoder.decode(MuxedAccountMed25519XDR.self, data: data)
            return try value.toXdrJson()
        case "MuxedAccountXDR":
            let value = try XDRDecoder.decode(MuxedAccountXDR.self, data: data)
            return try value.toXdrJson()
        case "MuxedAccountXDRMed25519XDR":
            let value = try XDRDecoder.decode(MuxedAccountXDRMed25519XDR.self, data: data)
            return try value.toXdrJson()
        case "NodeIDXDR":
            let value = try XDRDecoder.decode(NodeIDXDR.self, data: data)
            return try NodeIDXDRJsonCodec.toXdrJson(value)
        case "OfferEntryFlagsXDR":
            let value = try XDRDecoder.decode(OfferEntryFlagsXDR.self, data: data)
            return try value.toXdrJson()
        case "OfferEntryXDR":
            let value = try XDRDecoder.decode(OfferEntryXDR.self, data: data)
            return try value.toXdrJson()
        case "OfferEntryXDRExtXDR":
            let value = try XDRDecoder.decode(OfferEntryXDRExtXDR.self, data: data)
            return try value.toXdrJson()
        case "OperationBodyXDR":
            let value = try XDRDecoder.decode(OperationBodyXDR.self, data: data)
            return try value.toXdrJson()
        case "OperationID":
            let value = try XDRDecoder.decode(OperationID.self, data: data)
            return try value.toXdrJson()
        case "OperationMetaV2XDR":
            let value = try XDRDecoder.decode(OperationMetaV2XDR.self, data: data)
            return try value.toXdrJson()
        case "OperationMetaXDR":
            let value = try XDRDecoder.decode(OperationMetaXDR.self, data: data)
            return try value.toXdrJson()
        case "OperationResultCode":
            let value = try XDRDecoder.decode(OperationResultCode.self, data: data)
            return try value.toXdrJson()
        case "OperationResultXDR":
            let value = try XDRDecoder.decode(OperationResultXDR.self, data: data)
            return try value.toXdrJson()
        case "OperationResultXDRTrXDR":
            let value = try XDRDecoder.decode(OperationResultXDRTrXDR.self, data: data)
            return try value.toXdrJson()
        case "OperationType":
            let value = try XDRDecoder.decode(OperationType.self, data: data)
            return try value.toXdrJson()
        case "OperationXDR":
            let value = try XDRDecoder.decode(OperationXDR.self, data: data)
            return try value.toXdrJson()
        case "ParallelTxExecutionStageXDR":
            let value = try XDRDecoder.decode(ParallelTxExecutionStageXDR.self, data: data)
            return try value.toXdrJson()
        case "ParallelTxsComponentXDR":
            let value = try XDRDecoder.decode(ParallelTxsComponentXDR.self, data: data)
            return try value.toXdrJson()
        case "PathPaymentResultXDRSuccessXDR":
            let value = try XDRDecoder.decode(PathPaymentResultXDRSuccessXDR.self, data: data)
            return try value.toXdrJson()
        case "PaymentOperationXDR":
            let value = try XDRDecoder.decode(PaymentOperationXDR.self, data: data)
            return try value.toXdrJson()
        case "PaymentResultCode":
            let value = try XDRDecoder.decode(PaymentResultCode.self, data: data)
            return try value.toXdrJson()
        case "PaymentResultXDR":
            let value = try XDRDecoder.decode(PaymentResultXDR.self, data: data)
            return try value.toXdrJson()
        case "PeerAddressXDR":
            let value = try XDRDecoder.decode(PeerAddressXDR.self, data: data)
            return try value.toXdrJson()
        case "PeerAddressXDRIpXDR":
            let value = try XDRDecoder.decode(PeerAddressXDRIpXDR.self, data: data)
            return try value.toXdrJson()
        case "PeerStatsXDR":
            let value = try XDRDecoder.decode(PeerStatsXDR.self, data: data)
            return try value.toXdrJson()
        case "PersistedSCPStateV0XDR":
            let value = try XDRDecoder.decode(PersistedSCPStateV0XDR.self, data: data)
            return try value.toXdrJson()
        case "PersistedSCPStateV1XDR":
            let value = try XDRDecoder.decode(PersistedSCPStateV1XDR.self, data: data)
            return try value.toXdrJson()
        case "PersistedSCPStateXDR":
            let value = try XDRDecoder.decode(PersistedSCPStateXDR.self, data: data)
            return try value.toXdrJson()
        case "PoolIDXDR":
            let value = try XDRDecoder.decode(PoolIDXDR.self, data: data)
            return try PoolIDXDRJsonCodec.toXdrJson(value)
        case "PreconditionType":
            let value = try XDRDecoder.decode(PreconditionType.self, data: data)
            return try value.toXdrJson()
        case "PreconditionsV2XDR":
            let value = try XDRDecoder.decode(PreconditionsV2XDR.self, data: data)
            return try value.toXdrJson()
        case "PreconditionsXDR":
            let value = try XDRDecoder.decode(PreconditionsXDR.self, data: data)
            return try value.toXdrJson()
        case "PriceXDR":
            let value = try XDRDecoder.decode(PriceXDR.self, data: data)
            return try value.toXdrJson()
        case "PublicKey":
            let value = try XDRDecoder.decode(PublicKey.self, data: data)
            return try value.toXdrJson()
        case "PublicKeyTypeXDR":
            let value = try XDRDecoder.decode(PublicKeyTypeXDR.self, data: data)
            return try value.toXdrJson()
        case "RestoreFootprintOpXDR":
            let value = try XDRDecoder.decode(RestoreFootprintOpXDR.self, data: data)
            return try value.toXdrJson()
        case "RestoreFootprintResultCode":
            let value = try XDRDecoder.decode(RestoreFootprintResultCode.self, data: data)
            return try value.toXdrJson()
        case "RestoreFootprintResultXDR":
            let value = try XDRDecoder.decode(RestoreFootprintResultXDR.self, data: data)
            return try value.toXdrJson()
        case "RevokeID":
            let value = try XDRDecoder.decode(RevokeID.self, data: data)
            return try value.toXdrJson()
        case "RevokeSponsorshipOpXDR":
            let value = try XDRDecoder.decode(RevokeSponsorshipOpXDR.self, data: data)
            return try value.toXdrJson()
        case "RevokeSponsorshipResultCode":
            let value = try XDRDecoder.decode(RevokeSponsorshipResultCode.self, data: data)
            return try value.toXdrJson()
        case "RevokeSponsorshipResultXDR":
            let value = try XDRDecoder.decode(RevokeSponsorshipResultXDR.self, data: data)
            return try value.toXdrJson()
        case "RevokeSponsorshipSignerXDR":
            let value = try XDRDecoder.decode(RevokeSponsorshipSignerXDR.self, data: data)
            return try value.toXdrJson()
        case "RevokeSponsorshipType":
            let value = try XDRDecoder.decode(RevokeSponsorshipType.self, data: data)
            return try value.toXdrJson()
        case "SCAddressType":
            let value = try XDRDecoder.decode(SCAddressType.self, data: data)
            return try value.toXdrJson()
        case "SCAddressXDR":
            let value = try XDRDecoder.decode(SCAddressXDR.self, data: data)
            return try value.toXdrJson()
        case "SCBytesXDR":
            let value = try XDRDecoder.decode(SCBytesXDR.self, data: data)
            return try SCBytesXDRJsonCodec.toXdrJson(value)
        case "SCContractInstanceXDR":
            let value = try XDRDecoder.decode(SCContractInstanceXDR.self, data: data)
            return try value.toXdrJson()
        case "SCEnvMetaEntryXDR":
            let value = try XDRDecoder.decode(SCEnvMetaEntryXDR.self, data: data)
            return try value.toXdrJson()
        case "SCEnvMetaEntryXDRInterfaceVersionXDR":
            let value = try XDRDecoder.decode(SCEnvMetaEntryXDRInterfaceVersionXDR.self, data: data)
            return try value.toXdrJson()
        case "SCEnvMetaKind":
            let value = try XDRDecoder.decode(SCEnvMetaKind.self, data: data)
            return try value.toXdrJson()
        case "SCErrorCode":
            let value = try XDRDecoder.decode(SCErrorCode.self, data: data)
            return try value.toXdrJson()
        case "SCErrorType":
            let value = try XDRDecoder.decode(SCErrorType.self, data: data)
            return try value.toXdrJson()
        case "SCErrorXDR":
            let value = try XDRDecoder.decode(SCErrorXDR.self, data: data)
            return try value.toXdrJson()
        case "SCMapEntryXDR":
            let value = try XDRDecoder.decode(SCMapEntryXDR.self, data: data)
            return try value.toXdrJson()
        case "SCMapXDR":
            let value = try XDRDecoder.decode(SCMapXDR.self, data: data)
            return try value.toXdrJson()
        case "SCMetaEntryXDR":
            let value = try XDRDecoder.decode(SCMetaEntryXDR.self, data: data)
            return try value.toXdrJson()
        case "SCMetaKind":
            let value = try XDRDecoder.decode(SCMetaKind.self, data: data)
            return try value.toXdrJson()
        case "SCMetaV0XDR":
            let value = try XDRDecoder.decode(SCMetaV0XDR.self, data: data)
            return try value.toXdrJson()
        case "SCNonceKeyXDR":
            let value = try XDRDecoder.decode(SCNonceKeyXDR.self, data: data)
            return try value.toXdrJson()
        case "SCPBallotXDR":
            let value = try XDRDecoder.decode(SCPBallotXDR.self, data: data)
            return try value.toXdrJson()
        case "SCPEnvelopeXDR":
            let value = try XDRDecoder.decode(SCPEnvelopeXDR.self, data: data)
            return try value.toXdrJson()
        case "SCPHistoryEntryV0XDR":
            let value = try XDRDecoder.decode(SCPHistoryEntryV0XDR.self, data: data)
            return try value.toXdrJson()
        case "SCPHistoryEntryXDR":
            let value = try XDRDecoder.decode(SCPHistoryEntryXDR.self, data: data)
            return try value.toXdrJson()
        case "SCPNominationXDR":
            let value = try XDRDecoder.decode(SCPNominationXDR.self, data: data)
            return try value.toXdrJson()
        case "SCPQuorumSetXDR":
            let value = try XDRDecoder.decode(SCPQuorumSetXDR.self, data: data)
            return try value.toXdrJson()
        case "SCPStatementTypeXDR":
            let value = try XDRDecoder.decode(SCPStatementTypeXDR.self, data: data)
            return try value.toXdrJson()
        case "SCPStatementXDR":
            let value = try XDRDecoder.decode(SCPStatementXDR.self, data: data)
            return try value.toXdrJson()
        case "SCPStatementXDRConfirmXDR":
            let value = try XDRDecoder.decode(SCPStatementXDRConfirmXDR.self, data: data)
            return try value.toXdrJson()
        case "SCPStatementXDRExternalizeXDR":
            let value = try XDRDecoder.decode(SCPStatementXDRExternalizeXDR.self, data: data)
            return try value.toXdrJson()
        case "SCPStatementXDRPledgesXDR":
            let value = try XDRDecoder.decode(SCPStatementXDRPledgesXDR.self, data: data)
            return try value.toXdrJson()
        case "SCPStatementXDRPrepareXDR":
            let value = try XDRDecoder.decode(SCPStatementXDRPrepareXDR.self, data: data)
            return try value.toXdrJson()
        case "SCSpecEntryKind":
            let value = try XDRDecoder.decode(SCSpecEntryKind.self, data: data)
            return try value.toXdrJson()
        case "SCSpecEntryXDR":
            let value = try XDRDecoder.decode(SCSpecEntryXDR.self, data: data)
            return try value.toXdrJson()
        case "SCSpecEventDataFormat":
            let value = try XDRDecoder.decode(SCSpecEventDataFormat.self, data: data)
            return try value.toXdrJson()
        case "SCSpecEventParamLocationV0":
            let value = try XDRDecoder.decode(SCSpecEventParamLocationV0.self, data: data)
            return try value.toXdrJson()
        case "SCSpecEventParamV0XDR":
            let value = try XDRDecoder.decode(SCSpecEventParamV0XDR.self, data: data)
            return try value.toXdrJson()
        case "SCSpecEventV0XDR":
            let value = try XDRDecoder.decode(SCSpecEventV0XDR.self, data: data)
            return try value.toXdrJson()
        case "SCSpecFunctionInputV0XDR":
            let value = try XDRDecoder.decode(SCSpecFunctionInputV0XDR.self, data: data)
            return try value.toXdrJson()
        case "SCSpecFunctionV0XDR":
            let value = try XDRDecoder.decode(SCSpecFunctionV0XDR.self, data: data)
            return try value.toXdrJson()
        case "SCSpecType":
            let value = try XDRDecoder.decode(SCSpecType.self, data: data)
            return try value.toXdrJson()
        case "SCSpecTypeBytesNXDR":
            let value = try XDRDecoder.decode(SCSpecTypeBytesNXDR.self, data: data)
            return try value.toXdrJson()
        case "SCSpecTypeDefXDR":
            let value = try XDRDecoder.decode(SCSpecTypeDefXDR.self, data: data)
            return try value.toXdrJson()
        case "SCSpecTypeMapXDR":
            let value = try XDRDecoder.decode(SCSpecTypeMapXDR.self, data: data)
            return try value.toXdrJson()
        case "SCSpecTypeOptionXDR":
            let value = try XDRDecoder.decode(SCSpecTypeOptionXDR.self, data: data)
            return try value.toXdrJson()
        case "SCSpecTypeResultXDR":
            let value = try XDRDecoder.decode(SCSpecTypeResultXDR.self, data: data)
            return try value.toXdrJson()
        case "SCSpecTypeTupleXDR":
            let value = try XDRDecoder.decode(SCSpecTypeTupleXDR.self, data: data)
            return try value.toXdrJson()
        case "SCSpecTypeUDTXDR":
            let value = try XDRDecoder.decode(SCSpecTypeUDTXDR.self, data: data)
            return try value.toXdrJson()
        case "SCSpecTypeVecXDR":
            let value = try XDRDecoder.decode(SCSpecTypeVecXDR.self, data: data)
            return try value.toXdrJson()
        case "SCSpecUDTEnumCaseV0XDR":
            let value = try XDRDecoder.decode(SCSpecUDTEnumCaseV0XDR.self, data: data)
            return try value.toXdrJson()
        case "SCSpecUDTEnumV0XDR":
            let value = try XDRDecoder.decode(SCSpecUDTEnumV0XDR.self, data: data)
            return try value.toXdrJson()
        case "SCSpecUDTErrorEnumCaseV0XDR":
            let value = try XDRDecoder.decode(SCSpecUDTErrorEnumCaseV0XDR.self, data: data)
            return try value.toXdrJson()
        case "SCSpecUDTErrorEnumV0XDR":
            let value = try XDRDecoder.decode(SCSpecUDTErrorEnumV0XDR.self, data: data)
            return try value.toXdrJson()
        case "SCSpecUDTStructFieldV0XDR":
            let value = try XDRDecoder.decode(SCSpecUDTStructFieldV0XDR.self, data: data)
            return try value.toXdrJson()
        case "SCSpecUDTStructV0XDR":
            let value = try XDRDecoder.decode(SCSpecUDTStructV0XDR.self, data: data)
            return try value.toXdrJson()
        case "SCSpecUDTUnionCaseTupleV0XDR":
            let value = try XDRDecoder.decode(SCSpecUDTUnionCaseTupleV0XDR.self, data: data)
            return try value.toXdrJson()
        case "SCSpecUDTUnionCaseV0Kind":
            let value = try XDRDecoder.decode(SCSpecUDTUnionCaseV0Kind.self, data: data)
            return try value.toXdrJson()
        case "SCSpecUDTUnionCaseV0XDR":
            let value = try XDRDecoder.decode(SCSpecUDTUnionCaseV0XDR.self, data: data)
            return try value.toXdrJson()
        case "SCSpecUDTUnionCaseVoidV0XDR":
            let value = try XDRDecoder.decode(SCSpecUDTUnionCaseVoidV0XDR.self, data: data)
            return try value.toXdrJson()
        case "SCSpecUDTUnionV0XDR":
            let value = try XDRDecoder.decode(SCSpecUDTUnionV0XDR.self, data: data)
            return try value.toXdrJson()
        case "SCStringXDR":
            let value = try XDRDecoder.decode(SCStringXDR.self, data: data)
            return try SCStringXDRJsonCodec.toXdrJson(value)
        case "SCSymbolXDR":
            let value = try XDRDecoder.decode(SCSymbolXDR.self, data: data)
            return try SCSymbolXDRJsonCodec.toXdrJson(value)
        case "SCValType":
            let value = try XDRDecoder.decode(SCValType.self, data: data)
            return try value.toXdrJson()
        case "SCValXDR":
            let value = try XDRDecoder.decode(SCValXDR.self, data: data)
            return try value.toXdrJson()
        case "SCVecXDR":
            let value = try XDRDecoder.decode(SCVecXDR.self, data: data)
            return try value.toXdrJson()
        case "SendMoreExtendedXDR":
            let value = try XDRDecoder.decode(SendMoreExtendedXDR.self, data: data)
            return try value.toXdrJson()
        case "SendMoreXDR":
            let value = try XDRDecoder.decode(SendMoreXDR.self, data: data)
            return try value.toXdrJson()
        case "SequenceNumberXDR":
            let value = try XDRDecoder.decode(SequenceNumberXDR.self, data: data)
            return try SequenceNumberXDRJsonCodec.toXdrJson(value)
        case "SerializedBinaryFuseFilterXDR":
            let value = try XDRDecoder.decode(SerializedBinaryFuseFilterXDR.self, data: data)
            return try value.toXdrJson()
        case "SetOptionsOperationXDR":
            let value = try XDRDecoder.decode(SetOptionsOperationXDR.self, data: data)
            return try value.toXdrJson()
        case "SetOptionsResultCode":
            let value = try XDRDecoder.decode(SetOptionsResultCode.self, data: data)
            return try value.toXdrJson()
        case "SetOptionsResultXDR":
            let value = try XDRDecoder.decode(SetOptionsResultXDR.self, data: data)
            return try value.toXdrJson()
        case "SetTrustLineFlagsOpXDR":
            let value = try XDRDecoder.decode(SetTrustLineFlagsOpXDR.self, data: data)
            return try value.toXdrJson()
        case "SetTrustLineFlagsResultCode":
            let value = try XDRDecoder.decode(SetTrustLineFlagsResultCode.self, data: data)
            return try value.toXdrJson()
        case "SetTrustLineFlagsResultXDR":
            let value = try XDRDecoder.decode(SetTrustLineFlagsResultXDR.self, data: data)
            return try value.toXdrJson()
        case "ShortHashSeedXDR":
            let value = try XDRDecoder.decode(ShortHashSeedXDR.self, data: data)
            return try value.toXdrJson()
        case "SignatureHintXDR":
            let value = try XDRDecoder.decode(SignatureHintXDR.self, data: data)
            return try SignatureHintXDRJsonCodec.toXdrJson(value)
        case "SignatureXDR":
            let value = try XDRDecoder.decode(SignatureXDR.self, data: data)
            return try SignatureXDRJsonCodec.toXdrJson(value)
        case "SignedTimeSlicedSurveyRequestMessageXDR":
            let value = try XDRDecoder.decode(SignedTimeSlicedSurveyRequestMessageXDR.self, data: data)
            return try value.toXdrJson()
        case "SignedTimeSlicedSurveyResponseMessageXDR":
            let value = try XDRDecoder.decode(SignedTimeSlicedSurveyResponseMessageXDR.self, data: data)
            return try value.toXdrJson()
        case "SignedTimeSlicedSurveyStartCollectingMessageXDR":
            let value = try XDRDecoder.decode(SignedTimeSlicedSurveyStartCollectingMessageXDR.self, data: data)
            return try value.toXdrJson()
        case "SignedTimeSlicedSurveyStopCollectingMessageXDR":
            let value = try XDRDecoder.decode(SignedTimeSlicedSurveyStopCollectingMessageXDR.self, data: data)
            return try value.toXdrJson()
        case "SignerKeyType":
            let value = try XDRDecoder.decode(SignerKeyType.self, data: data)
            return try value.toXdrJson()
        case "SignerKeyXDR":
            let value = try XDRDecoder.decode(SignerKeyXDR.self, data: data)
            return try value.toXdrJson()
        case "SignerXDR":
            let value = try XDRDecoder.decode(SignerXDR.self, data: data)
            return try value.toXdrJson()
        case "SimplePaymentResultXDR":
            let value = try XDRDecoder.decode(SimplePaymentResultXDR.self, data: data)
            return try value.toXdrJson()
        case "SorobanAddressCredentialsWithDelegatesXDR":
            let value = try XDRDecoder.decode(SorobanAddressCredentialsWithDelegatesXDR.self, data: data)
            return try value.toXdrJson()
        case "SorobanAddressCredentialsXDR":
            let value = try XDRDecoder.decode(SorobanAddressCredentialsXDR.self, data: data)
            return try value.toXdrJson()
        case "SorobanAuthorizationEntriesXDR":
            let value = try XDRDecoder.decode(SorobanAuthorizationEntriesXDR.self, data: data)
            return try value.toXdrJson()
        case "SorobanAuthorizationEntryXDR":
            let value = try XDRDecoder.decode(SorobanAuthorizationEntryXDR.self, data: data)
            return try value.toXdrJson()
        case "SorobanAuthorizedFunctionType":
            let value = try XDRDecoder.decode(SorobanAuthorizedFunctionType.self, data: data)
            return try value.toXdrJson()
        case "SorobanAuthorizedFunctionXDR":
            let value = try XDRDecoder.decode(SorobanAuthorizedFunctionXDR.self, data: data)
            return try value.toXdrJson()
        case "SorobanAuthorizedInvocationXDR":
            let value = try XDRDecoder.decode(SorobanAuthorizedInvocationXDR.self, data: data)
            return try value.toXdrJson()
        case "SorobanCredentialsType":
            let value = try XDRDecoder.decode(SorobanCredentialsType.self, data: data)
            return try value.toXdrJson()
        case "SorobanCredentialsXDR":
            let value = try XDRDecoder.decode(SorobanCredentialsXDR.self, data: data)
            return try value.toXdrJson()
        case "SorobanDelegateSignatureXDR":
            let value = try XDRDecoder.decode(SorobanDelegateSignatureXDR.self, data: data)
            return try value.toXdrJson()
        case "SorobanResourcesExt":
            let value = try XDRDecoder.decode(SorobanResourcesExt.self, data: data)
            return try value.toXdrJson()
        case "SorobanResourcesExtV0":
            let value = try XDRDecoder.decode(SorobanResourcesExtV0.self, data: data)
            return try value.toXdrJson()
        case "SorobanResourcesXDR":
            let value = try XDRDecoder.decode(SorobanResourcesXDR.self, data: data)
            return try value.toXdrJson()
        case "SorobanTransactionDataXDR":
            let value = try XDRDecoder.decode(SorobanTransactionDataXDR.self, data: data)
            return try value.toXdrJson()
        case "SorobanTransactionMetaExt":
            let value = try XDRDecoder.decode(SorobanTransactionMetaExt.self, data: data)
            return try value.toXdrJson()
        case "SorobanTransactionMetaExtV1":
            let value = try XDRDecoder.decode(SorobanTransactionMetaExtV1.self, data: data)
            return try value.toXdrJson()
        case "SorobanTransactionMetaV2XDR":
            let value = try XDRDecoder.decode(SorobanTransactionMetaV2XDR.self, data: data)
            return try value.toXdrJson()
        case "SorobanTransactionMetaXDR":
            let value = try XDRDecoder.decode(SorobanTransactionMetaXDR.self, data: data)
            return try value.toXdrJson()
        case "StateArchivalSettingsXDR":
            let value = try XDRDecoder.decode(StateArchivalSettingsXDR.self, data: data)
            return try value.toXdrJson()
        case "StellarMessageXDR":
            let value = try XDRDecoder.decode(StellarMessageXDR.self, data: data)
            return try value.toXdrJson()
        case "StellarValueTypeXDR":
            let value = try XDRDecoder.decode(StellarValueTypeXDR.self, data: data)
            return try value.toXdrJson()
        case "StellarValueXDR":
            let value = try XDRDecoder.decode(StellarValueXDR.self, data: data)
            return try value.toXdrJson()
        case "StellarValueXDRExtXDR":
            let value = try XDRDecoder.decode(StellarValueXDRExtXDR.self, data: data)
            return try value.toXdrJson()
        case "StellarValueXDRProposedValueXDR":
            let value = try XDRDecoder.decode(StellarValueXDRProposedValueXDR.self, data: data)
            return try value.toXdrJson()
        case "StoredDebugTransactionSetXDR":
            let value = try XDRDecoder.decode(StoredDebugTransactionSetXDR.self, data: data)
            return try value.toXdrJson()
        case "StoredTransactionSetXDR":
            let value = try XDRDecoder.decode(StoredTransactionSetXDR.self, data: data)
            return try value.toXdrJson()
        case "String32XDR":
            let value = try XDRDecoder.decode(String32XDR.self, data: data)
            return try String32XDRJsonCodec.toXdrJson(value)
        case "String64XDR":
            let value = try XDRDecoder.decode(String64XDR.self, data: data)
            return try String64XDRJsonCodec.toXdrJson(value)
        case "SurveyMessageCommandTypeXDR":
            let value = try XDRDecoder.decode(SurveyMessageCommandTypeXDR.self, data: data)
            return try value.toXdrJson()
        case "SurveyMessageResponseTypeXDR":
            let value = try XDRDecoder.decode(SurveyMessageResponseTypeXDR.self, data: data)
            return try value.toXdrJson()
        case "SurveyRequestMessageXDR":
            let value = try XDRDecoder.decode(SurveyRequestMessageXDR.self, data: data)
            return try value.toXdrJson()
        case "SurveyResponseBodyXDR":
            let value = try XDRDecoder.decode(SurveyResponseBodyXDR.self, data: data)
            return try value.toXdrJson()
        case "SurveyResponseMessageXDR":
            let value = try XDRDecoder.decode(SurveyResponseMessageXDR.self, data: data)
            return try value.toXdrJson()
        case "TTLEntryXDR":
            let value = try XDRDecoder.decode(TTLEntryXDR.self, data: data)
            return try value.toXdrJson()
        case "ThresholdIndexesXDR":
            let value = try XDRDecoder.decode(ThresholdIndexesXDR.self, data: data)
            return try value.toXdrJson()
        case "ThresholdsXDR":
            let value = try XDRDecoder.decode(ThresholdsXDR.self, data: data)
            return try ThresholdsXDRJsonCodec.toXdrJson(value)
        case "TimeBoundsXDR":
            let value = try XDRDecoder.decode(TimeBoundsXDR.self, data: data)
            return try value.toXdrJson()
        case "TimePointXDR":
            let value = try XDRDecoder.decode(TimePointXDR.self, data: data)
            return try TimePointXDRJsonCodec.toXdrJson(value)
        case "TimeSlicedNodeDataXDR":
            let value = try XDRDecoder.decode(TimeSlicedNodeDataXDR.self, data: data)
            return try value.toXdrJson()
        case "TimeSlicedPeerDataListXDR":
            let value = try XDRDecoder.decode(TimeSlicedPeerDataListXDR.self, data: data)
            return try value.toXdrJson()
        case "TimeSlicedPeerDataXDR":
            let value = try XDRDecoder.decode(TimeSlicedPeerDataXDR.self, data: data)
            return try value.toXdrJson()
        case "TimeSlicedSurveyRequestMessageXDR":
            let value = try XDRDecoder.decode(TimeSlicedSurveyRequestMessageXDR.self, data: data)
            return try value.toXdrJson()
        case "TimeSlicedSurveyResponseMessageXDR":
            let value = try XDRDecoder.decode(TimeSlicedSurveyResponseMessageXDR.self, data: data)
            return try value.toXdrJson()
        case "TimeSlicedSurveyStartCollectingMessageXDR":
            let value = try XDRDecoder.decode(TimeSlicedSurveyStartCollectingMessageXDR.self, data: data)
            return try value.toXdrJson()
        case "TimeSlicedSurveyStopCollectingMessageXDR":
            let value = try XDRDecoder.decode(TimeSlicedSurveyStopCollectingMessageXDR.self, data: data)
            return try value.toXdrJson()
        case "TopologyResponseBodyV2XDR":
            let value = try XDRDecoder.decode(TopologyResponseBodyV2XDR.self, data: data)
            return try value.toXdrJson()
        case "TransactionEnvelopeXDR":
            let value = try XDRDecoder.decode(TransactionEnvelopeXDR.self, data: data)
            return try value.toXdrJson()
        case "TransactionEventStage":
            let value = try XDRDecoder.decode(TransactionEventStage.self, data: data)
            return try value.toXdrJson()
        case "TransactionEventXDR":
            let value = try XDRDecoder.decode(TransactionEventXDR.self, data: data)
            return try value.toXdrJson()
        case "TransactionExtXDR":
            let value = try XDRDecoder.decode(TransactionExtXDR.self, data: data)
            return try value.toXdrJson()
        case "TransactionHistoryEntryXDR":
            let value = try XDRDecoder.decode(TransactionHistoryEntryXDR.self, data: data)
            return try value.toXdrJson()
        case "TransactionHistoryEntryXDRExtXDR":
            let value = try XDRDecoder.decode(TransactionHistoryEntryXDRExtXDR.self, data: data)
            return try value.toXdrJson()
        case "TransactionHistoryResultEntryXDR":
            let value = try XDRDecoder.decode(TransactionHistoryResultEntryXDR.self, data: data)
            return try value.toXdrJson()
        case "TransactionHistoryResultEntryXDRExtXDR":
            let value = try XDRDecoder.decode(TransactionHistoryResultEntryXDRExtXDR.self, data: data)
            return try value.toXdrJson()
        case "TransactionMetaV1XDR":
            let value = try XDRDecoder.decode(TransactionMetaV1XDR.self, data: data)
            return try value.toXdrJson()
        case "TransactionMetaV2XDR":
            let value = try XDRDecoder.decode(TransactionMetaV2XDR.self, data: data)
            return try value.toXdrJson()
        case "TransactionMetaV3XDR":
            let value = try XDRDecoder.decode(TransactionMetaV3XDR.self, data: data)
            return try value.toXdrJson()
        case "TransactionMetaV4XDR":
            let value = try XDRDecoder.decode(TransactionMetaV4XDR.self, data: data)
            return try value.toXdrJson()
        case "TransactionMetaXDR":
            let value = try XDRDecoder.decode(TransactionMetaXDR.self, data: data)
            return try value.toXdrJson()
        case "TransactionPhaseXDR":
            let value = try XDRDecoder.decode(TransactionPhaseXDR.self, data: data)
            return try value.toXdrJson()
        case "TransactionResultBodyXDR":
            let value = try XDRDecoder.decode(TransactionResultBodyXDR.self, data: data)
            return try value.toXdrJson()
        case "TransactionResultCode":
            let value = try XDRDecoder.decode(TransactionResultCode.self, data: data)
            return try value.toXdrJson()
        case "TransactionResultMetaV1XDR":
            let value = try XDRDecoder.decode(TransactionResultMetaV1XDR.self, data: data)
            return try value.toXdrJson()
        case "TransactionResultMetaXDR":
            let value = try XDRDecoder.decode(TransactionResultMetaXDR.self, data: data)
            return try value.toXdrJson()
        case "TransactionResultPairXDR":
            let value = try XDRDecoder.decode(TransactionResultPairXDR.self, data: data)
            return try value.toXdrJson()
        case "TransactionResultSetXDR":
            let value = try XDRDecoder.decode(TransactionResultSetXDR.self, data: data)
            return try value.toXdrJson()
        case "TransactionResultXDR":
            let value = try XDRDecoder.decode(TransactionResultXDR.self, data: data)
            return try value.toXdrJson()
        case "TransactionResultXDRExtXDR":
            let value = try XDRDecoder.decode(TransactionResultXDRExtXDR.self, data: data)
            return try value.toXdrJson()
        case "TransactionSetV1XDR":
            let value = try XDRDecoder.decode(TransactionSetV1XDR.self, data: data)
            return try value.toXdrJson()
        case "TransactionSetXDR":
            let value = try XDRDecoder.decode(TransactionSetXDR.self, data: data)
            return try value.toXdrJson()
        case "TransactionSignaturePayload":
            let value = try XDRDecoder.decode(TransactionSignaturePayload.self, data: data)
            return try value.toXdrJson()
        case "TransactionSignaturePayloadTaggedTransactionXDR":
            let value = try XDRDecoder.decode(TransactionSignaturePayloadTaggedTransactionXDR.self, data: data)
            return try value.toXdrJson()
        case "TransactionV0EnvelopeXDR":
            let value = try XDRDecoder.decode(TransactionV0EnvelopeXDR.self, data: data)
            return try value.toXdrJson()
        case "TransactionV0XDR":
            let value = try XDRDecoder.decode(TransactionV0XDR.self, data: data)
            return try value.toXdrJson()
        case "TransactionV0XDRExtXDR":
            let value = try XDRDecoder.decode(TransactionV0XDRExtXDR.self, data: data)
            return try value.toXdrJson()
        case "TransactionV1EnvelopeXDR":
            let value = try XDRDecoder.decode(TransactionV1EnvelopeXDR.self, data: data)
            return try value.toXdrJson()
        case "TransactionXDR":
            let value = try XDRDecoder.decode(TransactionXDR.self, data: data)
            return try value.toXdrJson()
        case "TrustLineFlags":
            let value = try XDRDecoder.decode(TrustLineFlags.self, data: data)
            return try value.toXdrJson()
        case "TrustlineAssetXDR":
            let value = try XDRDecoder.decode(TrustlineAssetXDR.self, data: data)
            return try value.toXdrJson()
        case "TrustlineEntryExtV1XDR":
            let value = try XDRDecoder.decode(TrustlineEntryExtV1XDR.self, data: data)
            return try value.toXdrJson()
        case "TrustlineEntryExtXDR":
            let value = try XDRDecoder.decode(TrustlineEntryExtXDR.self, data: data)
            return try value.toXdrJson()
        case "TrustlineEntryExtensionV1":
            let value = try XDRDecoder.decode(TrustlineEntryExtensionV1.self, data: data)
            return try value.toXdrJson()
        case "TrustlineEntryExtensionV2":
            let value = try XDRDecoder.decode(TrustlineEntryExtensionV2.self, data: data)
            return try value.toXdrJson()
        case "TrustlineEntryExtensionV2ExtXDR":
            let value = try XDRDecoder.decode(TrustlineEntryExtensionV2ExtXDR.self, data: data)
            return try value.toXdrJson()
        case "TrustlineEntryXDR":
            let value = try XDRDecoder.decode(TrustlineEntryXDR.self, data: data)
            return try value.toXdrJson()
        case "TxAdvertVectorXDR":
            let value = try XDRDecoder.decode(TxAdvertVectorXDR.self, data: data)
            return try value.toXdrJson()
        case "TxDemandVectorXDR":
            let value = try XDRDecoder.decode(TxDemandVectorXDR.self, data: data)
            return try value.toXdrJson()
        case "TxSetComponentTypeXDR":
            let value = try XDRDecoder.decode(TxSetComponentTypeXDR.self, data: data)
            return try value.toXdrJson()
        case "TxSetComponentXDR":
            let value = try XDRDecoder.decode(TxSetComponentXDR.self, data: data)
            return try value.toXdrJson()
        case "TxSetComponentXDRTxsMaybeDiscountedFeeXDR":
            let value = try XDRDecoder.decode(TxSetComponentXDRTxsMaybeDiscountedFeeXDR.self, data: data)
            return try value.toXdrJson()
        case "UInt128PartsXDR":
            let value = try XDRDecoder.decode(UInt128PartsXDR.self, data: data)
            return try value.toXdrJson()
        case "UInt256PartsXDR":
            let value = try XDRDecoder.decode(UInt256PartsXDR.self, data: data)
            return try value.toXdrJson()
        case "Uint256XDR":
            let value = try XDRDecoder.decode(Uint256XDR.self, data: data)
            return try Uint256XDRJsonCodec.toXdrJson(value)
        case "Uint32XDR":
            let value = try XDRDecoder.decode(Uint32XDR.self, data: data)
            return try Uint32XDRJsonCodec.toXdrJson(value)
        case "Uint64XDR":
            let value = try XDRDecoder.decode(Uint64XDR.self, data: data)
            return try Uint64XDRJsonCodec.toXdrJson(value)
        case "UpgradeEntryMetaXDR":
            let value = try XDRDecoder.decode(UpgradeEntryMetaXDR.self, data: data)
            return try value.toXdrJson()
        case "UpgradeTypeXDR":
            let value = try XDRDecoder.decode(UpgradeTypeXDR.self, data: data)
            return try UpgradeTypeXDRJsonCodec.toXdrJson(value)
        case "ValueXDR":
            let value = try XDRDecoder.decode(ValueXDR.self, data: data)
            return try ValueXDRJsonCodec.toXdrJson(value)
        default:
            throw Sep51CorpusDispatchError.unknownType(iosType)
        }
    }

    /// Reads the XDR-JSON text and emits the base64 XDR the binary codec encodes it to.
    static func xdrBase64(forType iosType: String, json: String) throws -> String {
        switch iosType {
        case "AccountEntryExtV1XDR":
            let value = try AccountEntryExtV1XDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "AccountEntryExtV2XDR":
            let value = try AccountEntryExtV2XDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "AccountEntryExtXDR":
            let value = try AccountEntryExtXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "AccountEntryExtensionV1":
            let value = try AccountEntryExtensionV1.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "AccountEntryExtensionV2":
            let value = try AccountEntryExtensionV2.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "AccountEntryExtensionV3":
            let value = try AccountEntryExtensionV3.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "AccountEntryXDR":
            let value = try AccountEntryXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "AccountFlags":
            let value = try AccountFlags.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "AccountIDXDR":
            let value = try AccountIDXDRJsonCodec.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "AccountMergeResultCode":
            let value = try AccountMergeResultCode.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "AccountMergeResultXDR":
            let value = try AccountMergeResultXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "AllowTrustOpAssetXDR":
            let value = try AllowTrustOpAssetXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "AllowTrustOperationXDR":
            let value = try AllowTrustOperationXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "AllowTrustResultCode":
            let value = try AllowTrustResultCode.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "AllowTrustResultXDR":
            let value = try AllowTrustResultXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "Alpha12XDR":
            let value = try Alpha12XDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "Alpha4XDR":
            let value = try Alpha4XDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "AssetCode12XDR":
            let value = try AssetCode12XDRJsonCodec.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "AssetCode4XDR":
            let value = try AssetCode4XDRJsonCodec.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "AssetType":
            let value = try AssetType.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "AssetXDR":
            let value = try AssetXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "AuthCertXDR":
            let value = try AuthCertXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "AuthXDR":
            let value = try AuthXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "AuthenticatedMessageXDR":
            let value = try AuthenticatedMessageXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "AuthenticatedMessageXDRV0XDR":
            let value = try AuthenticatedMessageXDRV0XDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "BeginSponsoringFutureReservesOpXDR":
            let value = try BeginSponsoringFutureReservesOpXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "BeginSponsoringFutureReservesResultCode":
            let value = try BeginSponsoringFutureReservesResultCode.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "BeginSponsoringFutureReservesResultXDR":
            let value = try BeginSponsoringFutureReservesResultXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "BinaryFuseFilterTypeXDR":
            let value = try BinaryFuseFilterTypeXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "BucketEntryTypeXDR":
            let value = try BucketEntryTypeXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "BucketEntryXDR":
            let value = try BucketEntryXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "BucketListTypeXDR":
            let value = try BucketListTypeXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "BucketMetadataXDR":
            let value = try BucketMetadataXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "BucketMetadataXDRExtXDR":
            let value = try BucketMetadataXDRExtXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "BumpSequenceOperationXDR":
            let value = try BumpSequenceOperationXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "BumpSequenceResultCode":
            let value = try BumpSequenceResultCode.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "BumpSequenceResultXDR":
            let value = try BumpSequenceResultXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ChangeTrustAssetXDR":
            let value = try ChangeTrustAssetXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ChangeTrustOperationXDR":
            let value = try ChangeTrustOperationXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ChangeTrustResultCode":
            let value = try ChangeTrustResultCode.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ChangeTrustResultXDR":
            let value = try ChangeTrustResultXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ClaimAtomType":
            let value = try ClaimAtomType.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ClaimAtomXDR":
            let value = try ClaimAtomXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ClaimClaimableBalanceOpXDR":
            let value = try ClaimClaimableBalanceOpXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ClaimClaimableBalanceResultCode":
            let value = try ClaimClaimableBalanceResultCode.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ClaimClaimableBalanceResultXDR":
            let value = try ClaimClaimableBalanceResultXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ClaimLiquidityAtomXDR":
            let value = try ClaimLiquidityAtomXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ClaimOfferAtomV0XDR":
            let value = try ClaimOfferAtomV0XDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ClaimOfferAtomXDR":
            let value = try ClaimOfferAtomXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ClaimPredicateType":
            let value = try ClaimPredicateType.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ClaimPredicateXDR":
            let value = try ClaimPredicateXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ClaimableBalanceEntryExtXDR":
            let value = try ClaimableBalanceEntryExtXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ClaimableBalanceEntryExtensionV1":
            let value = try ClaimableBalanceEntryExtensionV1.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ClaimableBalanceEntryExtensionV1ExtXDR":
            let value = try ClaimableBalanceEntryExtensionV1ExtXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ClaimableBalanceEntryXDR":
            let value = try ClaimableBalanceEntryXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ClaimableBalanceFlags":
            let value = try ClaimableBalanceFlags.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ClaimableBalanceIDType":
            let value = try ClaimableBalanceIDType.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ClaimableBalanceIDXDR":
            let value = try ClaimableBalanceIDXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ClaimantType":
            let value = try ClaimantType.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ClaimantV0XDR":
            let value = try ClaimantV0XDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ClaimantXDR":
            let value = try ClaimantXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ClawbackClaimableBalanceOpXDR":
            let value = try ClawbackClaimableBalanceOpXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ClawbackClaimableBalanceResultCode":
            let value = try ClawbackClaimableBalanceResultCode.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ClawbackClaimableBalanceResultXDR":
            let value = try ClawbackClaimableBalanceResultXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ClawbackOpXDR":
            let value = try ClawbackOpXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ClawbackResultCode":
            let value = try ClawbackResultCode.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ClawbackResultXDR":
            let value = try ClawbackResultXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ConfigSettingContractBandwidthV0XDR":
            let value = try ConfigSettingContractBandwidthV0XDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ConfigSettingContractComputeV0XDR":
            let value = try ConfigSettingContractComputeV0XDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ConfigSettingContractEventsV0XDR":
            let value = try ConfigSettingContractEventsV0XDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ConfigSettingContractExecutionLanesV0XDR":
            let value = try ConfigSettingContractExecutionLanesV0XDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ConfigSettingContractHistoricalDataV0XDR":
            let value = try ConfigSettingContractHistoricalDataV0XDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ConfigSettingContractLedgerCostExtV0":
            let value = try ConfigSettingContractLedgerCostExtV0.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ConfigSettingContractLedgerCostV0XDR":
            let value = try ConfigSettingContractLedgerCostV0XDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ConfigSettingContractParallelComputeV0":
            let value = try ConfigSettingContractParallelComputeV0.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ConfigSettingEntryXDR":
            let value = try ConfigSettingEntryXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ConfigSettingID":
            let value = try ConfigSettingID.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ConfigSettingSCPTiming":
            let value = try ConfigSettingSCPTiming.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ConfigUpgradeSetKeyXDR":
            let value = try ConfigUpgradeSetKeyXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ConfigUpgradeSetXDR":
            let value = try ConfigUpgradeSetXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ConstantProductXDR":
            let value = try ConstantProductXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ContractCodeCostInputsXDR":
            let value = try ContractCodeCostInputsXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ContractCodeEntryExt":
            let value = try ContractCodeEntryExt.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ContractCodeEntryExtV1":
            let value = try ContractCodeEntryExtV1.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ContractCodeEntryXDR":
            let value = try ContractCodeEntryXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ContractCostParamEntryXDR":
            let value = try ContractCostParamEntryXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ContractCostParamsXDR":
            let value = try ContractCostParamsXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ContractCostType":
            let value = try ContractCostType.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ContractDataDurability":
            let value = try ContractDataDurability.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ContractDataEntryXDR":
            let value = try ContractDataEntryXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ContractEventBodyV0XDR":
            let value = try ContractEventBodyV0XDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ContractEventBodyXDR":
            let value = try ContractEventBodyXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ContractEventType":
            let value = try ContractEventType.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ContractEventXDR":
            let value = try ContractEventXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ContractExecutableExternalRefXDR":
            let value = try ContractExecutableExternalRefXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ContractExecutableType":
            let value = try ContractExecutableType.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ContractExecutableXDR":
            let value = try ContractExecutableXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ContractIDPreimageFromAddressXDR":
            let value = try ContractIDPreimageFromAddressXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ContractIDPreimageType":
            let value = try ContractIDPreimageType.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ContractIDPreimageXDR":
            let value = try ContractIDPreimageXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ContractIDXDR":
            let value = try ContractIDXDRJsonCodec.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "CreateAccountOperationXDR":
            let value = try CreateAccountOperationXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "CreateAccountResultCode":
            let value = try CreateAccountResultCode.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "CreateAccountResultXDR":
            let value = try CreateAccountResultXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "CreateClaimableBalanceOpXDR":
            let value = try CreateClaimableBalanceOpXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "CreateClaimableBalanceResultCode":
            let value = try CreateClaimableBalanceResultCode.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "CreateClaimableBalanceResultXDR":
            let value = try CreateClaimableBalanceResultXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "CreateContractArgsXDR":
            let value = try CreateContractArgsXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "CreateContractV2ArgsXDR":
            let value = try CreateContractV2ArgsXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "CreatePassiveOfferOperationXDR":
            let value = try CreatePassiveOfferOperationXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "CryptoKeyType":
            let value = try CryptoKeyType.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "Curve25519PublicXDR":
            let value = try Curve25519PublicXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "Curve25519SecretXDR":
            let value = try Curve25519SecretXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "DataEntryXDR":
            let value = try DataEntryXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "DataEntryXDRExtXDR":
            let value = try DataEntryXDRExtXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "DataValueXDR":
            let value = try DataValueXDRJsonCodec.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "DecoratedSignatureXDR":
            let value = try DecoratedSignatureXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "DependentTxClusterXDR":
            let value = try DependentTxClusterXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "DiagnosticEventXDR":
            let value = try DiagnosticEventXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "DontHaveXDR":
            let value = try DontHaveXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "DurationXDR":
            let value = try DurationXDRJsonCodec.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "Ed25519SignedPayload":
            let value = try Ed25519SignedPayload.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "EncodedLedgerKeyXDR":
            let value = try EncodedLedgerKeyXDRJsonCodec.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "EncryptedBodyXDR":
            let value = try EncryptedBodyXDRJsonCodec.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "EndSponsoringFutureReservesResultCode":
            let value = try EndSponsoringFutureReservesResultCode.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "EndSponsoringFutureReservesResultXDR":
            let value = try EndSponsoringFutureReservesResultXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "EnvelopeType":
            let value = try EnvelopeType.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ErrorCodeXDR":
            let value = try ErrorCodeXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ErrorXDR":
            let value = try ErrorXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "EvictionIteratorXDR":
            let value = try EvictionIteratorXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ExtendFootprintTTLOpXDR":
            let value = try ExtendFootprintTTLOpXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ExtendFootprintTTLResultCode":
            let value = try ExtendFootprintTTLResultCode.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ExtendFootprintTTLResultXDR":
            let value = try ExtendFootprintTTLResultXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ExtensionPoint":
            let value = try ExtensionPoint.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "FeeBumpTransactionEnvelopeXDR":
            let value = try FeeBumpTransactionEnvelopeXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "FeeBumpTransactionXDR":
            let value = try FeeBumpTransactionXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "FeeBumpTransactionXDRExtXDR":
            let value = try FeeBumpTransactionXDRExtXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "FeeBumpTransactionXDRInnerTxXDR":
            let value = try FeeBumpTransactionXDRInnerTxXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "FloodAdvertXDR":
            let value = try FloodAdvertXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "FloodDemandXDR":
            let value = try FloodDemandXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "FreezeBypassTxsDeltaXDR":
            let value = try FreezeBypassTxsDeltaXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "FreezeBypassTxsXDR":
            let value = try FreezeBypassTxsXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "FrozenLedgerKeysDeltaXDR":
            let value = try FrozenLedgerKeysDeltaXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "FrozenLedgerKeysXDR":
            let value = try FrozenLedgerKeysXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "GeneralizedTransactionSetXDR":
            let value = try GeneralizedTransactionSetXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "HashIDPreimageContractIDXDR":
            let value = try HashIDPreimageContractIDXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "HashIDPreimageSorobanAuthorizationWithAddressXDR":
            let value = try HashIDPreimageSorobanAuthorizationWithAddressXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "HashIDPreimageSorobanAuthorizationXDR":
            let value = try HashIDPreimageSorobanAuthorizationXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "HashIDPreimageXDR":
            let value = try HashIDPreimageXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "HashXDR":
            let value = try HashXDRJsonCodec.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "HelloXDR":
            let value = try HelloXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "HmacSha256KeyXDR":
            let value = try HmacSha256KeyXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "HmacSha256MacXDR":
            let value = try HmacSha256MacXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "HostFunctionType":
            let value = try HostFunctionType.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "HostFunctionXDR":
            let value = try HostFunctionXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "HotArchiveBucketEntryTypeXDR":
            let value = try HotArchiveBucketEntryTypeXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "HotArchiveBucketEntryXDR":
            let value = try HotArchiveBucketEntryXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "IPAddrTypeXDR":
            let value = try IPAddrTypeXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "InflationPayoutXDR":
            let value = try InflationPayoutXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "InflationResultCode":
            let value = try InflationResultCode.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "InflationResultXDR":
            let value = try InflationResultXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "InnerTransactionResultBodyXDR":
            let value = try InnerTransactionResultBodyXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "InnerTransactionResultPair":
            let value = try InnerTransactionResultPair.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "InnerTransactionResultXDR":
            let value = try InnerTransactionResultXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "InnerTransactionResultXDRExtXDR":
            let value = try InnerTransactionResultXDRExtXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "Int128PartsXDR":
            let value = try Int128PartsXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "Int256PartsXDR":
            let value = try Int256PartsXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "Int32XDR":
            let value = try Int32XDRJsonCodec.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "Int64XDR":
            let value = try Int64XDRJsonCodec.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "InvokeContractArgsXDR":
            let value = try InvokeContractArgsXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "InvokeHostFunctionOpXDR":
            let value = try InvokeHostFunctionOpXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "InvokeHostFunctionResultCode":
            let value = try InvokeHostFunctionResultCode.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "InvokeHostFunctionResultXDR":
            let value = try InvokeHostFunctionResultXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "InvokeHostFunctionSuccessPreImageXDR":
            let value = try InvokeHostFunctionSuccessPreImageXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "LedgerBoundsXDR":
            let value = try LedgerBoundsXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "LedgerCloseMetaBatchXDR":
            let value = try LedgerCloseMetaBatchXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "LedgerCloseMetaExtV1XDR":
            let value = try LedgerCloseMetaExtV1XDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "LedgerCloseMetaExtXDR":
            let value = try LedgerCloseMetaExtXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "LedgerCloseMetaV0XDR":
            let value = try LedgerCloseMetaV0XDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "LedgerCloseMetaV1XDR":
            let value = try LedgerCloseMetaV1XDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "LedgerCloseMetaV2XDR":
            let value = try LedgerCloseMetaV2XDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "LedgerCloseMetaXDR":
            let value = try LedgerCloseMetaXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "LedgerCloseValueSignatureXDR":
            let value = try LedgerCloseValueSignatureXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "LedgerEntryChangeType":
            let value = try LedgerEntryChangeType.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "LedgerEntryChangeXDR":
            let value = try LedgerEntryChangeXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "LedgerEntryChangesXDR":
            let value = try LedgerEntryChangesXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "LedgerEntryDataXDR":
            let value = try LedgerEntryDataXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "LedgerEntryExtXDR":
            let value = try LedgerEntryExtXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "LedgerEntryExtensionV1":
            let value = try LedgerEntryExtensionV1.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "LedgerEntryExtensionV1ExtXDR":
            let value = try LedgerEntryExtensionV1ExtXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "LedgerEntryType":
            let value = try LedgerEntryType.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "LedgerEntryXDR":
            let value = try LedgerEntryXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "LedgerFootprintXDR":
            let value = try LedgerFootprintXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "LedgerHeaderExtensionV1XDR":
            let value = try LedgerHeaderExtensionV1XDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "LedgerHeaderExtensionV1XDRExtXDR":
            let value = try LedgerHeaderExtensionV1XDRExtXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "LedgerHeaderFlagsXDR":
            let value = try LedgerHeaderFlagsXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "LedgerHeaderHistoryEntryXDR":
            let value = try LedgerHeaderHistoryEntryXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "LedgerHeaderHistoryEntryXDRExtXDR":
            let value = try LedgerHeaderHistoryEntryXDRExtXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "LedgerHeaderXDR":
            let value = try LedgerHeaderXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "LedgerHeaderXDRExtXDR":
            let value = try LedgerHeaderXDRExtXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "LedgerKeyAccountXDR":
            let value = try LedgerKeyAccountXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "LedgerKeyClaimableBalanceXDR":
            let value = try LedgerKeyClaimableBalanceXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "LedgerKeyConfigSettingXDR":
            let value = try LedgerKeyConfigSettingXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "LedgerKeyContractCodeXDR":
            let value = try LedgerKeyContractCodeXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "LedgerKeyContractDataXDR":
            let value = try LedgerKeyContractDataXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "LedgerKeyDataXDR":
            let value = try LedgerKeyDataXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "LedgerKeyLiquidityPoolXDR":
            let value = try LedgerKeyLiquidityPoolXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "LedgerKeyOfferXDR":
            let value = try LedgerKeyOfferXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "LedgerKeyTTLXDR":
            let value = try LedgerKeyTTLXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "LedgerKeyTrustLineXDR":
            let value = try LedgerKeyTrustLineXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "LedgerKeyXDR":
            let value = try LedgerKeyXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "LedgerSCPMessagesXDR":
            let value = try LedgerSCPMessagesXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "LedgerUpgradeTypeXDR":
            let value = try LedgerUpgradeTypeXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "LedgerUpgradeXDR":
            let value = try LedgerUpgradeXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "LiabilitiesXDR":
            let value = try LiabilitiesXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "LiquidityPoolBodyXDR":
            let value = try LiquidityPoolBodyXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "LiquidityPoolConstantProductParametersXDR":
            let value = try LiquidityPoolConstantProductParametersXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "LiquidityPoolDepositOpXDR":
            let value = try LiquidityPoolDepositOpXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "LiquidityPoolDepositResulCode":
            let value = try LiquidityPoolDepositResulCode.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "LiquidityPoolDepositResultXDR":
            let value = try LiquidityPoolDepositResultXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "LiquidityPoolEntryXDR":
            let value = try LiquidityPoolEntryXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "LiquidityPoolParametersXDR":
            let value = try LiquidityPoolParametersXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "LiquidityPoolType":
            let value = try LiquidityPoolType.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "LiquidityPoolWithdrawOpXDR":
            let value = try LiquidityPoolWithdrawOpXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "LiquidityPoolWithdrawResulCode":
            let value = try LiquidityPoolWithdrawResulCode.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "LiquidityPoolWithdrawResultXDR":
            let value = try LiquidityPoolWithdrawResultXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ManageDataOperationXDR":
            let value = try ManageDataOperationXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ManageDataResultCode":
            let value = try ManageDataResultCode.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ManageDataResultXDR":
            let value = try ManageDataResultXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ManageOfferEffect":
            let value = try ManageOfferEffect.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ManageOfferResultCode":
            let value = try ManageOfferResultCode.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ManageOfferResultXDR":
            let value = try ManageOfferResultXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ManageOfferSuccessResultOfferXDR":
            let value = try ManageOfferSuccessResultOfferXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ManageOfferSuccessResultXDR":
            let value = try ManageOfferSuccessResultXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "MemoType":
            let value = try MemoType.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "MemoXDR":
            let value = try MemoXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "MessageTypeXDR":
            let value = try MessageTypeXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "MuxedAccountMed25519XDR":
            let value = try MuxedAccountMed25519XDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "MuxedAccountXDR":
            let value = try MuxedAccountXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "MuxedAccountXDRMed25519XDR":
            let value = try MuxedAccountXDRMed25519XDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "NodeIDXDR":
            let value = try NodeIDXDRJsonCodec.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "OfferEntryFlagsXDR":
            let value = try OfferEntryFlagsXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "OfferEntryXDR":
            let value = try OfferEntryXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "OfferEntryXDRExtXDR":
            let value = try OfferEntryXDRExtXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "OperationBodyXDR":
            let value = try OperationBodyXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "OperationID":
            let value = try OperationID.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "OperationMetaV2XDR":
            let value = try OperationMetaV2XDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "OperationMetaXDR":
            let value = try OperationMetaXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "OperationResultCode":
            let value = try OperationResultCode.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "OperationResultXDR":
            let value = try OperationResultXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "OperationResultXDRTrXDR":
            let value = try OperationResultXDRTrXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "OperationType":
            let value = try OperationType.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "OperationXDR":
            let value = try OperationXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ParallelTxExecutionStageXDR":
            let value = try ParallelTxExecutionStageXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ParallelTxsComponentXDR":
            let value = try ParallelTxsComponentXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "PathPaymentResultXDRSuccessXDR":
            let value = try PathPaymentResultXDRSuccessXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "PaymentOperationXDR":
            let value = try PaymentOperationXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "PaymentResultCode":
            let value = try PaymentResultCode.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "PaymentResultXDR":
            let value = try PaymentResultXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "PeerAddressXDR":
            let value = try PeerAddressXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "PeerAddressXDRIpXDR":
            let value = try PeerAddressXDRIpXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "PeerStatsXDR":
            let value = try PeerStatsXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "PersistedSCPStateV0XDR":
            let value = try PersistedSCPStateV0XDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "PersistedSCPStateV1XDR":
            let value = try PersistedSCPStateV1XDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "PersistedSCPStateXDR":
            let value = try PersistedSCPStateXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "PoolIDXDR":
            let value = try PoolIDXDRJsonCodec.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "PreconditionType":
            let value = try PreconditionType.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "PreconditionsV2XDR":
            let value = try PreconditionsV2XDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "PreconditionsXDR":
            let value = try PreconditionsXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "PriceXDR":
            let value = try PriceXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "PublicKey":
            let value = try PublicKey.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "PublicKeyTypeXDR":
            let value = try PublicKeyTypeXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "RestoreFootprintOpXDR":
            let value = try RestoreFootprintOpXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "RestoreFootprintResultCode":
            let value = try RestoreFootprintResultCode.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "RestoreFootprintResultXDR":
            let value = try RestoreFootprintResultXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "RevokeID":
            let value = try RevokeID.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "RevokeSponsorshipOpXDR":
            let value = try RevokeSponsorshipOpXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "RevokeSponsorshipResultCode":
            let value = try RevokeSponsorshipResultCode.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "RevokeSponsorshipResultXDR":
            let value = try RevokeSponsorshipResultXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "RevokeSponsorshipSignerXDR":
            let value = try RevokeSponsorshipSignerXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "RevokeSponsorshipType":
            let value = try RevokeSponsorshipType.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SCAddressType":
            let value = try SCAddressType.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SCAddressXDR":
            let value = try SCAddressXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SCBytesXDR":
            let value = try SCBytesXDRJsonCodec.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SCContractInstanceXDR":
            let value = try SCContractInstanceXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SCEnvMetaEntryXDR":
            let value = try SCEnvMetaEntryXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SCEnvMetaEntryXDRInterfaceVersionXDR":
            let value = try SCEnvMetaEntryXDRInterfaceVersionXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SCEnvMetaKind":
            let value = try SCEnvMetaKind.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SCErrorCode":
            let value = try SCErrorCode.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SCErrorType":
            let value = try SCErrorType.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SCErrorXDR":
            let value = try SCErrorXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SCMapEntryXDR":
            let value = try SCMapEntryXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SCMapXDR":
            let value = try SCMapXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SCMetaEntryXDR":
            let value = try SCMetaEntryXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SCMetaKind":
            let value = try SCMetaKind.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SCMetaV0XDR":
            let value = try SCMetaV0XDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SCNonceKeyXDR":
            let value = try SCNonceKeyXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SCPBallotXDR":
            let value = try SCPBallotXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SCPEnvelopeXDR":
            let value = try SCPEnvelopeXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SCPHistoryEntryV0XDR":
            let value = try SCPHistoryEntryV0XDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SCPHistoryEntryXDR":
            let value = try SCPHistoryEntryXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SCPNominationXDR":
            let value = try SCPNominationXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SCPQuorumSetXDR":
            let value = try SCPQuorumSetXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SCPStatementTypeXDR":
            let value = try SCPStatementTypeXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SCPStatementXDR":
            let value = try SCPStatementXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SCPStatementXDRConfirmXDR":
            let value = try SCPStatementXDRConfirmXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SCPStatementXDRExternalizeXDR":
            let value = try SCPStatementXDRExternalizeXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SCPStatementXDRPledgesXDR":
            let value = try SCPStatementXDRPledgesXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SCPStatementXDRPrepareXDR":
            let value = try SCPStatementXDRPrepareXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SCSpecEntryKind":
            let value = try SCSpecEntryKind.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SCSpecEntryXDR":
            let value = try SCSpecEntryXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SCSpecEventDataFormat":
            let value = try SCSpecEventDataFormat.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SCSpecEventParamLocationV0":
            let value = try SCSpecEventParamLocationV0.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SCSpecEventParamV0XDR":
            let value = try SCSpecEventParamV0XDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SCSpecEventV0XDR":
            let value = try SCSpecEventV0XDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SCSpecFunctionInputV0XDR":
            let value = try SCSpecFunctionInputV0XDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SCSpecFunctionV0XDR":
            let value = try SCSpecFunctionV0XDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SCSpecType":
            let value = try SCSpecType.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SCSpecTypeBytesNXDR":
            let value = try SCSpecTypeBytesNXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SCSpecTypeDefXDR":
            let value = try SCSpecTypeDefXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SCSpecTypeMapXDR":
            let value = try SCSpecTypeMapXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SCSpecTypeOptionXDR":
            let value = try SCSpecTypeOptionXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SCSpecTypeResultXDR":
            let value = try SCSpecTypeResultXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SCSpecTypeTupleXDR":
            let value = try SCSpecTypeTupleXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SCSpecTypeUDTXDR":
            let value = try SCSpecTypeUDTXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SCSpecTypeVecXDR":
            let value = try SCSpecTypeVecXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SCSpecUDTEnumCaseV0XDR":
            let value = try SCSpecUDTEnumCaseV0XDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SCSpecUDTEnumV0XDR":
            let value = try SCSpecUDTEnumV0XDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SCSpecUDTErrorEnumCaseV0XDR":
            let value = try SCSpecUDTErrorEnumCaseV0XDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SCSpecUDTErrorEnumV0XDR":
            let value = try SCSpecUDTErrorEnumV0XDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SCSpecUDTStructFieldV0XDR":
            let value = try SCSpecUDTStructFieldV0XDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SCSpecUDTStructV0XDR":
            let value = try SCSpecUDTStructV0XDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SCSpecUDTUnionCaseTupleV0XDR":
            let value = try SCSpecUDTUnionCaseTupleV0XDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SCSpecUDTUnionCaseV0Kind":
            let value = try SCSpecUDTUnionCaseV0Kind.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SCSpecUDTUnionCaseV0XDR":
            let value = try SCSpecUDTUnionCaseV0XDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SCSpecUDTUnionCaseVoidV0XDR":
            let value = try SCSpecUDTUnionCaseVoidV0XDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SCSpecUDTUnionV0XDR":
            let value = try SCSpecUDTUnionV0XDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SCStringXDR":
            let value = try SCStringXDRJsonCodec.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SCSymbolXDR":
            let value = try SCSymbolXDRJsonCodec.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SCValType":
            let value = try SCValType.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SCValXDR":
            let value = try SCValXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SCVecXDR":
            let value = try SCVecXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SendMoreExtendedXDR":
            let value = try SendMoreExtendedXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SendMoreXDR":
            let value = try SendMoreXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SequenceNumberXDR":
            let value = try SequenceNumberXDRJsonCodec.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SerializedBinaryFuseFilterXDR":
            let value = try SerializedBinaryFuseFilterXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SetOptionsOperationXDR":
            let value = try SetOptionsOperationXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SetOptionsResultCode":
            let value = try SetOptionsResultCode.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SetOptionsResultXDR":
            let value = try SetOptionsResultXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SetTrustLineFlagsOpXDR":
            let value = try SetTrustLineFlagsOpXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SetTrustLineFlagsResultCode":
            let value = try SetTrustLineFlagsResultCode.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SetTrustLineFlagsResultXDR":
            let value = try SetTrustLineFlagsResultXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ShortHashSeedXDR":
            let value = try ShortHashSeedXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SignatureHintXDR":
            let value = try SignatureHintXDRJsonCodec.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SignatureXDR":
            let value = try SignatureXDRJsonCodec.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SignedTimeSlicedSurveyRequestMessageXDR":
            let value = try SignedTimeSlicedSurveyRequestMessageXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SignedTimeSlicedSurveyResponseMessageXDR":
            let value = try SignedTimeSlicedSurveyResponseMessageXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SignedTimeSlicedSurveyStartCollectingMessageXDR":
            let value = try SignedTimeSlicedSurveyStartCollectingMessageXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SignedTimeSlicedSurveyStopCollectingMessageXDR":
            let value = try SignedTimeSlicedSurveyStopCollectingMessageXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SignerKeyType":
            let value = try SignerKeyType.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SignerKeyXDR":
            let value = try SignerKeyXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SignerXDR":
            let value = try SignerXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SimplePaymentResultXDR":
            let value = try SimplePaymentResultXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SorobanAddressCredentialsWithDelegatesXDR":
            let value = try SorobanAddressCredentialsWithDelegatesXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SorobanAddressCredentialsXDR":
            let value = try SorobanAddressCredentialsXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SorobanAuthorizationEntriesXDR":
            let value = try SorobanAuthorizationEntriesXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SorobanAuthorizationEntryXDR":
            let value = try SorobanAuthorizationEntryXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SorobanAuthorizedFunctionType":
            let value = try SorobanAuthorizedFunctionType.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SorobanAuthorizedFunctionXDR":
            let value = try SorobanAuthorizedFunctionXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SorobanAuthorizedInvocationXDR":
            let value = try SorobanAuthorizedInvocationXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SorobanCredentialsType":
            let value = try SorobanCredentialsType.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SorobanCredentialsXDR":
            let value = try SorobanCredentialsXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SorobanDelegateSignatureXDR":
            let value = try SorobanDelegateSignatureXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SorobanResourcesExt":
            let value = try SorobanResourcesExt.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SorobanResourcesExtV0":
            let value = try SorobanResourcesExtV0.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SorobanResourcesXDR":
            let value = try SorobanResourcesXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SorobanTransactionDataXDR":
            let value = try SorobanTransactionDataXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SorobanTransactionMetaExt":
            let value = try SorobanTransactionMetaExt.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SorobanTransactionMetaExtV1":
            let value = try SorobanTransactionMetaExtV1.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SorobanTransactionMetaV2XDR":
            let value = try SorobanTransactionMetaV2XDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SorobanTransactionMetaXDR":
            let value = try SorobanTransactionMetaXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "StateArchivalSettingsXDR":
            let value = try StateArchivalSettingsXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "StellarMessageXDR":
            let value = try StellarMessageXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "StellarValueTypeXDR":
            let value = try StellarValueTypeXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "StellarValueXDR":
            let value = try StellarValueXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "StellarValueXDRExtXDR":
            let value = try StellarValueXDRExtXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "StellarValueXDRProposedValueXDR":
            let value = try StellarValueXDRProposedValueXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "StoredDebugTransactionSetXDR":
            let value = try StoredDebugTransactionSetXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "StoredTransactionSetXDR":
            let value = try StoredTransactionSetXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "String32XDR":
            let value = try String32XDRJsonCodec.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "String64XDR":
            let value = try String64XDRJsonCodec.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SurveyMessageCommandTypeXDR":
            let value = try SurveyMessageCommandTypeXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SurveyMessageResponseTypeXDR":
            let value = try SurveyMessageResponseTypeXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SurveyRequestMessageXDR":
            let value = try SurveyRequestMessageXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SurveyResponseBodyXDR":
            let value = try SurveyResponseBodyXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "SurveyResponseMessageXDR":
            let value = try SurveyResponseMessageXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "TTLEntryXDR":
            let value = try TTLEntryXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ThresholdIndexesXDR":
            let value = try ThresholdIndexesXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ThresholdsXDR":
            let value = try ThresholdsXDRJsonCodec.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "TimeBoundsXDR":
            let value = try TimeBoundsXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "TimePointXDR":
            let value = try TimePointXDRJsonCodec.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "TimeSlicedNodeDataXDR":
            let value = try TimeSlicedNodeDataXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "TimeSlicedPeerDataListXDR":
            let value = try TimeSlicedPeerDataListXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "TimeSlicedPeerDataXDR":
            let value = try TimeSlicedPeerDataXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "TimeSlicedSurveyRequestMessageXDR":
            let value = try TimeSlicedSurveyRequestMessageXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "TimeSlicedSurveyResponseMessageXDR":
            let value = try TimeSlicedSurveyResponseMessageXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "TimeSlicedSurveyStartCollectingMessageXDR":
            let value = try TimeSlicedSurveyStartCollectingMessageXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "TimeSlicedSurveyStopCollectingMessageXDR":
            let value = try TimeSlicedSurveyStopCollectingMessageXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "TopologyResponseBodyV2XDR":
            let value = try TopologyResponseBodyV2XDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "TransactionEnvelopeXDR":
            let value = try TransactionEnvelopeXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "TransactionEventStage":
            let value = try TransactionEventStage.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "TransactionEventXDR":
            let value = try TransactionEventXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "TransactionExtXDR":
            let value = try TransactionExtXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "TransactionHistoryEntryXDR":
            let value = try TransactionHistoryEntryXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "TransactionHistoryEntryXDRExtXDR":
            let value = try TransactionHistoryEntryXDRExtXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "TransactionHistoryResultEntryXDR":
            let value = try TransactionHistoryResultEntryXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "TransactionHistoryResultEntryXDRExtXDR":
            let value = try TransactionHistoryResultEntryXDRExtXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "TransactionMetaV1XDR":
            let value = try TransactionMetaV1XDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "TransactionMetaV2XDR":
            let value = try TransactionMetaV2XDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "TransactionMetaV3XDR":
            let value = try TransactionMetaV3XDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "TransactionMetaV4XDR":
            let value = try TransactionMetaV4XDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "TransactionMetaXDR":
            let value = try TransactionMetaXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "TransactionPhaseXDR":
            let value = try TransactionPhaseXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "TransactionResultBodyXDR":
            let value = try TransactionResultBodyXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "TransactionResultCode":
            let value = try TransactionResultCode.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "TransactionResultMetaV1XDR":
            let value = try TransactionResultMetaV1XDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "TransactionResultMetaXDR":
            let value = try TransactionResultMetaXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "TransactionResultPairXDR":
            let value = try TransactionResultPairXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "TransactionResultSetXDR":
            let value = try TransactionResultSetXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "TransactionResultXDR":
            let value = try TransactionResultXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "TransactionResultXDRExtXDR":
            let value = try TransactionResultXDRExtXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "TransactionSetV1XDR":
            let value = try TransactionSetV1XDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "TransactionSetXDR":
            let value = try TransactionSetXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "TransactionSignaturePayload":
            let value = try TransactionSignaturePayload.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "TransactionSignaturePayloadTaggedTransactionXDR":
            let value = try TransactionSignaturePayloadTaggedTransactionXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "TransactionV0EnvelopeXDR":
            let value = try TransactionV0EnvelopeXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "TransactionV0XDR":
            let value = try TransactionV0XDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "TransactionV0XDRExtXDR":
            let value = try TransactionV0XDRExtXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "TransactionV1EnvelopeXDR":
            let value = try TransactionV1EnvelopeXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "TransactionXDR":
            let value = try TransactionXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "TrustLineFlags":
            let value = try TrustLineFlags.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "TrustlineAssetXDR":
            let value = try TrustlineAssetXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "TrustlineEntryExtV1XDR":
            let value = try TrustlineEntryExtV1XDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "TrustlineEntryExtXDR":
            let value = try TrustlineEntryExtXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "TrustlineEntryExtensionV1":
            let value = try TrustlineEntryExtensionV1.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "TrustlineEntryExtensionV2":
            let value = try TrustlineEntryExtensionV2.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "TrustlineEntryExtensionV2ExtXDR":
            let value = try TrustlineEntryExtensionV2ExtXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "TrustlineEntryXDR":
            let value = try TrustlineEntryXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "TxAdvertVectorXDR":
            let value = try TxAdvertVectorXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "TxDemandVectorXDR":
            let value = try TxDemandVectorXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "TxSetComponentTypeXDR":
            let value = try TxSetComponentTypeXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "TxSetComponentXDR":
            let value = try TxSetComponentXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "TxSetComponentXDRTxsMaybeDiscountedFeeXDR":
            let value = try TxSetComponentXDRTxsMaybeDiscountedFeeXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "UInt128PartsXDR":
            let value = try UInt128PartsXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "UInt256PartsXDR":
            let value = try UInt256PartsXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "Uint256XDR":
            let value = try Uint256XDRJsonCodec.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "Uint32XDR":
            let value = try Uint32XDRJsonCodec.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "Uint64XDR":
            let value = try Uint64XDRJsonCodec.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "UpgradeEntryMetaXDR":
            let value = try UpgradeEntryMetaXDR.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "UpgradeTypeXDR":
            let value = try UpgradeTypeXDRJsonCodec.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        case "ValueXDR":
            let value = try ValueXDRJsonCodec.fromXdrJson(json)
            return try Data(XDREncoder.encode(value)).base64EncodedString()
        default:
            throw Sep51CorpusDispatchError.unknownType(iosType)
        }
    }

    /// Every type name the two switches above handle.
    static let dispatchedTypes: Set<String> = [
        "AccountEntryExtV1XDR",
        "AccountEntryExtV2XDR",
        "AccountEntryExtXDR",
        "AccountEntryExtensionV1",
        "AccountEntryExtensionV2",
        "AccountEntryExtensionV3",
        "AccountEntryXDR",
        "AccountFlags",
        "AccountIDXDR",
        "AccountMergeResultCode",
        "AccountMergeResultXDR",
        "AllowTrustOpAssetXDR",
        "AllowTrustOperationXDR",
        "AllowTrustResultCode",
        "AllowTrustResultXDR",
        "Alpha12XDR",
        "Alpha4XDR",
        "AssetCode12XDR",
        "AssetCode4XDR",
        "AssetType",
        "AssetXDR",
        "AuthCertXDR",
        "AuthXDR",
        "AuthenticatedMessageXDR",
        "AuthenticatedMessageXDRV0XDR",
        "BeginSponsoringFutureReservesOpXDR",
        "BeginSponsoringFutureReservesResultCode",
        "BeginSponsoringFutureReservesResultXDR",
        "BinaryFuseFilterTypeXDR",
        "BucketEntryTypeXDR",
        "BucketEntryXDR",
        "BucketListTypeXDR",
        "BucketMetadataXDR",
        "BucketMetadataXDRExtXDR",
        "BumpSequenceOperationXDR",
        "BumpSequenceResultCode",
        "BumpSequenceResultXDR",
        "ChangeTrustAssetXDR",
        "ChangeTrustOperationXDR",
        "ChangeTrustResultCode",
        "ChangeTrustResultXDR",
        "ClaimAtomType",
        "ClaimAtomXDR",
        "ClaimClaimableBalanceOpXDR",
        "ClaimClaimableBalanceResultCode",
        "ClaimClaimableBalanceResultXDR",
        "ClaimLiquidityAtomXDR",
        "ClaimOfferAtomV0XDR",
        "ClaimOfferAtomXDR",
        "ClaimPredicateType",
        "ClaimPredicateXDR",
        "ClaimableBalanceEntryExtXDR",
        "ClaimableBalanceEntryExtensionV1",
        "ClaimableBalanceEntryExtensionV1ExtXDR",
        "ClaimableBalanceEntryXDR",
        "ClaimableBalanceFlags",
        "ClaimableBalanceIDType",
        "ClaimableBalanceIDXDR",
        "ClaimantType",
        "ClaimantV0XDR",
        "ClaimantXDR",
        "ClawbackClaimableBalanceOpXDR",
        "ClawbackClaimableBalanceResultCode",
        "ClawbackClaimableBalanceResultXDR",
        "ClawbackOpXDR",
        "ClawbackResultCode",
        "ClawbackResultXDR",
        "ConfigSettingContractBandwidthV0XDR",
        "ConfigSettingContractComputeV0XDR",
        "ConfigSettingContractEventsV0XDR",
        "ConfigSettingContractExecutionLanesV0XDR",
        "ConfigSettingContractHistoricalDataV0XDR",
        "ConfigSettingContractLedgerCostExtV0",
        "ConfigSettingContractLedgerCostV0XDR",
        "ConfigSettingContractParallelComputeV0",
        "ConfigSettingEntryXDR",
        "ConfigSettingID",
        "ConfigSettingSCPTiming",
        "ConfigUpgradeSetKeyXDR",
        "ConfigUpgradeSetXDR",
        "ConstantProductXDR",
        "ContractCodeCostInputsXDR",
        "ContractCodeEntryExt",
        "ContractCodeEntryExtV1",
        "ContractCodeEntryXDR",
        "ContractCostParamEntryXDR",
        "ContractCostParamsXDR",
        "ContractCostType",
        "ContractDataDurability",
        "ContractDataEntryXDR",
        "ContractEventBodyV0XDR",
        "ContractEventBodyXDR",
        "ContractEventType",
        "ContractEventXDR",
        "ContractExecutableExternalRefXDR",
        "ContractExecutableType",
        "ContractExecutableXDR",
        "ContractIDPreimageFromAddressXDR",
        "ContractIDPreimageType",
        "ContractIDPreimageXDR",
        "ContractIDXDR",
        "CreateAccountOperationXDR",
        "CreateAccountResultCode",
        "CreateAccountResultXDR",
        "CreateClaimableBalanceOpXDR",
        "CreateClaimableBalanceResultCode",
        "CreateClaimableBalanceResultXDR",
        "CreateContractArgsXDR",
        "CreateContractV2ArgsXDR",
        "CreatePassiveOfferOperationXDR",
        "CryptoKeyType",
        "Curve25519PublicXDR",
        "Curve25519SecretXDR",
        "DataEntryXDR",
        "DataEntryXDRExtXDR",
        "DataValueXDR",
        "DecoratedSignatureXDR",
        "DependentTxClusterXDR",
        "DiagnosticEventXDR",
        "DontHaveXDR",
        "DurationXDR",
        "Ed25519SignedPayload",
        "EncodedLedgerKeyXDR",
        "EncryptedBodyXDR",
        "EndSponsoringFutureReservesResultCode",
        "EndSponsoringFutureReservesResultXDR",
        "EnvelopeType",
        "ErrorCodeXDR",
        "ErrorXDR",
        "EvictionIteratorXDR",
        "ExtendFootprintTTLOpXDR",
        "ExtendFootprintTTLResultCode",
        "ExtendFootprintTTLResultXDR",
        "ExtensionPoint",
        "FeeBumpTransactionEnvelopeXDR",
        "FeeBumpTransactionXDR",
        "FeeBumpTransactionXDRExtXDR",
        "FeeBumpTransactionXDRInnerTxXDR",
        "FloodAdvertXDR",
        "FloodDemandXDR",
        "FreezeBypassTxsDeltaXDR",
        "FreezeBypassTxsXDR",
        "FrozenLedgerKeysDeltaXDR",
        "FrozenLedgerKeysXDR",
        "GeneralizedTransactionSetXDR",
        "HashIDPreimageContractIDXDR",
        "HashIDPreimageSorobanAuthorizationWithAddressXDR",
        "HashIDPreimageSorobanAuthorizationXDR",
        "HashIDPreimageXDR",
        "HashXDR",
        "HelloXDR",
        "HmacSha256KeyXDR",
        "HmacSha256MacXDR",
        "HostFunctionType",
        "HostFunctionXDR",
        "HotArchiveBucketEntryTypeXDR",
        "HotArchiveBucketEntryXDR",
        "IPAddrTypeXDR",
        "InflationPayoutXDR",
        "InflationResultCode",
        "InflationResultXDR",
        "InnerTransactionResultBodyXDR",
        "InnerTransactionResultPair",
        "InnerTransactionResultXDR",
        "InnerTransactionResultXDRExtXDR",
        "Int128PartsXDR",
        "Int256PartsXDR",
        "Int32XDR",
        "Int64XDR",
        "InvokeContractArgsXDR",
        "InvokeHostFunctionOpXDR",
        "InvokeHostFunctionResultCode",
        "InvokeHostFunctionResultXDR",
        "InvokeHostFunctionSuccessPreImageXDR",
        "LedgerBoundsXDR",
        "LedgerCloseMetaBatchXDR",
        "LedgerCloseMetaExtV1XDR",
        "LedgerCloseMetaExtXDR",
        "LedgerCloseMetaV0XDR",
        "LedgerCloseMetaV1XDR",
        "LedgerCloseMetaV2XDR",
        "LedgerCloseMetaXDR",
        "LedgerCloseValueSignatureXDR",
        "LedgerEntryChangeType",
        "LedgerEntryChangeXDR",
        "LedgerEntryChangesXDR",
        "LedgerEntryDataXDR",
        "LedgerEntryExtXDR",
        "LedgerEntryExtensionV1",
        "LedgerEntryExtensionV1ExtXDR",
        "LedgerEntryType",
        "LedgerEntryXDR",
        "LedgerFootprintXDR",
        "LedgerHeaderExtensionV1XDR",
        "LedgerHeaderExtensionV1XDRExtXDR",
        "LedgerHeaderFlagsXDR",
        "LedgerHeaderHistoryEntryXDR",
        "LedgerHeaderHistoryEntryXDRExtXDR",
        "LedgerHeaderXDR",
        "LedgerHeaderXDRExtXDR",
        "LedgerKeyAccountXDR",
        "LedgerKeyClaimableBalanceXDR",
        "LedgerKeyConfigSettingXDR",
        "LedgerKeyContractCodeXDR",
        "LedgerKeyContractDataXDR",
        "LedgerKeyDataXDR",
        "LedgerKeyLiquidityPoolXDR",
        "LedgerKeyOfferXDR",
        "LedgerKeyTTLXDR",
        "LedgerKeyTrustLineXDR",
        "LedgerKeyXDR",
        "LedgerSCPMessagesXDR",
        "LedgerUpgradeTypeXDR",
        "LedgerUpgradeXDR",
        "LiabilitiesXDR",
        "LiquidityPoolBodyXDR",
        "LiquidityPoolConstantProductParametersXDR",
        "LiquidityPoolDepositOpXDR",
        "LiquidityPoolDepositResulCode",
        "LiquidityPoolDepositResultXDR",
        "LiquidityPoolEntryXDR",
        "LiquidityPoolParametersXDR",
        "LiquidityPoolType",
        "LiquidityPoolWithdrawOpXDR",
        "LiquidityPoolWithdrawResulCode",
        "LiquidityPoolWithdrawResultXDR",
        "ManageDataOperationXDR",
        "ManageDataResultCode",
        "ManageDataResultXDR",
        "ManageOfferEffect",
        "ManageOfferResultCode",
        "ManageOfferResultXDR",
        "ManageOfferSuccessResultOfferXDR",
        "ManageOfferSuccessResultXDR",
        "MemoType",
        "MemoXDR",
        "MessageTypeXDR",
        "MuxedAccountMed25519XDR",
        "MuxedAccountXDR",
        "MuxedAccountXDRMed25519XDR",
        "NodeIDXDR",
        "OfferEntryFlagsXDR",
        "OfferEntryXDR",
        "OfferEntryXDRExtXDR",
        "OperationBodyXDR",
        "OperationID",
        "OperationMetaV2XDR",
        "OperationMetaXDR",
        "OperationResultCode",
        "OperationResultXDR",
        "OperationResultXDRTrXDR",
        "OperationType",
        "OperationXDR",
        "ParallelTxExecutionStageXDR",
        "ParallelTxsComponentXDR",
        "PathPaymentResultXDRSuccessXDR",
        "PaymentOperationXDR",
        "PaymentResultCode",
        "PaymentResultXDR",
        "PeerAddressXDR",
        "PeerAddressXDRIpXDR",
        "PeerStatsXDR",
        "PersistedSCPStateV0XDR",
        "PersistedSCPStateV1XDR",
        "PersistedSCPStateXDR",
        "PoolIDXDR",
        "PreconditionType",
        "PreconditionsV2XDR",
        "PreconditionsXDR",
        "PriceXDR",
        "PublicKey",
        "PublicKeyTypeXDR",
        "RestoreFootprintOpXDR",
        "RestoreFootprintResultCode",
        "RestoreFootprintResultXDR",
        "RevokeID",
        "RevokeSponsorshipOpXDR",
        "RevokeSponsorshipResultCode",
        "RevokeSponsorshipResultXDR",
        "RevokeSponsorshipSignerXDR",
        "RevokeSponsorshipType",
        "SCAddressType",
        "SCAddressXDR",
        "SCBytesXDR",
        "SCContractInstanceXDR",
        "SCEnvMetaEntryXDR",
        "SCEnvMetaEntryXDRInterfaceVersionXDR",
        "SCEnvMetaKind",
        "SCErrorCode",
        "SCErrorType",
        "SCErrorXDR",
        "SCMapEntryXDR",
        "SCMapXDR",
        "SCMetaEntryXDR",
        "SCMetaKind",
        "SCMetaV0XDR",
        "SCNonceKeyXDR",
        "SCPBallotXDR",
        "SCPEnvelopeXDR",
        "SCPHistoryEntryV0XDR",
        "SCPHistoryEntryXDR",
        "SCPNominationXDR",
        "SCPQuorumSetXDR",
        "SCPStatementTypeXDR",
        "SCPStatementXDR",
        "SCPStatementXDRConfirmXDR",
        "SCPStatementXDRExternalizeXDR",
        "SCPStatementXDRPledgesXDR",
        "SCPStatementXDRPrepareXDR",
        "SCSpecEntryKind",
        "SCSpecEntryXDR",
        "SCSpecEventDataFormat",
        "SCSpecEventParamLocationV0",
        "SCSpecEventParamV0XDR",
        "SCSpecEventV0XDR",
        "SCSpecFunctionInputV0XDR",
        "SCSpecFunctionV0XDR",
        "SCSpecType",
        "SCSpecTypeBytesNXDR",
        "SCSpecTypeDefXDR",
        "SCSpecTypeMapXDR",
        "SCSpecTypeOptionXDR",
        "SCSpecTypeResultXDR",
        "SCSpecTypeTupleXDR",
        "SCSpecTypeUDTXDR",
        "SCSpecTypeVecXDR",
        "SCSpecUDTEnumCaseV0XDR",
        "SCSpecUDTEnumV0XDR",
        "SCSpecUDTErrorEnumCaseV0XDR",
        "SCSpecUDTErrorEnumV0XDR",
        "SCSpecUDTStructFieldV0XDR",
        "SCSpecUDTStructV0XDR",
        "SCSpecUDTUnionCaseTupleV0XDR",
        "SCSpecUDTUnionCaseV0Kind",
        "SCSpecUDTUnionCaseV0XDR",
        "SCSpecUDTUnionCaseVoidV0XDR",
        "SCSpecUDTUnionV0XDR",
        "SCStringXDR",
        "SCSymbolXDR",
        "SCValType",
        "SCValXDR",
        "SCVecXDR",
        "SendMoreExtendedXDR",
        "SendMoreXDR",
        "SequenceNumberXDR",
        "SerializedBinaryFuseFilterXDR",
        "SetOptionsOperationXDR",
        "SetOptionsResultCode",
        "SetOptionsResultXDR",
        "SetTrustLineFlagsOpXDR",
        "SetTrustLineFlagsResultCode",
        "SetTrustLineFlagsResultXDR",
        "ShortHashSeedXDR",
        "SignatureHintXDR",
        "SignatureXDR",
        "SignedTimeSlicedSurveyRequestMessageXDR",
        "SignedTimeSlicedSurveyResponseMessageXDR",
        "SignedTimeSlicedSurveyStartCollectingMessageXDR",
        "SignedTimeSlicedSurveyStopCollectingMessageXDR",
        "SignerKeyType",
        "SignerKeyXDR",
        "SignerXDR",
        "SimplePaymentResultXDR",
        "SorobanAddressCredentialsWithDelegatesXDR",
        "SorobanAddressCredentialsXDR",
        "SorobanAuthorizationEntriesXDR",
        "SorobanAuthorizationEntryXDR",
        "SorobanAuthorizedFunctionType",
        "SorobanAuthorizedFunctionXDR",
        "SorobanAuthorizedInvocationXDR",
        "SorobanCredentialsType",
        "SorobanCredentialsXDR",
        "SorobanDelegateSignatureXDR",
        "SorobanResourcesExt",
        "SorobanResourcesExtV0",
        "SorobanResourcesXDR",
        "SorobanTransactionDataXDR",
        "SorobanTransactionMetaExt",
        "SorobanTransactionMetaExtV1",
        "SorobanTransactionMetaV2XDR",
        "SorobanTransactionMetaXDR",
        "StateArchivalSettingsXDR",
        "StellarMessageXDR",
        "StellarValueTypeXDR",
        "StellarValueXDR",
        "StellarValueXDRExtXDR",
        "StellarValueXDRProposedValueXDR",
        "StoredDebugTransactionSetXDR",
        "StoredTransactionSetXDR",
        "String32XDR",
        "String64XDR",
        "SurveyMessageCommandTypeXDR",
        "SurveyMessageResponseTypeXDR",
        "SurveyRequestMessageXDR",
        "SurveyResponseBodyXDR",
        "SurveyResponseMessageXDR",
        "TTLEntryXDR",
        "ThresholdIndexesXDR",
        "ThresholdsXDR",
        "TimeBoundsXDR",
        "TimePointXDR",
        "TimeSlicedNodeDataXDR",
        "TimeSlicedPeerDataListXDR",
        "TimeSlicedPeerDataXDR",
        "TimeSlicedSurveyRequestMessageXDR",
        "TimeSlicedSurveyResponseMessageXDR",
        "TimeSlicedSurveyStartCollectingMessageXDR",
        "TimeSlicedSurveyStopCollectingMessageXDR",
        "TopologyResponseBodyV2XDR",
        "TransactionEnvelopeXDR",
        "TransactionEventStage",
        "TransactionEventXDR",
        "TransactionExtXDR",
        "TransactionHistoryEntryXDR",
        "TransactionHistoryEntryXDRExtXDR",
        "TransactionHistoryResultEntryXDR",
        "TransactionHistoryResultEntryXDRExtXDR",
        "TransactionMetaV1XDR",
        "TransactionMetaV2XDR",
        "TransactionMetaV3XDR",
        "TransactionMetaV4XDR",
        "TransactionMetaXDR",
        "TransactionPhaseXDR",
        "TransactionResultBodyXDR",
        "TransactionResultCode",
        "TransactionResultMetaV1XDR",
        "TransactionResultMetaXDR",
        "TransactionResultPairXDR",
        "TransactionResultSetXDR",
        "TransactionResultXDR",
        "TransactionResultXDRExtXDR",
        "TransactionSetV1XDR",
        "TransactionSetXDR",
        "TransactionSignaturePayload",
        "TransactionSignaturePayloadTaggedTransactionXDR",
        "TransactionV0EnvelopeXDR",
        "TransactionV0XDR",
        "TransactionV0XDRExtXDR",
        "TransactionV1EnvelopeXDR",
        "TransactionXDR",
        "TrustLineFlags",
        "TrustlineAssetXDR",
        "TrustlineEntryExtV1XDR",
        "TrustlineEntryExtXDR",
        "TrustlineEntryExtensionV1",
        "TrustlineEntryExtensionV2",
        "TrustlineEntryExtensionV2ExtXDR",
        "TrustlineEntryXDR",
        "TxAdvertVectorXDR",
        "TxDemandVectorXDR",
        "TxSetComponentTypeXDR",
        "TxSetComponentXDR",
        "TxSetComponentXDRTxsMaybeDiscountedFeeXDR",
        "UInt128PartsXDR",
        "UInt256PartsXDR",
        "Uint256XDR",
        "Uint32XDR",
        "Uint64XDR",
        "UpgradeEntryMetaXDR",
        "UpgradeTypeXDR",
        "ValueXDR",
    ]
}
