import Foundation

public struct LiquidityPoolIDXDR: XDRCodable, Sendable {
    public let liquidityPoolID: WrappedData32

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        liquidityPoolID = try container.decode(WrappedData32.self)
    }

    public init(liquidityPoolID: WrappedData32) {
        self.liquidityPoolID = liquidityPoolID
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(liquidityPoolID)
    }
}
