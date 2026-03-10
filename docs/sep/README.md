# SEP Implementations

The SDK supports Stellar Ecosystem Proposals (SEPs) for interoperability with the Stellar ecosystem.

## What are SEPs?

Stellar Ecosystem Proposals (SEPs) define standards for how services, applications, and organizations interact with the Stellar network. They ensure consistent implementation of common patterns like domain verification, authentication, and asset transfers.

Think of SEPs as the "rules of the road" that let different Stellar applications talk to each other. When you use SEP-10 for authentication, any anchor that implements SEP-10 will understand your auth requests.

## Implemented SEPs

| SEP | Title | Documentation |
|-----|-------|---------------|
| SEP-01 | Stellar TOML | [sep-01.md](sep-01.md) |
| SEP-02 | Federation Protocol | [sep-02.md](sep-02.md) |
| SEP-05 | Key Derivation Methods | [sep-05.md](sep-05.md) |
| SEP-06 | Programmatic Deposit and Withdrawal | [sep-06.md](sep-06.md) |
| SEP-07 | URI Scheme | [sep-07.md](sep-07.md) |
| SEP-08 | Regulated Assets | [sep-08.md](sep-08.md) |
| SEP-09 | Standard KYC Fields | [sep-09.md](sep-09.md) |
| SEP-10 | Web Authentication | [sep-10.md](sep-10.md) |
| SEP-11 | Transaction Representation (Txrep) | [sep-11.md](sep-11.md) |
| SEP-12 | KYC API | [sep-12.md](sep-12.md) |
| SEP-23 | Strkey Encoding | [sep-23.md](sep-23.md) |
| SEP-24 | Interactive Deposit and Withdrawal | [sep-24.md](sep-24.md) |
| SEP-29 | Account Memo Requirements | [sep-29.md](sep-29.md) |
| SEP-30 | Account Recovery | [sep-30.md](sep-30.md) |
| SEP-38 | Anchor RFQ API | [sep-38.md](sep-38.md) |
| SEP-45 | Contract Account Authentication | [sep-45.md](sep-45.md) |
| SEP-53 | Message Signing | [sep-53.md](sep-53.md) |

## Which SEP Do I Need?

### Building a Wallet

Start by discovering anchor services, then authenticate and add deposit/withdrawal support:

1. **SEP-01** — Discover anchor endpoints via stellar.toml
2. **SEP-10** — Authenticate users with anchors (or **SEP-45** for contract accounts)
3. **SEP-12** — Submit KYC information required by anchors
4. **SEP-24** — Interactive deposit/withdrawal (recommended for most wallets)
5. **SEP-06** — Programmatic deposit/withdrawal (for automated flows)
6. **SEP-38** — Get exchange rate quotes (used with SEP-06 and SEP-24)

SEP-24 shows the user a web interface hosted by the anchor. SEP-06 handles everything via API calls. Most wallets use SEP-24 because it offloads UI complexity to the anchor. When exchanging between different assets (e.g., USD to USDC), SEP-38 provides rate quotes before the transaction.

### Working with Regulated Assets

Some assets require issuer approval for every transaction:

1. **SEP-08** — Get approval before submitting transactions with regulated assets

The issuer's approval server reviews each transaction and either approves, rejects, or requests modifications.

### Other Common Use Cases

| Use Case | SEPs |
|----------|------|
| Human-readable addresses (email-style) | SEP-02 |
| Deterministic key generation from mnemonics | SEP-05 |
| Payment requests via URI | SEP-07 |
| Standard KYC data fields | SEP-09 |
| Human-readable transaction format | SEP-11 |
| Strkey encoding and address validation | SEP-23 |
| Account memo requirements | SEP-29 |
| Account recovery via custodians | SEP-30 |
| Message signing and verification | SEP-53 |

## Learning More

Each SEP documentation page includes:
- Overview of what the protocol does
- Working code examples
- Error handling patterns
- Links to related SEPs

For the official specifications, see the [Stellar SEP repository](https://github.com/stellar/stellar-protocol/tree/master/ecosystem).
