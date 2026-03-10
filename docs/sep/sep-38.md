# SEP-38: Anchor RFQ API

Get exchange quotes between Stellar assets and off-chain assets (like fiat currencies).

## Overview

SEP-38 enables anchors to provide price quotes for asset exchanges. Use it when you need to:

- Show users estimated conversion rates before a deposit or withdrawal
- Lock in a firm exchange rate for a transaction
- Get available trading pairs from an anchor

Quotes come in two types:
- **Indicative quotes**: Estimated prices that may change (via `GET /prices` and `GET /price`)
- **Firm quotes**: Locked prices valid for a limited time (via `POST /quote`)

SEP-38 is used alongside SEP-6, SEP-24, or SEP-31 for the actual asset transfer.

## Quick example

This example shows how to connect to an anchor's quote service and fetch available assets and indicative prices:

```swift
import stellarsdk

// Connect to anchor's quote service
// First discover the URL from stellar.toml, or use a known URL directly
let quoteService = QuoteService(serviceAddress: "https://anchor.example.com/sep38")

// Get available assets for trading
let infoResult = await quoteService.info()
if case .success(let info) = infoResult {
    for asset in info.assets {
        print(asset.asset)
    }
}

// Get indicative prices for selling 100 USD
let pricesResult = await quoteService.prices(
    sellAsset: "iso4217:USD",
    sellAmount: "100"
)

if case .success(let prices) = pricesResult {
    for buyAsset in prices.buyAssets {
        print("Buy \(buyAsset.asset) at price \(buyAsset.price)")
    }
}
```

## Detailed usage

### Creating the service

The `QuoteService` class has methods for all SEP-38 endpoints. You create an instance with the quote server URL.

**From stellar.toml (recommended):**

Discover the quote server URL from the anchor's `ANCHOR_QUOTE_SERVER` field in stellar.toml, then create the service:

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

**With a direct URL:**

If you already know the quote server URL, you can instantiate the service directly:

```swift
import stellarsdk

let quoteService = QuoteService(serviceAddress: "https://anchor.example.com/sep38")
```

### Asset identification format

SEP-38 uses a specific format for identifying assets in requests and responses:

| Type | Format | Example |
|------|--------|---------|
| Stellar asset | `stellar:CODE:ISSUER` | `stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN` |
| Fiat currency | `iso4217:CODE` | `iso4217:USD` |

### Getting available assets (GET /info)

The `info()` method returns all Stellar and off-chain assets available for trading, along with their supported delivery methods and country restrictions:

```swift
import stellarsdk

let quoteService = QuoteService(serviceAddress: "https://anchor.example.com/sep38")

// Authentication is optional for this endpoint
let jwtToken: String? = nil // Or obtain via SEP-10 for personalized results

let infoResult = await quoteService.info(jwt: jwtToken)
if case .success(let info) = infoResult {
    for asset in info.assets {
        print("Asset: \(asset.asset)")

        // Check country restrictions for fiat assets
        if let codes = asset.countryCodes {
            print("  Available in: \(codes.joined(separator: ", "))")
        }

        // Check delivery methods for selling to the anchor
        if let sellMethods = asset.sellDeliveryMethods {
            for method in sellMethods {
                print("  Sell via \(method.name): \(method.description)")
            }
        }

        // Check delivery methods for receiving from the anchor
        if let buyMethods = asset.buyDeliveryMethods {
            for method in buyMethods {
                print("  Buy via \(method.name): \(method.description)")
            }
        }
    }
}
```

### Getting indicative prices (GET /prices)

The `prices()` method returns indicative (non-binding) exchange rates for multiple assets. Use this to show users what they can receive for a given amount.

```swift
import stellarsdk

let quoteService = QuoteService(serviceAddress: "https://anchor.example.com/sep38")

// What can I buy for 100 USD?
let pricesResult = await quoteService.prices(
    sellAsset: "iso4217:USD",
    sellAmount: "100",
    jwt: jwtToken // Optional
)

if case .success(let prices) = pricesResult {
    for buyAsset in prices.buyAssets {
        print("Asset: \(buyAsset.asset)")
        print("Price: \(buyAsset.price)")
        print("Decimals: \(buyAsset.decimals)")
    }
}
```

**With delivery method and country code:**

For off-chain assets, you can specify delivery methods and country codes to get more accurate pricing:

```swift
import stellarsdk

let quoteService = QuoteService(serviceAddress: "https://anchor.example.com/sep38")

// What USDC can I buy for 500 BRL via PIX in Brazil?
let pricesResult = await quoteService.prices(
    sellAsset: "iso4217:BRL",
    sellAmount: "500",
    sellDeliveryMethod: "PIX",
    countryCode: "BRA",
    jwt: jwtToken
)

if case .success(let prices) = pricesResult {
    for buyAsset in prices.buyAssets {
        print("\(buyAsset.asset) at \(buyAsset.price)")
    }
}
```

### Getting a price for a specific pair (GET /price)

The `price()` method returns an indicative price for a specific asset pair with detailed fee information. You must provide either `sellAmount` or `buyAmount`, but not both:

```swift
import stellarsdk

let quoteService = QuoteService(serviceAddress: "https://anchor.example.com/sep38")

// How much USDC do I get for 100 USD? (SEP-6 deposit context)
let priceResult = await quoteService.price(
    context: "sep6",
    sellAsset: "iso4217:USD",
    buyAsset: "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN",
    sellAmount: "100",
    jwt: jwtToken
)

if case .success(let price) = priceResult {
    print("Total price (with fees): \(price.totalPrice)")
    print("Price (without fees): \(price.price)")
    print("Sell amount: \(price.sellAmount)")
    print("Buy amount: \(price.buyAmount)")
    print("Fee total: \(price.fee.total) \(price.fee.asset)")
}
```

**Query by buy amount instead:**

If you know how much you want to receive, specify `buyAmount` instead:

```swift
import stellarsdk

let quoteService = QuoteService(serviceAddress: "https://anchor.example.com/sep38")

// How much USD do I need to get 50 USDC?
let priceResult = await quoteService.price(
    context: "sep6",
    sellAsset: "iso4217:USD",
    buyAsset: "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN",
    buyAmount: "50",
    jwt: jwtToken
)

if case .success(let price) = priceResult {
    print("You need to sell: \(price.sellAmount) USD")
    print("You will receive: \(price.buyAmount) USDC")
}
```

**With delivery methods:**

Specify delivery methods for more accurate quotes when working with off-chain assets:

```swift
import stellarsdk

let quoteService = QuoteService(serviceAddress: "https://anchor.example.com/sep38")

// BRL to USDC via PIX in Brazil, for SEP-31 cross-border payment
let priceResult = await quoteService.price(
    context: "sep31",
    sellAsset: "iso4217:BRL",
    buyAsset: "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN",
    sellAmount: "500",
    sellDeliveryMethod: "PIX",
    countryCode: "BRA",
    jwt: jwtToken
)
```

**Working with fee details:**

The response includes a detailed fee breakdown when provided by the anchor:

```swift
import stellarsdk

let quoteService = QuoteService(serviceAddress: "https://anchor.example.com/sep38")

let priceResult = await quoteService.price(
    context: "sep6",
    sellAsset: "iso4217:BRL",
    buyAsset: "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN",
    sellAmount: "500",
    jwt: jwtToken
)

if case .success(let price) = priceResult {
    print("Total fee: \(price.fee.total) \(price.fee.asset)")

    // Check for detailed fee breakdown
    if let details = price.fee.details {
        for detail in details {
            var desc = ""
            if let description = detail.description {
                desc = " (\(description))"
            }
            print("  \(detail.name): \(detail.amount)\(desc)")
        }
    }
}
```

### Requesting a firm quote (POST /quote)

Firm quotes lock in a guaranteed price for a limited time. Authentication is required. Use the `Sep38PostQuoteRequest` struct to build your request:

```swift
import stellarsdk

let quoteService = QuoteService(serviceAddress: "https://anchor.example.com/sep38")

// Build the quote request
var request = Sep38PostQuoteRequest(
    context: "sep6",
    sellAsset: "iso4217:USD",
    buyAsset: "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN"
)
request.sellAmount = "100"

// Submit the request (JWT is required)
let quoteResult = await quoteService.postQuote(request: request, jwt: jwtToken)

if case .success(let quote) = quoteResult {
    print("Quote ID: \(quote.id)")
    print("Expires at: \(quote.expiresAt)")
    print("Total price: \(quote.totalPrice)")
    print("Price (without fees): \(quote.price)")
    print("You sell: \(quote.sellAmount) (\(quote.sellAsset))")
    print("You receive: \(quote.buyAmount) (\(quote.buyAsset))")
}
```

**With expiration preference:**

You can request a minimum expiration time using the `expireAfter` property. The anchor may provide a longer expiration but should not provide a shorter one:

```swift
import stellarsdk

let quoteService = QuoteService(serviceAddress: "https://anchor.example.com/sep38")

// Request quote valid for at least 1 hour
var request = Sep38PostQuoteRequest(
    context: "sep6",
    sellAsset: "iso4217:USD",
    buyAsset: "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN"
)
request.sellAmount = "100"
request.expireAfter = Date(timeIntervalSinceNow: 3600)

let quoteResult = await quoteService.postQuote(request: request, jwt: jwtToken)
if case .success(let quote) = quoteResult {
    print("Quote valid until: \(quote.expiresAt)")
}
```

**With delivery methods:**

Include delivery methods when exchanging off-chain assets:

```swift
import stellarsdk

let quoteService = QuoteService(serviceAddress: "https://anchor.example.com/sep38")

// Quote for selling BRL via bank transfer, buying USDC
var request = Sep38PostQuoteRequest(
    context: "sep6",
    sellAsset: "iso4217:BRL",
    buyAsset: "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN"
)
request.sellAmount = "1000"
request.sellDeliveryMethod = "ACH"
request.countryCode = "BRA"

let quoteResult = await quoteService.postQuote(request: request, jwt: jwtToken)
```

### Retrieving a previous quote (GET /quote/:id)

Use `getQuote()` to retrieve a previously-created firm quote by its ID. This is useful for checking the quote status or retrieving details after creation. Authentication is required:

```swift
import stellarsdk

let quoteService = QuoteService(serviceAddress: "https://anchor.example.com/sep38")

// Use the ID from postQuote() response
let quoteId = "de762cda-a193-4961-861e-57b31fed6eb3"
let quoteResult = await quoteService.getQuote(id: quoteId, jwt: jwtToken)

if case .success(let quote) = quoteResult {
    print("Quote ID: \(quote.id)")
    print("Expires at: \(quote.expiresAt)")
    let isValid = quote.expiresAt > Date()
    print("Still valid: \(isValid)")
}
```

## Price formulas

The SEP-38 spec defines these relationships between price, amounts, and fees:

```
sell_amount = total_price * buy_amount
```

When the fee is in the sell asset:
```
sell_amount - fee = price * buy_amount
```

When the fee is in the buy asset:
```
sell_amount = price * (buy_amount + fee)
```

## Error handling

The SDK uses result enums rather than exceptions. Switch on `QuoteServiceError` cases for different error scenarios:

```swift
import stellarsdk

let quoteService = QuoteService(serviceAddress: "https://anchor.example.com/sep38")

var request = Sep38PostQuoteRequest(
    context: "sep6",
    sellAsset: "iso4217:USD",
    buyAsset: "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN"
)
request.sellAmount = "100"

let quoteResult = await quoteService.postQuote(request: request, jwt: jwtToken)

switch quoteResult {
case .success(let quote):
    print("Quote created: \(quote.id)")

case .failure(let error):
    switch error {
    case .invalidArgument(let message):
        // Both sellAmount and buyAmount provided, or neither provided
        print("Invalid request: \(message)")

    case .badRequest(let message):
        // HTTP 400 - Invalid request parameters
        print("Bad request: \(message)")

    case .permissionDenied(let message):
        // HTTP 403 - Authentication failed or not authorized
        print("Permission denied: \(message)")

    case .notFound(let message):
        // HTTP 404 - Quote not found (for getQuote)
        print("Quote not found: \(message)")

    case .parsingResponseFailed(let message):
        // Response could not be decoded
        print("Parsing failed: \(message)")

    case .horizonError(let horizonError):
        // Other HTTP errors
        print("Unexpected error: \(horizonError)")
    }
}
```

### Error reference

| Error Case | HTTP Status | Common Causes | Solution |
|-----------|-------------|---------------|----------|
| `.invalidArgument` | N/A | Both `sellAmount` and `buyAmount` provided, or neither provided | Provide exactly one of the two amounts |
| `.badRequest` | 400 | Invalid asset format, unsupported asset pair, invalid context | Check asset identifiers and required fields |
| `.permissionDenied` | 403 | Missing JWT, expired JWT, or user not authorized | Re-authenticate with SEP-10 |
| `.notFound` | 404 | Quote ID doesn't exist (for `getQuote`) | Verify quote ID; it may have expired and been removed |
| `.parsingResponseFailed` | N/A | Unexpected response format from server | Check anchor status; retry later |
| `.horizonError` | Other | Server error or unexpected response | Check anchor status; retry later |

## SDK classes reference

### Service class

| Class | Description |
|-------|-------------|
| `QuoteService` | Main service class with methods: `info()`, `prices()`, `price()`, `postQuote()`, `getQuote()` |

### Request classes

| Class | Description |
|-------|-------------|
| `Sep38PostQuoteRequest` | Request body for creating firm quotes via `postQuote()` |

### Response classes

| Class | Description |
|-------|-------------|
| `Sep38InfoResponse` | Response from `info()` containing available assets |
| `Sep38PricesResponse` | Response from `prices()` containing indicative prices for multiple assets |
| `Sep38PriceResponse` | Response from `price()` containing indicative price for a single pair |
| `Sep38QuoteResponse` | Response from `postQuote()` and `getQuote()` containing firm quote details |

### Model classes

| Class | Description |
|-------|-------------|
| `Sep38Asset` | Asset information including delivery methods and country availability |
| `Sep38BuyAsset` | Buy asset option with price from `prices()` response |
| `Sep38Fee` | Fee structure with total amount and optional breakdown |
| `Sep38FeeDetails` | Individual fee component (name, amount, description) |
| `Sep38SellDeliveryMethod` | Method for delivering off-chain assets to the anchor |
| `Sep38BuyDeliveryMethod` | Method for receiving off-chain assets from the anchor |

### Error cases

| Case | Description |
|-------|-------------|
| `.invalidArgument` | Client-side validation failure |
| `.badRequest` | HTTP 400 - Invalid request |
| `.permissionDenied` | HTTP 403 - Authentication required or failed |
| `.notFound` | HTTP 404 - Quote not found |
| `.parsingResponseFailed` | Response could not be decoded |
| `.horizonError` | Other HTTP errors |

## Related SEPs

- [SEP-10](sep-10.md) - Authentication for traditional Stellar accounts
- [SEP-6](sep-06.md) - Programmatic deposit/withdrawal (uses quotes with `context: "sep6"`)
- [SEP-24](sep-24.md) - Interactive deposit/withdrawal (uses quotes with `context: "sep24"`)

## Further reading

- [SDK source code](https://github.com/nicobigger/stellar-ios-mac-sdk/tree/main/stellarsdk/stellarsdk/quote) - QuoteService implementation

## Reference

- [SEP-38 Specification (v2.5.0)](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0038.md)

---

[Back to SEP Overview](README.md)
