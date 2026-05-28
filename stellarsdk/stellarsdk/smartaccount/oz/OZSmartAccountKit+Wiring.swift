//
//  OZSmartAccountKit+Wiring.swift
//  stellarsdk
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import Foundation

// ============================================================================
// MARK: - OZContextRuleManager + OZContextRuleParser
// ============================================================================

// Adapter for label-shape mismatch between OZContextRuleParser and OZContextRuleManager. Forwards only; no behaviour.
extension OZContextRuleManager: OZContextRuleParser {

    internal func getContextRule(contextRuleId: UInt32) async throws -> SCValXDR {
        return try await self.getContextRule(id: contextRuleId)
    }

    internal func parseContextRule(_ scVal: SCValXDR) throws -> ParsedContextRule {
        return try self.parseContextRule(scVal: scVal)
    }
}
