// Backward-compatible static constants for EnvelopeType.
// Previously EnvelopeType was a struct-with-constants; now it is an auto-generated enum.
// These constants allow existing code that uses EnvelopeType.ENVELOPE_TYPE_TX etc. to compile.

import Foundation

extension EnvelopeType {
    public static let ENVELOPE_TYPE_TX_V0: Int32 = EnvelopeType.txV0.rawValue
    public static let ENVELOPE_TYPE_SCP: Int32 = EnvelopeType.scp.rawValue
    public static let ENVELOPE_TYPE_TX: Int32 = EnvelopeType.tx.rawValue
    public static let ENVELOPE_TYPE_AUTH: Int32 = EnvelopeType.auth.rawValue
    public static let ENVELOPE_TYPE_SCPVALUE: Int32 = EnvelopeType.scpvalue.rawValue
    public static let ENVELOPE_TYPE_TX_FEE_BUMP: Int32 = EnvelopeType.txFeeBump.rawValue
    public static let ENVELOPE_TYPE_OP_ID: Int32 = EnvelopeType.opId.rawValue
    public static let ENVELOPE_TYPE_POOL_REVOKE_OP_ID: Int32 = EnvelopeType.poolRevokeOpId.rawValue
    public static let ENVELOPE_TYPE_CONTRACT_ID: Int32 = EnvelopeType.contractId.rawValue
    public static let ENVELOPE_TYPE_SOROBAN_AUTHORIZATION: Int32 = EnvelopeType.sorobanAuthorization.rawValue
}
