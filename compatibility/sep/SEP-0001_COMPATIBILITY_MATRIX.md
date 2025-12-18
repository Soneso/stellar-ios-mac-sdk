# SEP-0001 (Stellar Info File) Compatibility Matrix

**Generated:** 2025-12-18

**SEP Version:** 2.7.0

**SEP Status:** Active

**SEP URL:** https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0001.md

## SEP Summary

The `stellar.toml` file is used to provide a common place where the Internet can find information about your organization’s Stellar integration.

By setting the home_domain of your Stellar account to the domain that hosts your `stellar.toml`, you can create a definitive link between this information and that account.

Any website can publish Stellar network information, and the `stellar.toml` is designed to be readable by both humans and machines.

If you are an anchor or issuer, the `stellar.toml` file serves a very important purpose: it allows you to publish information about your organization and token(s) that help to legitimize your offerings.

Clients and exchanges can use this information to decide whether a token should be listed.

Fully and truthfully disclosing contact and business inf.

## Overall Coverage

**Total Coverage:** 100.0% (70/70 fields)

- ✅ **Implemented:** 70/70
- ❌ **Not Implemented:** 0/70

**Required Fields:** 100.0% (3/3)

**Optional Fields:** 100.0% (67/67)

## Implementation Status

✅ **Implemented**

### Implementation Files

- `stellarsdk/stellarsdk/toml/AccountInformation.swift`
- `stellarsdk/stellarsdk/toml/IssuerDocumentation.swift`
- `stellarsdk/stellarsdk/toml/PointOfContactDocumentation.swift`
- `stellarsdk/stellarsdk/toml/CurrencyDocumentation.swift`
- `stellarsdk/stellarsdk/toml/ValidatorInformation.swift`

### Key Classes

- **`AccountInformation`**: General Information fields from stellar.toml
- **`IssuerDocumentation`**: Organization Documentation fields ([DOCUMENTATION] section)
- **`PointOfContactDocumentation`**: Point of Contact fields ([[PRINCIPALS]] section)
- **`CurrencyDocumentation`**: Currency Documentation fields ([[CURRENCIES]] section)
- **`ValidatorInformation`**: Validator Information fields ([[VALIDATORS]] section)
- **`StellarToml`**: Main parser class for stellar.toml files

## Coverage by Section

| Section | Coverage | Required Coverage | Implemented | Total |
|---------|----------|-------------------|-------------|-------|
| General Information | 100.0% | 100.0% | 16 | 16 |
| Organization Documentation | 100.0% | 100.0% | 17 | 17 |
| Point of Contact Documentation | 100.0% | 100.0% | 8 | 8 |
| Currency Documentation | 100.0% | 100.0% | 24 | 24 |
| Validator Information | 100.0% | 100.0% | 5 | 5 |

## Detailed Field Comparison

### General Information

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `VERSION` |  | ✅ | `version` | The version of SEP-1 your `stellar.toml` adheres to. This helps parsers know which fields to expect. |
| `NETWORK_PASSPHRASE` |  | ✅ | `networkPassphrase` | The passphrase for the specific [Stellar network](https://developers.stellar.org/docs/networks) this infrastructure operates on |
| `FEDERATION_SERVER` |  | ✅ | `federationServer` | The endpoint for clients to resolve stellar addresses for users on your domain via [SEP-2](sep-0002.md) Federation Protocol |
| `AUTH_SERVER` |  | ✅ | `authServer` | (deprecated) The endpoint used for [SEP-3](sep-0003.md) Compliance Protocol |
| `TRANSFER_SERVER` |  | ✅ | `transferServer` | The server used for [SEP-6](sep-0006.md) Anchor/Client interoperability |
| `TRANSFER_SERVER_SEP0024` |  | ✅ | `transferServerSep24` | The server used for [SEP-24](sep-0024.md) Anchor/Client interoperability |
| `KYC_SERVER` |  | ✅ | `kycServer` | The server used for [SEP-12](sep-0012.md) Anchor/Client customer info transfer |
| `WEB_AUTH_ENDPOINT` |  | ✅ | `webAuthEndpoint` | The endpoint used for [SEP-10 Web Authentication](sep-0010.md) |
| `WEB_AUTH_FOR_CONTRACTS_ENDPOINT` |  | ✅ | `webAuthForContractsEndpoint` | The endpoint used for [SEP-45 Web Authentication](sep-0045.md) |
| `WEB_AUTH_CONTRACT_ID` |  | ✅ | `webAuthContractId` | The web authentication contract ID for [SEP-45 Web Authentication](sep-0045.md) |
| `SIGNING_KEY` |  | ✅ | `signingKey` | The signing key is used for [SEP-3](sep-0003.md) Compliance Protocol (deprecated) and [SEP-10](sep-0010.md)/[SEP-45](sep-0045.md) Authentication Pr... |
| `HORIZON_URL` |  | ✅ | `horizonUrl` | Location of public-facing Horizon instance (if you offer one) |
| `ACCOUNTS` |  | ✅ | `accounts` | A list of Stellar accounts that are controlled by this domain |
| `URI_REQUEST_SIGNING_KEY` |  | ✅ | `uriRequestSigningKey` | The signing key is used for [SEP-7](sep-0007.md) delegated signing |
| `DIRECT_PAYMENT_SERVER` |  | ✅ | `directPaymentServer` | The server used for receiving [SEP-31](sep-0031.md) direct fiat-to-fiat payments. Requires [SEP-12](sep-0012.md) and hence a `KYC_SERVER` TOML attr... |
| `ANCHOR_QUOTE_SERVER` |  | ✅ | `anchorQuoteServer` | The server used for receiving [SEP-38](sep-0038.md) requests. |

### Organization Documentation

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `ORG_NAME` |  | ✅ | `orgName` | Legal name of your organization |
| `ORG_DBA` |  | ✅ | `orgDBA` | (may not apply) [DBA](https://www.entrepreneur.com/encyclopedia/doing-business-as-dba) of your organization |
| `ORG_URL` |  | ✅ | `orgURL` | Your organization's official URL. Your `stellar.toml` must be hosted on the same domain. |
| `ORG_LOGO` |  | ✅ | `orgLogo` | A PNG image of your organization's logo on a transparent background |
| `ORG_DESCRIPTION` |  | ✅ | `orgDescription` | Short description of your organization |
| `ORG_PHYSICAL_ADDRESS` |  | ✅ | `orgPhysicalAddress` | Physical address for your organization |
| `ORG_PHYSICAL_ADDRESS_ATTESTATION` |  | ✅ | `orgPhysicalAddressAttestation` | URL on the same domain as your `ORG_URL` that contains an image or pdf official document attesting to your physical address. It must list your `ORG... |
| `ORG_PHONE_NUMBER` |  | ✅ | `orgPhoneNumber` | Your organization's phone number in [E.164 format](https://en.wikipedia.org/wiki/E.164), e.g. `+14155552671`. See also [this guide](https://support... |
| `ORG_PHONE_NUMBER_ATTESTATION` |  | ✅ | `orgPhoneNumberAttestation` | URL on the same domain as your `ORG_URL` that contains an image or pdf of a phone bill showing both the phone number and your organization's name. |
| `ORG_KEYBASE` |  | ✅ | `orgKeybase` | A [Keybase](https://keybase.io/) account name for your organization. Should contain proof of ownership of any public online accounts you list here,... |
| `ORG_TWITTER` |  | ✅ | `orgTwitter` | Your organization's Twitter account |
| `ORG_GITHUB` |  | ✅ | `orgGithub` | Your organization's Github account |
| `ORG_OFFICIAL_EMAIL` |  | ✅ | `orgOfficialEmail` | An email that business partners such as wallets, exchanges, or anchors can use to contact your organization. Must be hosted at your `ORG_URL` domain. |
| `ORG_SUPPORT_EMAIL` |  | ✅ | `orgSupportEmail` | An email that users can use to request support regarding your Stellar assets or applications. |
| `ORG_LICENSING_AUTHORITY` |  | ✅ | `orgLicensingAuthority` | Name of the authority or agency that issued a license, registration, or authorization to your organization, if applicable |
| `ORG_LICENSE_TYPE` |  | ✅ | `orgLicenseType` | Type of financial or other license, registration, or authorization your organization holds, if applicable |
| `ORG_LICENSE_NUMBER` |  | ✅ | `orgLicenseNumber` | Official license, registration, or authorization number of your organization, if applicable |

### Point of Contact Documentation

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `name` |  | ✅ | `name` | Full legal name |
| `email` |  | ✅ | `email` | Business email address for the principal |
| `keybase` |  | ✅ | `keybase` | Personal Keybase account. Should include proof of ownership for other online accounts, as well as the organization's domain. |
| `telegram` |  | ✅ | `telegram` | Personal Telegram account |
| `twitter` |  | ✅ | `twitter` | Personal Twitter account |
| `github` |  | ✅ | `github` | Personal Github account |
| `id_photo_hash` |  | ✅ | `idPhotoHash` | SHA-256 hash of a photo of the principal's government-issued photo ID |
| `verification_photo_hash` |  | ✅ | `verificationPhotoHash` | SHA-256 hash of a verification photo of principal. Should be well-lit and contain: principal holding ID card and signed, dated, hand-written messag... |

### Currency Documentation

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `code` | ✓ | ✅ | `code` | Token code. Required. |
| `issuer` | ✓ | ✅ | `issuer` | Stellar public key of the issuing account. Required for tokens that are Stellar Assets. Omitted if the token is not a Stellar asset. |
| `contract` | ✓ | ✅ | `contract` | Contract ID of the token contract. The token must be compatible with the [SEP-41 Token Interface](sep-0041.md) to be defined here. Required for tok... |
| `code_template` |  | ✅ | `codeTemplate` | A pattern with `?` as a single character wildcard. Allows a `[[CURRENCIES]]` entry to apply to multiple assets that share the same info. An example... |
| `status` |  | ✅ | `status` | Status of token. One of `live`, `dead`, `test`, or `private`. Allows issuer to mark whether token is dead/for testing/for private use or is live an... |
| `display_decimals` |  | ✅ | `displayDecimals` | Preference for number of decimals to show when a client displays currency balance |
| `name` |  | ✅ | `name` | A short name for the token |
| `desc` |  | ✅ | `desc` | Description of token and what it represents |
| `conditions` |  | ✅ | `conditions` | Conditions on token |
| `image` |  | ✅ | `image` | URL to a PNG image on a transparent background representing token |
| `fixed_number` |  | ✅ | `fixedNumber` | Fixed number of tokens, if the number of tokens issued will never change |
| `max_number` |  | ✅ | `maxNumber` | Max number of tokens, if there will never be more than `max_number` tokens |
| `is_unlimited` |  | ✅ | `isUnlimited` | The number of tokens is dilutable at the issuer's discretion |
| `is_asset_anchored` |  | ✅ | `isAssetAnchored` | `true` if token can be redeemed for underlying asset, otherwise `false` |
| `anchor_asset_type` |  | ✅ | `anchorAssetType` | Type of asset anchored. Can be `fiat`, `crypto`, `nft`, `stock`, `bond`, `commodity`, `realestate`, or `other`. |
| `anchor_asset` |  | ✅ | `anchorAsset` | If anchored token, code / symbol for asset that token is anchored to. E.g. USD, BTC, SBUX, Address of real-estate investment property. |
| `attestation_of_reserve` |  | ✅ | `attestationOfReserve` | URL to attestation or other proof, evidence, or verification of reserves, such as third-party audits. |
| `redemption_instructions` |  | ✅ | `redemptionInstructions` | If anchored token, these are instructions to redeem the underlying asset from tokens. |
| `collateral_addresses` |  | ✅ | `collateralAddresses` | If this is an anchored crypto token, list of one or more public addresses that hold the assets for which you are issuing tokens. |
| `collateral_address_messages` |  | ✅ | `collateralAddressMessages` | Messages stating that funds in the `collateral_addresses` list are reserved to back the issued asset. See below for details. |
| `collateral_address_signatures` |  | ✅ | `collateralAddressSignatures` | These prove you control the `collateral_addresses`. For each address you list, sign the entry in `collateral_address_messages` with the address's p... |
| `regulated` |  | ✅ | `regulated` | indicates whether or not this is a [sep0008](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0008.md) regulated asset. If mis... |
| `approval_server` |  | ✅ | `approvalServer` | url of a [sep0008](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0008.md) compliant approval service that signs validated t... |
| `approval_criteria` |  | ✅ | `approvalCriteria` | a human readable string that explains the issuer's requirements for approving transactions. |

### Validator Information

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `ALIAS` |  | ✅ | `alias` | A name for display in stellar-core configs that conforms to `^[a-z0-9-]{2,16}$` |
| `DISPLAY_NAME` |  | ✅ | `displayName` | A human-readable name for display in quorum explorers and other interfaces |
| `PUBLIC_KEY` |  | ✅ | `publicKey` | The Stellar account associated with the node |
| `HOST` |  | ✅ | `host` | The IP:port or domain:port peers can use to connect to the node |
| `HISTORY` |  | ✅ | `history` | The location of the history archive published by this validator |

## Implementation Gaps

🎉 **No gaps found!** All fields are implemented.

## Recommendations

✅ The SDK has full compatibility with SEP-01!
- Consider caching stellar.toml responses to reduce network requests
- Always use the secure (HTTPS) mode in production
- Handle TomlFileError cases appropriately in client applications
- For linked currency files, implement retry logic for network failures

## Legend

- ✅ **Implemented**: Field is implemented in SDK
- ❌ **Not Implemented**: Field is missing from SDK
- ⚙️ **Server**: Server-side only feature (not applicable to client SDKs)
- ✓ **Required**: Field is required by SEP specification
- (blank) **Optional**: Field is optional

---

**Report Generated:** 2025-12-18

**SDK Version:** 3.4.1

**Analysis Tool:** SEP Compatibility Matrix Generator v2.0