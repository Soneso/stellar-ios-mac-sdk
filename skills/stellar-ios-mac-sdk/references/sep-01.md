# SEP-01: Stellar Info File (stellar.toml)

**Purpose:** Fetch and parse a domain's `stellar.toml` to discover anchor service endpoints and asset information.
**Prerequisites:** None
**SDK Class:** `StellarToml`

## Table of Contents

1. [Loading stellar.toml](#loading-stellartoml)
2. [Service Endpoint Discovery (AccountInformation)](#service-endpoint-discovery-accountinformation)
3. [Organization Documentation (IssuerDocumentation)](#organization-documentation-issuerdocumentation)
4. [Currencies (CurrencyDocumentation)](#currencies-currencydocumentation)
5. [Principals (PointOfContactDocumentation)](#principals-pointofcontactdocumentation)
6. [Validators (ValidatorInformation)](#validators-validatorinformation)
7. [Error Handling](#error-handling)
8. [Common Pitfalls](#common-pitfalls)

---

## Loading stellar.toml

### From a domain

`StellarToml.from(domain:)` is an `async` static method. It constructs `https://DOMAIN/.well-known/stellar.toml`, fetches it, and returns a `TomlForDomainEnum`. The `domain` parameter must not include a scheme.

```swift
import stellarsdk

let result = await StellarToml.from(domain: "testanchor.stellar.org")

switch result {
case .success(let stellarToml):
    // Access all parsed sections via properties
    if let webAuth = stellarToml.accountInformation.webAuthEndpoint {
        print("SEP-10 endpoint: \(webAuth)")
    }
    if let transferSep24 = stellarToml.accountInformation.transferServerSep24 {
        print("SEP-24 server: \(transferSep24)")
    }
    for currency in stellarToml.currenciesDocumentation {
        print("Asset: \(currency.code ?? "unknown"), Issuer: \(currency.issuer ?? "n/a")")
    }
case .failure(let error):
    print("Failed to load stellar.toml: \(error)")
}
```

The `secure` parameter defaults to `true` (HTTPS). Pass `secure: false` for HTTP-only testing only — never in production:

```swift
// Test environments only — never production
let result = await StellarToml.from(domain: "localhost:8080", secure: false)
```

### From a TOML string

`StellarToml(fromString:)` is a throwing initializer. Use it to parse a previously fetched or cached TOML string.

```swift
import stellarsdk

let tomlContent = """
VERSION = "2.7.0"
NETWORK_PASSPHRASE = "Public Global Stellar Network ; September 2015"
WEB_AUTH_ENDPOINT = "https://auth.example.com"
TRANSFER_SERVER_SEP0024 = "https://transfer.example.com/sep24"
SIGNING_KEY = "GBBHQ7H4V6RRORKYLHTCAWP6MOHNORRFJSDPXDFYDGJB2LPZUFPXUEW3"

[DOCUMENTATION]
ORG_NAME = "Example Organization"
ORG_URL = "https://example.com"
"""

do {
    let stellarToml = try StellarToml(fromString: tomlContent)
    print("Version: \(stellarToml.accountInformation.version ?? "unset")")
    print("Org: \(stellarToml.issuerDocumentation.orgName ?? "unset")")
} catch {
    print("Parse error: \(error)")
}
```

The `[DOCUMENTATION]` section is required — `fromString` throws `TomlFileError.invalidToml` if it is missing.

### Loading a linked currency TOML

Per SEP-01, a currency entry may contain only a `toml` URL pointing to a separate TOML file. Use `StellarToml.currencyFrom(url:)` to fetch it:

```swift
import stellarsdk

// First load the main stellar.toml
let result = await StellarToml.from(domain: "example.com")
guard case .success(let stellarToml) = result else { return }

// Check each currency for linked TOML entries
for currency in stellarToml.currenciesDocumentation {
    if let tomlUrl = currency.toml {
        // This entry is a link — other fields will be nil
        let currencyResult = await StellarToml.currencyFrom(url: tomlUrl)
        switch currencyResult {
        case .success(let fullCurrency):
            print("Linked currency: \(fullCurrency.code ?? ""), issuer: \(fullCurrency.issuer ?? "")")
        case .failure(let error):
            print("Failed to load linked currency: \(error)")
        }
    }
}
```

---

## Service Endpoint Discovery (AccountInformation)

`stellarToml.accountInformation` is an `AccountInformation` instance (never nil). All properties are `String?` except `accounts` which is `[String]` (never nil, may be empty).

This is the most common use of SEP-01: discovering which SEP services an anchor supports.

```swift
import stellarsdk

let result = await StellarToml.from(domain: "testanchor.stellar.org")
guard case .success(let stellarToml) = result else { return }

let info = stellarToml.accountInformation

// SEP service endpoints — nil if the anchor does not support that SEP
info.federationServer            // String?  SEP-02 Federation Server
info.transferServer              // String?  SEP-06 Deposit/Withdrawal
info.transferServerSep24         // String?  SEP-24 Interactive Deposit/Withdrawal
info.kycServer                   // String?  SEP-12 KYC / Customer Info
info.webAuthEndpoint             // String?  SEP-10 Web Authentication
info.webAuthForContractsEndpoint // String?  SEP-45 Web Auth for Soroban contracts
info.webAuthContractId           // String?  SEP-45 contract address (C...)
info.directPaymentServer         // String?  SEP-31 Cross-Border Payments
info.anchorQuoteServer           // String?  SEP-38 Quotes (RFQ)
info.uriRequestSigningKey        // String?  SEP-07 URI scheme signing key

// Signing key for SEP-10 challenge verification
info.signingKey                  // String?  G... public key

// Network and infrastructure
info.version                     // String?  SEP-01 spec version, e.g. "2.7.0"
info.networkPassphrase           // String?  network identifier string
info.horizonUrl                  // String?  anchor's public Horizon instance URL
info.accounts                    // [String] G... accounts controlled by this domain

// Deprecated
info.authServer                  // String?  SEP-03 Compliance (deprecated)
```

Always nil-check endpoints before using them:

```swift
guard let webAuthEndpoint = info.webAuthEndpoint,
      let signingKey = info.signingKey else {
    throw NSError(domain: "SEP01", code: 1,
                  userInfo: [NSLocalizedDescriptionKey: "Anchor does not support SEP-10"])
}

guard let transferServerSep24 = info.transferServerSep24 else {
    throw NSError(domain: "SEP01", code: 2,
                  userInfo: [NSLocalizedDescriptionKey: "Anchor does not support SEP-24"])
}
```

---

## Organization Documentation (IssuerDocumentation)

`stellarToml.issuerDocumentation` is an `IssuerDocumentation` instance (never nil). All properties are `String?`.

```swift
import stellarsdk

let result = await StellarToml.from(domain: "testanchor.stellar.org")
guard case .success(let stellarToml) = result else { return }

let docs = stellarToml.issuerDocumentation

docs.orgName                       // String?  legal name of organization
docs.orgDBA                        // String?  doing-business-as name
docs.orgURL                        // String?  official URL (same domain as stellar.toml)
docs.orgLogo                       // String?  URL to organization logo
docs.orgDescription                // String?  short description
docs.orgPhysicalAddress            // String?  physical address
docs.orgPhysicalAddressAttestation // String?  URL to address proof document
docs.orgPhoneNumber                // String?  E.164 format, e.g. "+14155551234"
docs.orgPhoneNumberAttestation     // String?  URL to phone bill image
docs.orgKeybase                    // String?  Keybase account name
docs.orgTwitter                    // String?  Twitter handle (without @)
docs.orgGithub                     // String?  GitHub organization account
docs.orgOfficialEmail              // String?  business partner contact email
docs.orgSupportEmail               // String?  user support email
docs.orgLicensingAuthority         // String?  regulatory authority name, if licensed
docs.orgLicenseType                // String?  license type, if applicable
docs.orgLicenseNumber              // String?  official license number, if applicable

// Example: display org info
if let orgName = docs.orgName {
    print("Organization: \(orgName)")
}
if let email = docs.orgSupportEmail {
    print("Support: \(email)")
}
```

---

## Currencies (CurrencyDocumentation)

`stellarToml.currenciesDocumentation` is `[CurrencyDocumentation]` (never nil, may be empty). Each entry maps to a `[[CURRENCIES]]` block in the TOML file.

```swift
import stellarsdk

let result = await StellarToml.from(domain: "testanchor.stellar.org")
guard case .success(let stellarToml) = result else { return }

for currency in stellarToml.currenciesDocumentation {

    // --- Token identifier ---
    // Classic Stellar asset: code + issuer are set
    // Soroban token (SEP-41): contract is set instead of issuer
    // Linked entry: only toml is set; all other fields are nil
    currency.code             // String?  asset code, e.g. "USDC" (max 12 chars)
    currency.issuer           // String?  G... issuer (classic Stellar assets)
    currency.contract         // String?  C... contract address (Soroban/SEP-41 tokens)
    currency.codeTemplate     // String?  wildcard pattern, e.g. "CORN????????"
    currency.toml             // String?  URL to linked currency TOML file

    // --- Display info ---
    currency.name             // String?  short display name (max 20 chars)
    currency.desc             // String?  description of what the token represents
    currency.conditions       // String?  terms and conditions
    currency.image            // String?  URL to token logo image
    currency.displayDecimals  // Int?     preferred decimal places (0–7)
    currency.status           // String?  "live", "dead", "test", or "private"

    // --- Supply model (at most one is set) ---
    currency.fixedNumber      // Int?     total fixed supply (never changes)
    currency.maxNumber        // Int?     maximum supply cap
    currency.isUnlimited      // Bool?    true = dilutable at issuer's discretion

    // --- Anchored asset info ---
    currency.isAssetAnchored        // Bool?   true if redeemable for underlying asset
    currency.anchorAssetType        // String? "fiat", "crypto", "nft", "stock",
                                    //         "bond", "commodity", "realestate", or "other"
    currency.anchorAsset            // String? underlying asset, e.g. "USD", "BTC"
    currency.attestationOfReserve   // String? URL to reserve audit/proof
    currency.redemptionInstructions // String? how to redeem the underlying asset

    // --- Crypto-backed collateral proof ---
    currency.collateralAddresses          // [String]  addresses holding backing assets
    currency.collateralAddressMessages    // [String]  reserve messages for each address
    currency.collateralAddressSignatures  // [String]  base64 signatures proving control

    // --- SEP-08 Regulated Assets ---
    currency.regulated        // Bool?   true if this is a SEP-08 regulated asset
    currency.approvalServer   // String? URL of SEP-08 approval service
    currency.approvalCriteria // String? human-readable approval requirements
}
```

Note: `collateralAddresses`, `collateralAddressMessages`, and `collateralAddressSignatures` are `[String]` (never nil, may be empty).

### Filtering currencies

```swift
// Find a specific asset
let usdc = stellarToml.currenciesDocumentation.first { $0.code == "USDC" }

// Get only live assets with issuers
let liveAssets = stellarToml.currenciesDocumentation.filter {
    $0.status == "live" && $0.issuer != nil
}

// Get Soroban token entries
let sorobanTokens = stellarToml.currenciesDocumentation.filter {
    $0.contract != nil
}

// Collect assets needing linked TOML fetch
let linkedEntries = stellarToml.currenciesDocumentation.filter {
    $0.toml != nil
}
```

---

## Principals (PointOfContactDocumentation)

`stellarToml.pointsOfContact` is `[PointOfContactDocumentation]` (never nil, may be empty). Each entry maps to a `[[PRINCIPALS]]` block.

```swift
import stellarsdk

let result = await StellarToml.from(domain: "testanchor.stellar.org")
guard case .success(let stellarToml) = result else { return }

for principal in stellarToml.pointsOfContact {
    principal.name                  // String?  full legal name
    principal.email                 // String?  business email address
    principal.keybase               // String?  Keybase account
    principal.telegram              // String?  Telegram handle
    principal.twitter               // String?  Twitter handle
    principal.github                // String?  GitHub account
    principal.idPhotoHash           // String?  SHA-256 of government ID photo
    principal.verificationPhotoHash // String?  SHA-256 of verification photo
}

// Access first principal
if let contact = stellarToml.pointsOfContact.first {
    print("Contact: \(contact.name ?? "unnamed"), \(contact.email ?? "no email")")
}
```

---

## Validators (ValidatorInformation)

`stellarToml.validatorsInformation` is `[ValidatorInformation]` (never nil, may be empty). Each entry maps to a `[[VALIDATORS]]` block. Most anchors do not run validators — this section is primarily used by node operators.

```swift
import stellarsdk

// stellar.org publishes SDF validators
let result = await StellarToml.from(domain: "stellar.org")
guard case .success(let stellarToml) = result else { return }

for validator in stellarToml.validatorsInformation {
    validator.alias       // String?  config name, e.g. "sdf1" (conforms to ^[a-z0-9-]{2,16}$)
    validator.displayName // String?  human-readable name, e.g. "SDF 1"
    validator.publicKey   // String?  G... node account public key
    validator.host        // String?  "domain.com:11625" or "IP:11625"
    validator.history     // String?  URL to history archive
}

// Print all validator nodes
for validator in stellarToml.validatorsInformation {
    print("\(validator.alias ?? "?") — \(validator.displayName ?? "?")")
    print("  Key: \(validator.publicKey ?? "?")")
    print("  Host: \(validator.host ?? "?")")
    print("  History: \(validator.history ?? "?")")
}
```

---

## Error Handling

### Result enums

`StellarToml.from(domain:)` returns `TomlForDomainEnum`:
- `.success(response: StellarToml)` — parsed successfully
- `.failure(error: TomlFileError)` — domain was invalid or TOML could not be parsed

`StellarToml.currencyFrom(url:)` returns `TomlCurrencyFromUrlEnum`:
- `.success(response: CurrencyDocumentation)` — currency parsed successfully
- `.failure(error: TomlCurrencyLoadError)` — URL was invalid or TOML could not be parsed

`StellarToml(fromString:)` is a throwing initializer — throws `TomlFileError.invalidToml` on parse failure.

### Error types

```swift
// TomlFileError — from StellarToml.from(domain:) and StellarToml(fromString:)
public enum TomlFileError: Error {
    case invalidDomain  // domain string could not form a valid URL
    case invalidToml    // TOML parse failure, or missing [DOCUMENTATION] section
}

// TomlCurrencyLoadError — from StellarToml.currencyFrom(url:)
public enum TomlCurrencyLoadError: Error {
    case invalidUrl   // URL string could not be parsed
    case invalidToml  // TOML parse failure
}
```

### Complete error handling example

```swift
import stellarsdk

func discoverAnchor(domain: String) async {
    let result = await StellarToml.from(domain: domain)

    switch result {
    case .success(let stellarToml):
        let info = stellarToml.accountInformation
        print("Version: \(info.version ?? "unset")")

        guard let webAuthEndpoint = info.webAuthEndpoint else {
            print("Anchor does not support SEP-10")
            return
        }
        print("SEP-10 endpoint: \(webAuthEndpoint)")

    case .failure(let error):
        switch error {
        case .invalidDomain:
            print("Invalid domain: \(domain)")
        case .invalidToml:
            print("Could not parse stellar.toml from \(domain)")
        }
    }
}
```

---

## Common Pitfalls

**`fromString` requires a `[DOCUMENTATION]` section:**

```swift
// WRONG: missing [DOCUMENTATION] section — throws TomlFileError.invalidToml
let tomlContent = """
VERSION = "2.7.0"
WEB_AUTH_ENDPOINT = "https://auth.example.com"
"""
let toml = try StellarToml(fromString: tomlContent)  // throws!

// CORRECT: [DOCUMENTATION] section is required (can be empty)
let tomlContent = """
VERSION = "2.7.0"
WEB_AUTH_ENDPOINT = "https://auth.example.com"
[DOCUMENTATION]
ORG_NAME = "Example"
"""
let toml = try StellarToml(fromString: tomlContent)  // succeeds
```

**Domain must not include a scheme:**

```swift
// WRONG: do not pass a URL with scheme
let result = await StellarToml.from(domain: "https://testanchor.stellar.org")
// Returns .failure(.invalidDomain) or fetches from "https://https://..."

// CORRECT: pass the bare domain only
let result = await StellarToml.from(domain: "testanchor.stellar.org")
```

**`issuerDocumentation` is always non-nil; check individual properties instead:**

```swift
// WRONG: this check is unnecessary and always true
if stellarToml.issuerDocumentation != nil { ... }

// CORRECT: check individual optional properties
if let orgName = stellarToml.issuerDocumentation.orgName {
    print("Org: \(orgName)")
}
```

**`currenciesDocumentation` and `validatorsInformation` are arrays, never nil:**

```swift
// WRONG: optional chaining on these arrays
stellarToml.currenciesDocumentation?.count  // compiler error — not optional

// CORRECT: use directly
stellarToml.currenciesDocumentation.count
stellarToml.validatorsInformation.isEmpty
```

**Linked currency entries have nil fields — only `toml` is set:**

```swift
// WRONG: accessing fields on a linked entry without checking
for currency in stellarToml.currenciesDocumentation {
    print(currency.code!)  // may crash if entry is a linked TOML reference
}

// CORRECT: check for linked entry first
for currency in stellarToml.currenciesDocumentation {
    if let tomlUrl = currency.toml {
        // This is a link — fetch the full data
        let linked = await StellarToml.currencyFrom(url: tomlUrl)
        // handle linked...
    } else {
        // Inline entry — code, issuer etc. are available
        print(currency.code ?? "unknown")
    }
}
```

**`accounts` is `[String]`, not `[String]?` — no nil check needed:**

```swift
// WRONG: optional check on accounts
if let accounts = stellarToml.accountInformation.accounts { ... }  // compiler error

// CORRECT: accounts is always [String], may be empty
let accounts = stellarToml.accountInformation.accounts
if accounts.isEmpty {
    print("No accounts listed")
}
```
