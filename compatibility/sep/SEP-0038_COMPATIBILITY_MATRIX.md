# SEP-0038 (Anchor RFQ API) Compatibility Matrix

**Generated:** 2025-10-16

**SEP Version:** 2.5.0
**SEP Status:** Draft
**SEP URL:** https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0038.md

## SEP Summary

This protocol enables anchors to accept off-chain assets in exchange for different on-chain assets, and vice versa.

Specifically, it enables anchors to provide quotes that can be referenced within the context of existing Stellar Ecosystem Proposals.

How the exchange of assets is facilitated is outside the scope of this document.

## Overall Coverage

**Total Coverage:** 100.0% (58/58 fields)

- ✅ **Implemented:** 58/58
- ❌ **Not Implemented:** 0/58

**Required Fields:** 100.0% (39/39)

**Optional Fields:** 100.0% (19/19)

## Implementation Status

✅ **Implemented**

### Implementation Files

- `stellarsdk/stellarsdk/quote/QuoteService.swift`
- `stellarsdk/stellarsdk/quote/request/Sep38PostQuoteRequest.swift`
- `stellarsdk/stellarsdk/quote/responses/Sep38Responses.swift`

### Key Classes

- No key classes documented

## Coverage by Section

| Section | Coverage | Required Coverage | Implemented | Total |
|---------|----------|-------------------|-------------|-------|
| Info Endpoint | 100.0% | 100.0% | 1 | 1 |
| Info Response Fields | 100.0% | 100.0% | 1 | 1 |
| Asset Fields | 100.0% | 100.0% | 4 | 4 |
| Delivery Method Fields | 100.0% | 100.0% | 2 | 2 |
| Prices Endpoint | 100.0% | 100.0% | 1 | 1 |
| Prices Request Parameters | 100.0% | 100.0% | 5 | 5 |
| Prices Response Fields | 100.0% | 100.0% | 1 | 1 |
| Buy Asset Fields | 100.0% | 100.0% | 3 | 3 |
| Price Endpoint | 100.0% | 100.0% | 1 | 1 |
| Price Request Parameters | 100.0% | 100.0% | 8 | 8 |
| Price Response Fields | 100.0% | 100.0% | 5 | 5 |
| Post Quote Endpoint | 100.0% | 100.0% | 1 | 1 |
| Post Quote Request Fields | 100.0% | 100.0% | 9 | 9 |
| Get Quote Endpoint | 100.0% | 100.0% | 1 | 1 |
| Quote Response Fields | 100.0% | 100.0% | 9 | 9 |
| Fee Fields | 100.0% | 100.0% | 3 | 3 |
| Fee Details Fields | 100.0% | 100.0% | 3 | 3 |

## Detailed Field Comparison

### Info Endpoint

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `info_endpoint` | ✓ | ✅ | `info(jwt:)` | GET /info - Returns supported Stellar and off-chain assets available for trading |

### Info Response Fields

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `assets` | ✓ | ✅ | `assets` | Array of asset objects supported for trading |

### Asset Fields

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `asset` | ✓ | ✅ | `asset` | Asset identifier in Asset Identification Format |
| `sell_delivery_methods` |  | ✅ | `sellDeliveryMethods` | Array of delivery methods for selling this asset |
| `buy_delivery_methods` |  | ✅ | `buyDeliveryMethods` | Array of delivery methods for buying this asset |
| `country_codes` |  | ✅ | `countryCodes` | Array of ISO 3166-2 or ISO 3166-1 alpha-2 country codes |

### Delivery Method Fields

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `name` | ✓ | ✅ | `name` | Delivery method name identifier |
| `description` | ✓ | ✅ | `description` | Human-readable description of the delivery method |

### Prices Endpoint

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `prices_endpoint` | ✓ | ✅ | `prices(sellAsset:sellAmount:sellDeliveryMethod:buyDeliveryMethod:countryCode:jwt:)` | GET /prices - Returns indicative prices of off-chain assets in exchange for Stellar assets |

### Prices Request Parameters

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `sell_asset` | ✓ | ✅ | `sellAsset` | Asset to sell using Asset Identification Format |
| `sell_amount` | ✓ | ✅ | `sellAmount` | Amount of sell_asset to exchange |
| `sell_delivery_method` |  | ✅ | `sellDeliveryMethod` | Delivery method for off-chain sell asset |
| `buy_delivery_method` |  | ✅ | `buyDeliveryMethod` | Delivery method for off-chain buy asset |
| `country_code` |  | ✅ | `countryCode` | ISO 3166-2 or ISO-3166-1 alpha-2 country code |

### Prices Response Fields

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `buy_assets` | ✓ | ✅ | `buyAssets` | Array of buy asset objects with prices |

### Buy Asset Fields

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `asset` | ✓ | ✅ | `asset` | Asset identifier in Asset Identification Format |
| `price` | ✓ | ✅ | `price` | Price offered by anchor for one unit of buy_asset |
| `decimals` | ✓ | ✅ | `decimals` | Number of decimals for the buy asset |

### Price Endpoint

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `price_endpoint` | ✓ | ✅ | `price(context:sellAsset:buyAsset:sellAmount:buyAmount:sellDeliveryMethod:buyDeliveryMethod:countryCode:jwt:)` | GET /price - Returns indicative price for a specific asset pair |

### Price Request Parameters

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `context` | ✓ | ✅ | `context` | Context for quote usage (sep6 or sep31) |
| `sell_asset` | ✓ | ✅ | `sellAsset` | Asset client would like to sell |
| `buy_asset` | ✓ | ✅ | `buyAsset` | Asset client would like to exchange for sell_asset |
| `sell_amount` |  | ✅ | `sellAmount` | Amount of sell_asset to exchange (mutually exclusive with buy_amount) |
| `buy_amount` |  | ✅ | `buyAmount` | Amount of buy_asset to exchange for (mutually exclusive with sell_amount) |
| `sell_delivery_method` |  | ✅ | `sellDeliveryMethod` | Delivery method for off-chain sell asset |
| `buy_delivery_method` |  | ✅ | `buyDeliveryMethod` | Delivery method for off-chain buy asset |
| `country_code` |  | ✅ | `countryCode` | ISO 3166-2 or ISO-3166-1 alpha-2 country code |

### Price Response Fields

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `total_price` | ✓ | ✅ | `totalPrice` | Total conversion price including fees |
| `price` | ✓ | ✅ | `price` | Base conversion price excluding fees |
| `sell_amount` | ✓ | ✅ | `sellAmount` | Amount of sell_asset that will be exchanged |
| `buy_amount` | ✓ | ✅ | `buyAmount` | Amount of buy_asset that will be received |
| `fee` | ✓ | ✅ | `fee` | Fee object with total, asset, and optional details |

### Post Quote Endpoint

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `post_quote_endpoint` | ✓ | ✅ | `postQuote(request:jwt:)` | POST /quote - Request a firm quote for asset exchange |

### Post Quote Request Fields

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `context` | ✓ | ✅ | `context` | Context for quote usage (sep6 or sep31) |
| `sell_asset` | ✓ | ✅ | `sellAsset` | Asset client would like to sell |
| `buy_asset` | ✓ | ✅ | `buyAsset` | Asset client would like to exchange for sell_asset |
| `sell_amount` |  | ✅ | `sellAmount` | Amount of sell_asset to exchange (mutually exclusive with buy_amount) |
| `buy_amount` |  | ✅ | `buyAmount` | Amount of buy_asset to exchange for (mutually exclusive with sell_amount) |
| `expire_after` |  | ✅ | `expireAfter` | Requested expiration timestamp for the quote (ISO 8601) |
| `sell_delivery_method` |  | ✅ | `sellDeliveryMethod` | Delivery method for off-chain sell asset |
| `buy_delivery_method` |  | ✅ | `buyDeliveryMethod` | Delivery method for off-chain buy asset |
| `country_code` |  | ✅ | `countryCode` | ISO 3166-2 or ISO-3166-1 alpha-2 country code |

### Get Quote Endpoint

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `get_quote_endpoint` | ✓ | ✅ | `getQuote(id:jwt:)` | GET /quote/:id - Fetch a previously-provided firm quote |

### Quote Response Fields

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `id` | ✓ | ✅ | `id` | Unique identifier for the quote |
| `expires_at` | ✓ | ✅ | `expiresAt` | Expiration timestamp for the quote (ISO 8601) |
| `total_price` | ✓ | ✅ | `totalPrice` | Total conversion price including fees |
| `price` | ✓ | ✅ | `price` | Base conversion price excluding fees |
| `sell_asset` | ✓ | ✅ | `sellAsset` | Asset to be sold |
| `sell_amount` | ✓ | ✅ | `sellAmount` | Amount of sell_asset to be exchanged |
| `buy_asset` | ✓ | ✅ | `buyAsset` | Asset to be bought |
| `buy_amount` | ✓ | ✅ | `buyAmount` | Amount of buy_asset to be received |
| `fee` | ✓ | ✅ | `fee` | Fee object with total, asset, and optional details |

### Fee Fields

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `total` | ✓ | ✅ | `total` | Total fee amount as decimal string |
| `asset` | ✓ | ✅ | `asset` | Asset identifier for the fee |
| `details` |  | ✅ | `details` | Optional array of fee breakdown objects |

### Fee Details Fields

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `name` | ✓ | ✅ | `name` | Name identifier for the fee component |
| `amount` | ✓ | ✅ | `amount` | Fee amount as decimal string |
| `description` |  | ✅ | `description` | Human-readable description of the fee |

## Implementation Gaps

🎉 **No gaps found!** All fields are implemented.

## Recommendations

✅ The SDK has full compatibility with SEP-38!
- Always use SEP-10 authentication for protected endpoints
- Handle quote expiration appropriately in client applications
- Use /prices for multi-asset price discovery
- Use /price for single asset pair indicative pricing
- Use POST /quote for firm quotes before initiating transfers
- Provide either sell_amount or buy_amount, never both
- Specify context (sep6 or sep31) based on the transfer type
- Include delivery methods and country codes for off-chain assets
- Monitor quote expiration via expires_at timestamp
- Store quote IDs for transaction reconciliation

## Legend

- ✅ **Implemented**: Field is implemented in SDK
- ❌ **Not Implemented**: Field is missing from SDK
- ⚙️ **Server**: Server-side only feature (not applicable to client SDKs)
- ✓ **Required**: Field is required by SEP specification
- (blank) **Optional**: Field is optional

---

**Report Generated:** 2025-10-16
**SDK Version:** 3.2.7
**Analysis Tool:** SEP Compatibility Matrix Generator v2.0