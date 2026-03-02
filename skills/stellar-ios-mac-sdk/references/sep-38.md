# SEP-38: Anchor RFQ API

**Purpose:** Get exchange quotes between Stellar assets and off-chain assets for use in SEP-6 and SEP-24 flows.
**Prerequisites:** JWT from SEP-10 required for `postQuote()`; optional for `info()`, `prices()`, `price()`, and `getQuote()`
**SDK Class:** `QuoteService`

## Table of Contents

- [Quick Start](#quick-start)
- [Creating QuoteService](#creating-quoteservice)
- [Asset Identification Format](#asset-identification-format)
- [GET /info — Available Assets](#get-info--available-assets)
- [GET /prices — Indicative Prices (Multi-Asset)](#get-prices--indicative-prices-multi-asset)
- [GET /price — Indicative Price (Single Pair)](#get-price--indicative-price-single-pair)
- [POST /quote — Request a Firm Quote](#post-quote--request-a-firm-quote)
- [GET /quote/:id — Retrieve a Firm Quote](#get-quoteid--retrieve-a-firm-quote)
- [Response Objects Reference](#response-objects-reference)
- [Fee Objects](#fee-objects)
- [Delivery Methods](#delivery-methods)
- [Error Handling](#error-handling)
- [Price Formulas](#price-formulas)
- [Common Pitfalls](#common-pitfalls)

---

## Quick Start

```swift
import stellarsdk

// 1. Initialize with anchor quote server URL
let quoteService = QuoteService(serviceAddress: "https://anchor.example.com/sep38")

// 2. Get available assets (no auth required)
let infoResult = await quoteService.info()
if case .success(let info) = infoResult {
    for asset in info.assets {
        print("Asset: \(asset.asset)")
    }
}

// 3. Get indicative price for a pair
let priceResult = await quoteService.price(
    context: "sep6",
    sellAsset: "iso4217:USD",
    buyAsset: "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN",
    sellAmount: "100",
    jwt: jwtToken
)

// 4. Request a firm quote (auth required)
var request = Sep38PostQuoteRequest(
    context: "sep6",
    sellAsset: "iso4217:USD",
    buyAsset: "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN"
)
request.sellAmount = "100"
let quoteResult = await quoteService.postQuote(request: request, jwt: jwtToken)
if case .success(let quote) = quoteResult {
    print("Quote ID: \(quote.id)")
    print("Expires: \(quote.expiresAt)")
    print("Sell: \(quote.sellAmount) \(quote.sellAsset)")
    print("Buy:  \(quote.buyAmount) \(quote.buyAsset)")
}
```

---

## Creating QuoteService

`QuoteService` is initialized directly with the quote server URL. The iOS SDK does not have a `fromDomain` factory; discover the URL from the anchor's `stellar.toml` first:

```swift
import stellarsdk

// Discover the quote server URL from stellar.toml
let tomlResult = await StellarToml.from(domain: "anchor.example.com")
guard case .success(let toml) = tomlResult,
      let quoteServerUrl = toml.accountInformation.anchorQuoteServer else {
    print("Anchor does not publish ANCHOR_QUOTE_SERVER")
    return
}
let quoteService = QuoteService(serviceAddress: quoteServerUrl)
```

Constructor signature:
```
QuoteService(serviceAddress: String)
```

The `serviceAddress` property is publicly readable after initialization:
```swift
print(quoteService.serviceAddress) // "https://anchor.example.com/sep38"
```

---

## Asset Identification Format

SEP-38 uses a specific string format for asset identifiers. Always use these strings directly — do not pass `Asset` objects.

| Asset type | Format | Example |
|------------|--------|---------|
| Stellar asset | `stellar:CODE:ISSUER` | `stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN` |
| Fiat currency | `iso4217:CODE` | `iso4217:USD` |
| Fiat (regional) | `iso4217:CODE` | `iso4217:BRL` |

```swift
// WRONG: passing an Asset object — QuoteService expects String
let asset = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "USDC", issuer: issuerKeyPair)!
// CORRECT: use the SEP-38 string format
let sellAsset = "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN"
let buyAsset  = "iso4217:BRL"
```

---

## GET /info — Available Assets

Returns all Stellar and off-chain assets the anchor supports for quotes, including optional delivery methods and country restrictions.

Authentication is optional. Pass `nil` for unauthenticated calls.

```swift
import stellarsdk

let quoteService = QuoteService(serviceAddress: "https://anchor.example.com/sep38")

// JWT is optional — pass nil for unauthenticated call
let result = await quoteService.info(jwt: jwtToken)
switch result {
case .success(let info):
    for asset in info.assets {
        // asset is Sep38Asset
        print("Asset: \(asset.asset)")

        // Country codes for fiat assets — nil if no restriction
        if let codes = asset.countryCodes {
            print("  Countries: \(codes.joined(separator: ", "))")
        }

        // Methods for delivering this off-chain asset TO the anchor (sell)
        if let sellMethods = asset.sellDeliveryMethods {
            for method in sellMethods {
                print("  Sell via: \(method.name) — \(method.description)")
            }
        }

        // Methods for receiving this off-chain asset FROM the anchor (buy)
        if let buyMethods = asset.buyDeliveryMethods {
            for method in buyMethods {
                print("  Buy via: \(method.name) — \(method.description)")
            }
        }
    }
case .failure(let error):
    print("Error: \(error)")
}
```

Method signature:
```
func info(jwt: String? = nil) async -> Sep38InfoResponseEnum
```

### Result enum: `Sep38InfoResponseEnum`

```swift
switch result {
case .success(let response: Sep38InfoResponse): ...
case .failure(let error: QuoteServiceError): ...
}
```

### `Sep38InfoResponse` properties

| Property | Type | Description |
|----------|------|-------------|
| `assets` | `[Sep38Asset]` | All supported assets |

### `Sep38Asset` properties

| Property | Type | Description |
|----------|------|-------------|
| `asset` | `String` | Asset identifier in SEP-38 format |
| `sellDeliveryMethods` | `[Sep38SellDeliveryMethod]?` | Methods for delivering this asset to the anchor; `nil` if none |
| `buyDeliveryMethods` | `[Sep38BuyDeliveryMethod]?` | Methods for receiving this asset from the anchor; `nil` if none |
| `countryCodes` | `[String]?` | ISO 3166 country codes where this asset is available; `nil` if unrestricted |

---

## GET /prices — Indicative Prices (Multi-Asset)

Returns indicative (non-binding) prices for all tradeable buy assets when given a `sellAsset` and `sellAmount`. Use this to show users the full set of available options before they pick a specific pair.

Authentication is optional.

```swift
import stellarsdk

let quoteService = QuoteService(serviceAddress: "https://anchor.example.com/sep38")

let result = await quoteService.prices(
    sellAsset: "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN",
    sellAmount: "100",
    jwt: jwtToken  // optional
)
switch result {
case .success(let pricesResponse):
    for buyAsset in pricesResponse.buyAssets {
        // buyAsset is Sep38BuyAsset
        print("Asset: \(buyAsset.asset)")       // e.g. "iso4217:BRL"
        print("Price: \(buyAsset.price)")        // e.g. "0.18"
        print("Decimals: \(buyAsset.decimals)")  // e.g. 2
    }
case .failure(let error):
    print("Error: \(error)")
}
```

### With delivery method and country code

For off-chain assets, providing delivery method and country code yields more accurate indicative prices:

```swift
// What can I receive for 100 USDC, paid out via ACH in Brazil?
let result = await quoteService.prices(
    sellAsset: "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN",
    sellAmount: "100",
    sellDeliveryMethod: "wire",  // name from info() asset's sellDeliveryMethods
    buyDeliveryMethod: "ACH",    // name from info() asset's buyDeliveryMethods
    countryCode: "BRA",          // ISO 3166 code
    jwt: jwtToken
)
```

Method signature:
```
func prices(
    sellAsset: String,
    sellAmount: String,
    sellDeliveryMethod: String? = nil,
    buyDeliveryMethod: String? = nil,
    countryCode: String? = nil,
    jwt: String? = nil
) async -> Sep38PricesResponseEnum
```

### Result enum: `Sep38PricesResponseEnum`

```swift
switch result {
case .success(let response: Sep38PricesResponse): ...
case .failure(let error: QuoteServiceError): ...
}
```

### `Sep38PricesResponse` properties

| Property | Type | Description |
|----------|------|-------------|
| `buyAssets` | `[Sep38BuyAsset]` | Assets available to buy with their indicative prices |

### `Sep38BuyAsset` properties

| Property | Type | Description |
|----------|------|-------------|
| `asset` | `String` | Asset identifier in SEP-38 format |
| `price` | `String` | Indicative price (units of this asset per unit of sell asset) |
| `decimals` | `Int` | Decimal precision for this asset |

---

## GET /price — Indicative Price (Single Pair)

Returns an indicative price for a specific asset pair with fee details. You must provide either `sellAmount` or `buyAmount`, but not both. Providing both or neither returns a `.failure` with `.invalidArgument` before any network call is made.

Authentication is optional.

```swift
import stellarsdk

let quoteService = QuoteService(serviceAddress: "https://anchor.example.com/sep38")

// Query by sell amount: how much BRL do I get for 100 USDC?
let result = await quoteService.price(
    context: "sep6",   // "sep6" or "sep24"
    sellAsset: "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN",
    buyAsset: "iso4217:BRL",
    sellAmount: "100", // provide sellAmount OR buyAmount, not both
    jwt: jwtToken
)
switch result {
case .success(let price):
    print("Total price (with fees): \(price.totalPrice)")
    print("Price (without fees):    \(price.price)")
    print("Sell amount:             \(price.sellAmount)")
    print("Buy amount:              \(price.buyAmount)")
    print("Fee: \(price.fee.total) \(price.fee.asset)")
case .failure(let error):
    print("Error: \(error)")
}
```

### Query by buy amount

If you know the desired receive amount, use `buyAmount` instead:

```swift
// How much USDC do I need to sell to receive 500 BRL?
let result = await quoteService.price(
    context: "sep6",
    sellAsset: "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN",
    buyAsset: "iso4217:BRL",
    buyAmount: "500",  // provide buyAmount when you know the target receive amount
    jwt: jwtToken
)
if case .success(let price) = result {
    print("You need to sell: \(price.sellAmount)")
    print("You will receive: \(price.buyAmount)")
}
```

### With delivery methods

```swift
let result = await quoteService.price(
    context: "sep6",
    sellAsset: "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN",
    buyAsset: "iso4217:BRL",
    sellAmount: "100",
    sellDeliveryMethod: "wire",
    buyDeliveryMethod: "PIX",
    countryCode: "BRA",
    jwt: jwtToken
)
```

### Reading fee details

The response always includes a `Sep38Fee`. The optional `details` array contains itemized fee components:

```swift
if case .success(let price) = result {
    let fee = price.fee // Sep38Fee
    print("Fee total: \(fee.total) (\(fee.asset))")

    if let details = fee.details {
        for detail in details {
            // detail is Sep38FeeDetails
            var line = "\(detail.name): \(detail.amount)"
            if let desc = detail.description {
                line += " (\(desc))"
            }
            print(line)
        }
    }
}
```

Method signature:
```
func price(
    context: String,
    sellAsset: String,
    buyAsset: String,
    sellAmount: String? = nil,
    buyAmount: String? = nil,
    sellDeliveryMethod: String? = nil,
    buyDeliveryMethod: String? = nil,
    countryCode: String? = nil,
    jwt: String? = nil
) async -> Sep38PriceResponseEnum
```

### Result enum: `Sep38PriceResponseEnum`

```swift
switch result {
case .success(let response: Sep38PriceResponse): ...
case .failure(let error: QuoteServiceError): ...
}
```

### `Sep38PriceResponse` properties

| Property | Type | Description |
|----------|------|-------------|
| `totalPrice` | `String` | Total conversion price including fees |
| `price` | `String` | Base exchange rate without fees |
| `sellAmount` | `String` | Amount of sell asset that will be exchanged |
| `buyAmount` | `String` | Amount of buy asset that will be received |
| `fee` | `Sep38Fee` | Fee structure (always present) |

---

## POST /quote — Request a Firm Quote

A firm quote guarantees the exchange rate for a limited time. The returned `id` can be referenced in SEP-6 or SEP-24 transactions. Authentication is **required** — the `jwt` parameter is non-optional (`String`, not `String?`).

Either `sellAmount` or `buyAmount` must be set in the request, but not both. Providing both or neither returns a `.failure` with `.invalidArgument` without making a network call.

```swift
import stellarsdk

let quoteService = QuoteService(serviceAddress: "https://anchor.example.com/sep38")

// Build the request — use var to set optional fields after init
var request = Sep38PostQuoteRequest(
    context: "sep6",                // "sep6" or "sep24"
    sellAsset: "iso4217:BRL",
    buyAsset: "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN"
)
request.buyAmount = "100"           // OR sellAmount — not both

// JWT is required (non-optional String)
let result = await quoteService.postQuote(request: request, jwt: jwtToken)
switch result {
case .success(let quote):
    print("Quote ID:    \(quote.id)")
    print("Expires at:  \(quote.expiresAt)")
    print("Total price: \(quote.totalPrice)")
    print("Price:       \(quote.price)")
    print("Sell: \(quote.sellAmount) \(quote.sellAsset)")
    print("Buy:  \(quote.buyAmount) \(quote.buyAsset)")
    print("Fee:  \(quote.fee.total) \(quote.fee.asset)")
case .failure(let error):
    print("Error: \(error)")
}
```

### Request with expiration preference

Use `expireAfter` to signal when you need the quote to expire at the earliest:

```swift
var request = Sep38PostQuoteRequest(
    context: "sep6",
    sellAsset: "iso4217:USD",
    buyAsset: "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN"
)
request.sellAmount = "100"
request.expireAfter = Date(timeIntervalSinceNow: 3600)  // request at least 1 hour validity

let result = await quoteService.postQuote(request: request, jwt: jwtToken)
if case .success(let quote) = result {
    print("Valid until: \(quote.expiresAt)")
}
```

### Request with delivery methods

Include delivery method names (from `info()`) when exchanging off-chain assets:

```swift
var request = Sep38PostQuoteRequest(
    context: "sep6",
    sellAsset: "iso4217:BRL",
    buyAsset: "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN"
)
request.buyAmount = "100"
request.sellDeliveryMethod = "PIX"       // name from info() asset's sellDeliveryMethods
request.buyDeliveryMethod = "bank_transfer"
request.countryCode = "BRA"

let result = await quoteService.postQuote(request: request, jwt: jwtToken)
```

Method signature:
```
func postQuote(request: Sep38PostQuoteRequest, jwt: String) async -> Sep38QuoteResponseEnum
```

### `Sep38PostQuoteRequest` — all properties

Initialized with `init(context:sellAsset:buyAsset:)`. All other fields are set as mutable properties after init. The struct is `Sendable`.

```swift
// Required (set at init)
request.context               // String — "sep6" or "sep24"
request.sellAsset             // String — asset to sell in SEP-38 format
request.buyAsset              // String — asset to buy in SEP-38 format

// Exactly one required (set after init)
request.sellAmount            // String? — amount of sell asset (mutually exclusive with buyAmount)
request.buyAmount             // String? — amount of buy asset (mutually exclusive with sellAmount)

// Optional
request.expireAfter           // Date? — requested minimum quote validity
request.sellDeliveryMethod    // String? — delivery method name for sell asset
request.buyDeliveryMethod     // String? — delivery method name for buy asset
request.countryCode           // String? — ISO 3166 country code
```

---

## GET /quote/:id — Retrieve a Firm Quote

Retrieves a previously-created firm quote by its ID.

```swift
import stellarsdk

let quoteService = QuoteService(serviceAddress: "https://anchor.example.com/sep38")

let quoteId = "de762cda-a193-4961-861e-57b31fed6eb3"  // from postQuote() response
let result = await quoteService.getQuote(id: quoteId, jwt: jwtToken)
switch result {
case .success(let quote):
    print("Quote ID:   \(quote.id)")
    print("Expires at: \(quote.expiresAt)")
    let isValid = quote.expiresAt > Date()
    print("Still valid: \(isValid)")
    print("Sell: \(quote.sellAmount) \(quote.sellAsset)")
    print("Buy:  \(quote.buyAmount) \(quote.buyAsset)")
case .failure(let error):
    switch error {
    case .notFound(let message):
        print("Quote not found: \(message)")
    default:
        print("Error: \(error)")
    }
}
```

Method signature:
```
func getQuote(id: String, jwt: String? = nil) async -> Sep38QuoteResponseEnum
```

### Result enum: `Sep38QuoteResponseEnum`

Used by both `postQuote()` and `getQuote()`:

```swift
switch result {
case .success(let response: Sep38QuoteResponse): ...
case .failure(let error: QuoteServiceError): ...
}
```

### `Sep38QuoteResponse` properties

| Property | Type | Description |
|----------|------|-------------|
| `id` | `String` | Unique quote identifier |
| `expiresAt` | `Date` | When this quote expires |
| `totalPrice` | `String` | Total price including fees |
| `price` | `String` | Base exchange rate without fees |
| `sellAsset` | `String` | Asset being sold (SEP-38 format) |
| `sellAmount` | `String` | Amount of sell asset |
| `buyAsset` | `String` | Asset being purchased (SEP-38 format) |
| `buyAmount` | `String` | Amount of buy asset |
| `fee` | `Sep38Fee` | Fee structure (always present) |

---

## Response Objects Reference

### `Sep38Fee`

Fee structure present in both `Sep38PriceResponse` and `Sep38QuoteResponse`.

| Property | Type | Description |
|----------|------|-------------|
| `total` | `String` | Total fee amount as decimal string |
| `asset` | `String` | Asset in which the fee is denominated (SEP-38 format) |
| `details` | `[Sep38FeeDetails]?` | Itemized fee breakdown; `nil` when not provided by anchor |

### `Sep38FeeDetails`

One line item in a fee breakdown.

| Property | Type | Description |
|----------|------|-------------|
| `name` | `String` | Fee component name (e.g. `"Service fee"`, `"PIX fee"`) |
| `amount` | `String` | Amount for this component as decimal string |
| `description` | `String?` | Human-readable explanation; `nil` when not provided |

---

## Delivery Methods

`Sep38SellDeliveryMethod` and `Sep38BuyDeliveryMethod` have identical structure:

| Property | Type | Description |
|----------|------|-------------|
| `name` | `String` | Identifier used as parameter value (e.g. `"PIX"`, `"ACH"`, `"cash"`) |
| `description` | `String` | Human-readable description of the delivery method |

Use the `name` value as `sellDeliveryMethod` or `buyDeliveryMethod` in `prices()`, `price()`, and `Sep38PostQuoteRequest`.

```swift
// Discover valid delivery method names before using them
let infoResult = await quoteService.info(jwt: jwtToken)
if case .success(let info) = infoResult {
    for asset in info.assets {
        if asset.asset == "iso4217:BRL" {
            if let methods = asset.sellDeliveryMethods {
                for method in methods {
                    print("\(method.name): \(method.description)")
                    // Use method.name as sellDeliveryMethod parameter
                }
            }
        }
    }
}
```

---

## Error Handling

All `QuoteService` methods return result enums rather than throwing. Switch on `QuoteServiceError` cases:

```swift
import stellarsdk

var request = Sep38PostQuoteRequest(
    context: "sep6",
    sellAsset: "iso4217:USD",
    buyAsset: "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN"
)
request.sellAmount = "100"

let result = await quoteService.postQuote(request: request, jwt: jwtToken)
switch result {
case .success(let quote):
    print("Quote ID: \(quote.id)")

case .failure(let error):
    switch error {
    case .invalidArgument(let message):
        // Both sellAmount and buyAmount provided, or neither provided
        // Returned before any network call
        print("Invalid request: \(message)")

    case .badRequest(let message):
        // HTTP 400 — invalid asset format, unsupported pair, unknown context
        print("Bad request: \(message)")

    case .permissionDenied(let message):
        // HTTP 403 — missing or expired JWT, user not authorized
        print("Permission denied: \(message)")

    case .notFound(let message):
        // HTTP 404 — quote ID not found (getQuote only)
        print("Not found: \(message)")

    case .parsingResponseFailed(let message):
        // Response could not be decoded — unexpected server format
        print("Parsing failed: \(message)")

    case .horizonError(let horizonError):
        // Other HTTP errors (5xx, etc.)
        print("Horizon error: \(horizonError)")
    }
}
```

### `QuoteServiceError` reference

| Case | Trigger | Common cause |
|------|---------|--------------|
| `.invalidArgument(message:)` | `price()`, `postQuote()` | Both or neither of `sellAmount`/`buyAmount` provided |
| `.badRequest(message:)` | all methods | Invalid asset format, unsupported pair, missing required field |
| `.permissionDenied(message:)` | all methods | Missing or expired JWT, user not authorized |
| `.notFound(message:)` | `getQuote()` | Quote ID doesn't exist or has expired |
| `.parsingResponseFailed(message:)` | all methods | Unexpected response format from server |
| `.horizonError(error:)` | all methods | Other HTTP errors (5xx, network failures) |

---

## Price Formulas

The relationship between price, total_price, amounts, and fees:

```
sell_amount = total_price × buy_amount
```

When the fee is denominated in the **sell** asset:
```
sell_amount - fee.total = price × buy_amount
```

When the fee is denominated in the **buy** asset:
```
sell_amount = price × (buy_amount + fee.total)
```

`totalPrice` always includes fees. `price` is the raw exchange rate without fees.

---

## Common Pitfalls

**Providing both sellAmount and buyAmount:**

```swift
// WRONG: returns .failure(.invalidArgument(...)) — never reaches the server
let result = await quoteService.price(
    context: "sep6",
    sellAsset: "iso4217:USD",
    buyAsset: "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN",
    sellAmount: "100",
    buyAmount: "95"   // WRONG: cannot provide both
)

// CORRECT: provide exactly one
let result = await quoteService.price(
    context: "sep6",
    sellAsset: "iso4217:USD",
    buyAsset: "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN",
    sellAmount: "100"
)
```

**Providing neither sellAmount nor buyAmount:**

```swift
// WRONG: returns .failure(.invalidArgument(...))
var request = Sep38PostQuoteRequest(
    context: "sep6",
    sellAsset: "iso4217:USD",
    buyAsset: "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN"
)
// request.sellAmount and request.buyAmount are both nil — invalid
let result = await quoteService.postQuote(request: request, jwt: jwtToken)  // .failure

// CORRECT: set exactly one amount after init
var request = Sep38PostQuoteRequest(
    context: "sep6",
    sellAsset: "iso4217:USD",
    buyAsset: "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN"
)
request.sellAmount = "100"  // set BEFORE calling postQuote
let result = await quoteService.postQuote(request: request, jwt: jwtToken)
```

**Sep38PostQuoteRequest is a struct — declare with `var` to set optional fields:**

```swift
// WRONG: let prevents setting optional properties
let request = Sep38PostQuoteRequest(context: "sep6", sellAsset: "...", buyAsset: "...")
request.sellAmount = "100"  // compile error: cannot mutate let constant

// CORRECT: use var
var request = Sep38PostQuoteRequest(context: "sep6", sellAsset: "...", buyAsset: "...")
request.sellAmount = "100"
```

**postQuote() requires a non-optional JWT:**

```swift
// WRONG: jwt parameter of postQuote is String (non-optional) — nil causes compile error
// let result = await quoteService.postQuote(request: request, jwt: nil)

// CORRECT: obtain JWT via SEP-10 first
let webAuthResult = await WebAuthenticator.from(domain: "anchor.example.com", network: Network.testnet)
guard case .success(let webAuth) = webAuthResult else { return }
let jwtResult = await webAuth.jwtToken(forUserAccount: keyPair.accountId, signers: [keyPair])
guard case .success(let jwtToken) = jwtResult else { return }
let result = await quoteService.postQuote(request: request, jwt: jwtToken)
```

**expiresAt is a `Date`, not a String:**

```swift
if case .success(let quote) = result {
    // WRONG: treating Date as String
    // print(quote.expiresAt) — prints the Date's default description only

    // CORRECT: compare to Date() to check validity
    let isValid = quote.expiresAt > Date()
    print("Still valid: \(isValid)")

    // Format for display
    let formatter = ISO8601DateFormatter()
    print("Expires: \(formatter.string(from: quote.expiresAt))")
}
```

**fee.details is optional — always nil-check before iterating:**

```swift
if case .success(let price) = result {
    // WRONG: details may be nil when anchor does not provide itemized breakdown
    // for detail in price.fee.details { ... }  // crash on nil

    // CORRECT: nil-check first
    if let details = price.fee.details {
        for detail in details {
            print("\(detail.name): \(detail.amount)")
        }
    }
}
```

**totalPrice is not the raw exchange rate:**

```swift
// WRONG: totalPrice includes fees — misleading if used as a display rate
let displayRate = price.totalPrice

// CORRECT: use price for the raw rate; totalPrice satisfies sell_amount = total_price * buy_amount
let rawRate = price.price            // rate without fees
let effectiveRate = price.totalPrice // rate that includes fees in the sell amount
```

---

## Related SEPs

- [SEP-10](sep-10.md) — Web Authentication (provides JWT for `postQuote()`)
- [SEP-06](sep-06.md) — Deposit/Withdrawal API (use `context: "sep6"`)
- [SEP-24](sep-24.md) — Interactive Deposit/Withdrawal (use `context: "sep24"`)
- [SEP-01](sep-01.md) — stellar.toml (source of `ANCHOR_QUOTE_SERVER` URL)
