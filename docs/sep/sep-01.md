# SEP-01: Stellar info file (stellar.toml)

The stellar.toml file is a standardized configuration file that anchors and organizations host at their domains. It tells wallets and other services how to interact with their accounts, assets, and services. The SDK fetches and parses these files so your application can discover anchor endpoints.

**When to use:** Use this when your application needs to discover an anchor's service endpoints (SEP-6, SEP-10, SEP-24, federation, etc.) by fetching their stellar.toml file.

See the [SEP-01 specification](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0001.md) for protocol details.

**Note for implementers:** When hosting a stellar.toml file:
- File size must not exceed **100KB**
- Return `Access-Control-Allow-Origin: *` header for CORS
- Set `Content-Type: text/plain` so browsers render the file instead of downloading it

## Quick example

This example demonstrates loading a stellar.toml file from a domain and accessing service endpoints:

```swift
import stellarsdk

// Load stellar.toml from a domain
let result = await StellarToml.from(domain: "testanchor.stellar.org")

switch result {
case .success(let stellarToml):
    // Get service endpoints
    let info = stellarToml.accountInformation
    print("Transfer Server: \(info.transferServerSep24 ?? "not set")")
    print("Web Auth: \(info.webAuthEndpoint ?? "not set")")
case .failure(let error):
    print("Failed to load stellar.toml: \(error)")
}
```

## Loading stellar.toml

### From a domain

The SDK automatically constructs the URL `https://DOMAIN/.well-known/stellar.toml` and fetches the file:

```swift
import stellarsdk

let result = await StellarToml.from(domain: "soneso.com")

switch result {
case .success(let stellarToml):
    // Access organization info
    let docs = stellarToml.issuerDocumentation
    if let orgName = docs.orgName {
        print("Organization: \(orgName)")
    }
    if let supportEmail = docs.orgSupportEmail {
        print("Support: \(supportEmail)")
    }
case .failure(let error):
    print("Failed to load stellar.toml: \(error)")
}
```

### From a string

If you already have the TOML content (e.g., from a cached copy or test fixture), you can parse it directly:

```swift
import stellarsdk

let tomlContent = """
VERSION="2.0.0"
NETWORK_PASSPHRASE="Test SDF Network ; September 2015"
FEDERATION_SERVER="https://example.com/federation"
TRANSFER_SERVER_SEP0024="https://example.com/sep24"
WEB_AUTH_ENDPOINT="https://example.com/auth"
SIGNING_KEY="GCKX7PGTILCAM6NKST6PWNCBSMLHZJKFWXFHQLE4SUVKBQY3HOOYUNK"

[DOCUMENTATION]
ORG_NAME="Example Anchor"
ORG_URL="https://example.com"
"""

do {
    let stellarToml = try StellarToml(fromString: tomlContent)
    let info = stellarToml.accountInformation
    print("Version: \(info.version ?? "not set")")
} catch {
    print("Failed to parse stellar.toml: \(error)")
}
```

## Accessing data

### General information

The general information section contains service endpoints for SEP protocols and account information:

```swift
import stellarsdk

let result = await StellarToml.from(domain: "testanchor.stellar.org")
guard case .success(let stellarToml) = result else { return }

let info = stellarToml.accountInformation

// Protocol version
let version = info.version                           // String?  SEP-1 version (e.g., "2.0.0")

// Service endpoints
let federationServer = info.federationServer         // String?  SEP-02 Federation
let transferServer = info.transferServer              // String?  SEP-06 Deposit/Withdrawal
let transferServerSep24 = info.transferServerSep24    // String?  SEP-24 Interactive
let kycServer = info.kycServer                        // String?  SEP-12 KYC
let webAuthEndpoint = info.webAuthEndpoint            // String?  SEP-10 Web Auth
let directPaymentServer = info.directPaymentServer    // String?  SEP-31 Direct Payments
let anchorQuoteServer = info.anchorQuoteServer        // String?  SEP-38 Quotes

// SEP-45 Contract Web Authentication (Soroban)
let webAuthForContracts = info.webAuthForContractsEndpoint // String?  SEP-45 endpoint
let webAuthContractId = info.webAuthContractId        // String?  SEP-45 contract ID (C... address)

// Signing keys
let signingKey = info.signingKey                      // String?  For SEP-10 challenges
let uriSigningKey = info.uriRequestSigningKey         // String?  For SEP-07 URIs

// Deprecated (SEP-03 Compliance Protocol)
let authServer = info.authServer                      // String?  Deprecated

// Network info
let networkPassphrase = info.networkPassphrase        // String?
let horizonUrl = info.horizonUrl                      // String?

// Organization accounts
let accounts = info.accounts // [String] List of G... account IDs controlled by this domain
```

### Organization documentation

The documentation section contains contact and compliance information about the organization:

```swift
import stellarsdk

let result = await StellarToml.from(domain: "testanchor.stellar.org")
guard case .success(let stellarToml) = result else { return }

let docs = stellarToml.issuerDocumentation

// Basic organization info
print("Name: \(docs.orgName ?? "")")
print("DBA: \(docs.orgDBA ?? "")")
print("URL: \(docs.orgURL ?? "")")
print("Logo: \(docs.orgLogo ?? "")")
print("Description: \(docs.orgDescription ?? "")")

// Physical address with attestation
print("Address: \(docs.orgPhysicalAddress ?? "")")
print("Address Proof: \(docs.orgPhysicalAddressAttestation ?? "")")

// Phone number with attestation (E.164 format)
print("Phone: \(docs.orgPhoneNumber ?? "")")
print("Phone Proof: \(docs.orgPhoneNumberAttestation ?? "")")

// Contact information
print("Official Email: \(docs.orgOfficialEmail ?? "")")
print("Support Email: \(docs.orgSupportEmail ?? "")")

// Social accounts
print("Keybase: \(docs.orgKeybase ?? "")")
print("Twitter: \(docs.orgTwitter ?? "")")
print("GitHub: \(docs.orgGithub ?? "")")

// Licensing information (for regulated entities)
print("Licensing Authority: \(docs.orgLicensingAuthority ?? "")")
print("License Type: \(docs.orgLicenseType ?? "")")
print("License Number: \(docs.orgLicenseNumber ?? "")")
```

### Principals (points of contact)

The principals section contains identifying information for the organization's primary contact persons:

```swift
import stellarsdk

let result = await StellarToml.from(domain: "testanchor.stellar.org")
guard case .success(let stellarToml) = result else { return }

let principals = stellarToml.pointsOfContact

for principal in principals {
    // Basic contact info
    print("Name: \(principal.name ?? "")")
    print("Email: \(principal.email ?? "")")

    // Social accounts for verification
    print("Keybase: \(principal.keybase ?? "")")
    print("Telegram: \(principal.telegram ?? "")")
    print("Twitter: \(principal.twitter ?? "")")
    print("GitHub: \(principal.github ?? "")")

    // Identity verification hashes (SHA-256)
    print("ID Photo Hash: \(principal.idPhotoHash ?? "")")
    print("Verification Photo Hash: \(principal.verificationPhotoHash ?? "")")

    print("---")
}
```

### Currencies (assets)

The currencies section provides information about assets issued by the organization, including both classic Stellar assets and Soroban token contracts:

```swift
import stellarsdk

let result = await StellarToml.from(domain: "testanchor.stellar.org")
guard case .success(let stellarToml) = result else { return }

let currencies = stellarToml.currenciesDocumentation

for currency in currencies {
    // Basic token info
    print("Code: \(currency.code ?? "")")
    print("Name: \(currency.name ?? "")")
    print("Description: \(currency.desc ?? "")")
    print("Conditions: \(currency.conditions ?? "")")
    print("Status: \(currency.status ?? "")")  // live, dead, test, or private
    print("Decimals: \(currency.displayDecimals ?? 0)")
    print("Image: \(currency.image ?? "")")

    // Token identifier (one of these will be set)
    print("Issuer: \(currency.issuer ?? "")")         // G... for classic assets
    print("Contract: \(currency.contract ?? "")")     // C... for Soroban contracts (SEP-41)
    print("Code Template: \(currency.codeTemplate ?? "")") // Pattern for multiple assets

    // Supply information (mutually exclusive)
    print("Fixed Number: \(currency.fixedNumber ?? 0)")
    print("Max Number: \(currency.maxNumber ?? 0)")
    print("Unlimited: \(currency.isUnlimited == true ? "Yes" : "No")")

    // Anchored asset information
    print("Is Anchored: \(currency.isAssetAnchored == true ? "Yes" : "No")")
    print("Anchor Type: \(currency.anchorAssetType ?? "")")  // fiat, crypto, nft, stock, bond, commodity, realestate, other
    print("Anchor Asset: \(currency.anchorAsset ?? "")")
    print("Attestation: \(currency.attestationOfReserve ?? "")")
    print("Redemption: \(currency.redemptionInstructions ?? "")")

    // Collateral proof for crypto-backed tokens
    if !currency.collateralAddresses.isEmpty {
        print("Collateral Addresses: \(currency.collateralAddresses.joined(separator: ", "))")
        print("Collateral Messages: \(currency.collateralAddressMessages.joined(separator: ", "))")
        print("Collateral Signatures: \(currency.collateralAddressSignatures.joined(separator: ", "))")
    }

    // SEP-08 Regulated Assets
    print("Regulated: \(currency.regulated == true ? "Yes" : "No")")
    print("Approval Server: \(currency.approvalServer ?? "")")
    print("Approval Criteria: \(currency.approvalCriteria ?? "")")

    print("---")
}
```

### Linked currencies

Some stellar.toml files link to separate TOML files for detailed currency information. Use `currencyFrom(url:)` to fetch the full currency data:

```swift
import stellarsdk

let result = await StellarToml.from(domain: "example.com")
guard case .success(let stellarToml) = result else { return }

let currencies = stellarToml.currenciesDocumentation

for currency in currencies {
    // Check if currency details are in a separate file
    if let tomlUrl = currency.toml {
        let currencyResult = await StellarToml.currencyFrom(url: tomlUrl)
        switch currencyResult {
        case .success(let linkedCurrency):
            print("Code: \(linkedCurrency.code ?? "")")
            print("Issuer: \(linkedCurrency.issuer ?? "")")
            print("Name: \(linkedCurrency.name ?? "")")
        case .failure(let error):
            print("Failed to load linked currency: \(error)")
        }
    } else {
        // Currency data is inline
        print("Code: \(currency.code ?? "")")
    }
}
```

### Validators

The validators section is for organizations running Stellar validator nodes. Combined with SEP-20, it allows public declaration of nodes and archive locations:

```swift
import stellarsdk

let result = await StellarToml.from(domain: "stellar.org")
guard case .success(let stellarToml) = result else { return }

let validators = stellarToml.validatorsInformation

for validator in validators {
    print("Alias: \(validator.alias ?? "")")           // Config name (e.g., "sdf-1")
    print("Display Name: \(validator.displayName ?? "")")
    print("Public Key: \(validator.publicKey ?? "")")   // G... account
    print("Host: \(validator.host ?? "")")             // IP:port or domain:port
    print("History: \(validator.history ?? "")")       // Archive URL
    print("---")
}
```

## Error handling

The SDK returns result enums when fetching stellar.toml files. The `StellarToml(fromString:)` initializer throws on parse errors. Always handle both success and failure cases:

```swift
import stellarsdk

// Handle network failures
let result = await StellarToml.from(domain: "nonexistent-domain.invalid")
switch result {
case .success(let stellarToml):
    print("Loaded successfully")
case .failure(let error):
    // Domain unreachable, DNS failure, or stellar.toml not found (404)
    switch error {
    case .invalidDomain:
        print("Invalid domain")
    case .invalidToml:
        print("Could not parse stellar.toml")
    }
}

// Handle TOML parsing errors
do {
    let badToml = "this is not valid TOML [[["
    let stellarToml = try StellarToml(fromString: badToml)
} catch {
    print("Failed to parse stellar.toml: \(error)")
}
```

After loading, check for missing optional data before using it. Not all anchors implement every SEP:

```swift
import stellarsdk

let result = await StellarToml.from(domain: "example.com")
guard case .success(let stellarToml) = result else { return }

let info = stellarToml.accountInformation

// Check for SEP support before using endpoints
if info.webAuthEndpoint == nil {
    print("This anchor doesn't support SEP-10 authentication")
}

if info.transferServerSep24 == nil {
    print("This anchor doesn't support SEP-24 interactive deposits")
}

if info.kycServer == nil {
    print("This anchor doesn't support SEP-12 KYC")
}

// Check organization documentation properties individually
// (issuerDocumentation is always non-nil, but its properties are optional)
if let orgName = stellarToml.issuerDocumentation.orgName {
    print("Organization: \(orgName)")
} else {
    print("No organization name available")
}
```

## Testing your stellar.toml

Use these tools to validate your stellar.toml configuration:

- **[Stellar Anchor Validator](https://anchor-tests.stellar.org/)** - Test suite for anchor implementations, including stellar.toml validation
- **[stellar.toml checker](https://stellar.sui.li)** - Quick validation tool for stellar.toml files

## Related SEPs

SEPs that rely on stellar.toml for endpoint discovery or configuration:

- [SEP-02 Federation](sep-02.md) - `FEDERATION_SERVER`
- [SEP-06 Deposit/Withdrawal](sep-06.md) - `TRANSFER_SERVER`
- [SEP-07 URI Scheme](sep-07.md) - `URI_REQUEST_SIGNING_KEY`
- [SEP-08 Regulated Assets](sep-08.md) - Currency `approval_server`
- [SEP-10 Authentication](sep-10.md) - `WEB_AUTH_ENDPOINT`, `SIGNING_KEY`
- [SEP-12 KYC](sep-12.md) - `KYC_SERVER`
- [SEP-24 Interactive](sep-24.md) - `TRANSFER_SERVER_SEP0024`
- [SEP-38 Quotes](sep-38.md) - `ANCHOR_QUOTE_SERVER`
- [SEP-45 Contract Auth](sep-45.md) - `WEB_AUTH_FOR_CONTRACTS_ENDPOINT`, `WEB_AUTH_CONTRACT_ID`

---

[Back to SEP Overview](README.md)
