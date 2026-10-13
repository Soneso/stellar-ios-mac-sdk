# Documentation Strategy

This document defines the core strategy and principles for the Stellar iOS/macOS SDK documentation.

## Target Audience

All documentation is written for **SDK Users** - developers who want to integrate the SDK into their Swift applications.

**Who are SDK users?**
- iOS developers building Stellar integrations
- macOS developers building desktop Stellar applications
- Swift developers building cross-platform apps (iOS, macOS, tvOS, watchOS)
- Developers building payment systems, wallets, or anchor services
- Developers integrating with Stellar anchors via SEP protocols
- Developers building Soroban smart contract interactions
- AI agents assisting developers with Stellar integration

**Contributor documentation** (testing guides, architecture internals, build instructions) exists separately in CONTRIBUTING.md and is not part of the main learning path.

## Release Policy for Docs

`master`'s user documentation in `docs/` and the skill in `skills/` describe the released SDK, because users read them on GitHub against the SDK they can install. Documentation and skill content for unreleased behavior goes to the `release-docs` branch, not to the feature or fix branch that implements the behavior. Before a release, `master` is merged into `release-docs`, and `release-docs` is merged into the release preparation branch; `release-docs` is never the head of a pull request and is never merged directly into `master`. After the release it is fast-forwarded to `master`. Feature and fix branches carry code, tests, the CHANGELOG entry under `[Unreleased]`, and the version-independent process documents (`AGENTS.md`, `CONTRIBUTING.md`, this strategy) when a fact in them changes. Skill archives and the skill's generated API reference change only during release preparation; a run that regenerates them to check a change restores the committed files.

## Migration Guides

A release gets a migration guide when it changes behavior that existing code can observe. The test: code that compiled, ran, or passed its tests on the previous release fails to compile, behaves differently, or needs a change to keep its result. This covers changed defaults, removed or retyped API, stricter validation, and a new error type or message from an existing call. It also covers changed output spelling, new network requests, changes to the wire form, and fixes that end an error a caller may have worked around. A generated XDR addition gets a note when an exhaustive match over the type stops compiling or skips the new value silently. A deprecation gets a note only when the API also changes behavior; a removal always does. Additions, refactors, performance work, documentation, and CI changes get none.

The guide is `docs/migration/X.Y.Z.md`, titled `# Migrating to X.Y.Z`, and is written during release preparation from the final CHANGELOG section of the version. Its introduction reads (the clause on earlier guides is omitted when none exists):

```markdown
This guide covers the observable changes between P.Q.R and X.Y.Z. If you upgrade from an older version, also review the CHANGELOG between your version and P.Q.R and the earlier migration guides, newest first: [A.B.C](A.B.C.md). Each note describes one situation: whether you are affected, how it shows, and what to do.
```

When a guide covers more than one area, its notes are grouped under `## <area>` headings in the order of the CHANGELOG section; a guide with one area stays a flat list. Each note is one bullet for one situation:

1. "If you <what the affected code does>:", naming the API.
2. What happens in X.Y.Z, with the exact type, message, or value.
3. "In P.Q.R <what happened>.", naming the version.
4. The action in the imperative, with the opt-out if one exists, and what stays unaffected.

The previous-version sentence is the only history a note carries. A note stays under 120 words; a note over 150 words is split by situation.

A note carries a fenced before-and-after pair, labeled with both versions, when the action rewrites a call, a type, an override signature, or a multi-step recipe; the after block compiles against X.Y.Z. A one-token action (add `try`, catch a type, pass a flag) stays inline.

Every CHANGELOG `Breaking:` entry and every change of a kind this section names has a note, and every note traces to a CHANGELOG entry. The CHANGELOG states what the API does; the note says who is affected and what to do.

The CHANGELOG section of the version opens with `Migration guide: [docs/migration/X.Y.Z.md](docs/migration/X.Y.Z.md)`. The release notes end with a "Migrating to X.Y.Z" line that links the guide at the tag `X.Y.Z`. `docs/README.md` lists all guides, newest first. A correction of a published guide also updates the release notes of the version.

Review: a reviewer who did not write the guide starts from code that worked on P.Q.R and, note by note, decides whether they are affected, recognizes the symptom, and applies the action without the CHANGELOG or the source. A step that needs either fails the note.

## Core Principles

### 1. Progressive Learning

Documentation follows a structured learning path from novice to expert:

```
Quick Start -> Getting Started -> Core Concepts -> SEP Protocols -> Soroban
```

Each step assumes knowledge from the previous step. Complexity increases naturally.

**Learning paths by use case:**
- **Wallet developers**: Quick Start -> Accounts & Keys -> Transactions -> SEP-10 -> SEP-24/SEP-6
- **Anchor developers**: Quick Start -> Accounts & Keys -> SEP-1 -> SEP-10 -> SEP-12 -> SEP-24
- **DeFi developers**: Quick Start -> Accounts & Keys -> Transactions -> DEX Operations -> Soroban
- **Smart contract developers**: Quick Start -> Soroban Quick Start -> Contract Interaction -> Advanced Soroban

### 2. SDK Code Only

Documentation focuses exclusively on SDK usage. Avoid:
- **Framework-specific patterns** (UIKit view controllers, SwiftUI views, Combine pipelines)
- **Internal implementation details** (XDR encoding internals, HTTP client internals)
- **Hypothetical code** (classes, methods, or patterns not in the actual SDK)
- **Infrastructure concerns** (server setup, deployment, caching layers)

**Test**: Can a developer copy-paste this code and have it work with just the SDK dependency?

### 3. Examples Over Theory

Every section must have working code examples:
- Complete, runnable examples (no undefined variables)
- Real-world use cases (not abstract demonstrations)
- Comments explain WHY, not WHAT
- Show the happy path first, edge cases in Advanced docs
- All examples must include the required `import` statement

### 4. Accuracy Is Critical

All code must:
- Use actual SDK classes, methods, and properties
- Run without modifications (excluding secret keys)
- Be verified against SDK source code
- Use correct types, parameter names, and method signatures

**Verification process**: Cross-reference examples with actual SDK source files and test cases before publishing.

### 5. Conciseness Over Completeness

- Remove filler words and marketing language
- One clear example beats three redundant ones
- Link to source code for complete API reference (don't duplicate method signatures)
- Professional technical tone without unnecessary superlatives
- Avoid the word "comprehensive"

### 6. Swift Version Compatibility

Examples must work with Swift 6.0+ and Xcode 16+:
- Use modern Swift syntax (async/await, structured concurrency)
- Note the Swift/Xcode version requirements
- Use type annotations consistently
- Avoid deprecated Swift features

### 7. Human-Sounding Writing

Documentation must read like it was written by a developer, not generated by AI. Apply these rules:

**Avoid AI vocabulary and patterns:**
- Don't use: "comprehensive", "robust", "seamless", "pivotal", "crucial", "leverage"
- Don't use: "serves as", "stands as", "is a testament to"
- Don't use: "Additionally", "Moreover", "Furthermore" to start sentences
- Don't use: "It's important to note that...", "It should be noted..."
- Don't use em dashes; use a comma, a period, or a colon
- Don't use: forced groups of three ("fast, reliable, and secure")
- Don't use: vague attributions ("experts recommend", "developers often...")

**Do use:**
- Direct, specific language
- Active voice ("Send a payment" not "A payment can be sent")
- Natural sentence length variation
- Concrete examples over abstract claims
- First person when appropriate ("Here's how to..." or "You can...")
- Personality where it fits - docs can have voice

**No changelog residue:**

Documentation states the current contract, never the story of how the code got there, and never the counterfactual of what the code would do without one of its checks. Sentences shaped like "X happens rather than Y" or "X instead of Y", where Y is a former defect or a hypothetical failure, leak the author's editing context into the reader's head. The reader never imagined Y, learns nothing about the API from it, and is left wondering why it is mentioned. Migration guides are the one exception: each note names the previous version once (see Migration Guides).

Keep a "rather than"/"instead of" contrast only when both branches are real choices or plausible expectations for the reader ("returns nil rather than throwing", "catch the error rather than forcing the call with `try!`"). Delete it when the second branch exists only in the author's memory of the code.

```
DON'T: The checksum is verified, so a corrupted seed is rejected rather than
       imported as the signing key of a different account.

DO:    The checksum is verified, so a corrupted seed is rejected.
```

The justification for a check ("this guards against X") belongs in the commit message or release notes, not in user documentation.

**Comments explain WHY, not WHAT:**
```swift
// DON'T: This line creates a KeyPair by calling the generateRandomKeyPair() method
let keyPair = try! KeyPair.generateRandomKeyPair()

// DO: Generate credentials for a new account
let keyPair = try! KeyPair.generateRandomKeyPair()
```

**Quick Start goal:** A developer should go from zero to first transaction in 15 minutes.

## Content Guidelines

### SDK Usage Documentation

**sdk-usage.md structure:**
- Organized by **use case** (not by class structure)
- Complete working examples with all variables defined
- Links to source code for full API reference
- Focus on common patterns (80% use cases)

**What to include:**
- KeyPair generation, import, signing
- Mnemonic generation and key derivation (SEP-5)
- Transaction building and submission
- All Stellar operations with real use cases
- Horizon queries such as accounts, transactions, and effects
- Asset operations and trustlines
- DEX operations (offers, order book)
- Streaming/SSE support
- Multi-signature workflows
- Error handling patterns

**What to exclude:**
- Method signature documentation (source code handles this)
- Hypothetical wrapper classes
- UIKit/SwiftUI integration patterns
- Custom architecture or dependency injection layers

### SEP Protocol Documentation

Each SEP protocol guide follows this structure:
1. **Overview** (what problem it solves, when to use it)
2. **Quick Example** (minimal working code)
3. **Detailed Usage** (all features with examples)
4. **Error Handling** (common errors and solutions)
5. **Related SEPs** (links to related protocols)

**Length**: 200-500 lines per SEP depending on complexity

### Soroban Documentation

Soroban documentation covers:
1. **Quick Start** (deploy and invoke a simple contract)
2. **SorobanClient Usage** (high-level API)
3. **Contract Interaction** (invoking methods, handling results)
4. **Authorization** (Soroban auth framework)
5. **Contract Bindings** (generated type-safe clients)
6. **Advanced Topics** (manual transaction building, events)

### Multi-Class Namespace Reference Documentation

Some SDK namespaces span enough public classes that the generated API reference alone does not give consumers a single discoverable surface. The `smart-accounts/` directory is the current example: a kit with its own managers, configuration, error hierarchy, event stream, builder helpers, and per-platform providers.

For namespaces of this shape, a dedicated `api-reference.md` is permitted alongside the conceptual docs. The reference file complements the generated API reference: it groups related symbols, surfaces their relationships, and shows worked end-to-end examples that per-symbol pages cannot. Principle 5 (Conciseness Over Completeness) still applies. Link to the API reference, generated by jazzy and published at https://soneso.github.io/stellar-ios-mac-sdk/, for symbol-level docs (parameter doc-comments, type aliases, source files). Keep the reference file focused on the multi-symbol patterns a consumer needs to wire the namespace together.

Conceptual material (overview, architecture, lifecycle, key concepts) belongs in `README.md` and `onboarding.md`. Per-platform setup (entitlements, association files, signing) belongs in `webauthn-*.md` (or analogous setup pages for other namespaces).

### Example File Standards

Each example file should:
- Start with a brief description of what it demonstrates
- Include the required `import` statement
- Use testnet for examples (with note about public net)
- Include complete error handling where appropriate
- Link to relevant Stellar documentation

**Error handling in examples:** use `try!` when the input is fixed and known good (hardcoded literals, freshly generated values): a failure there is a programming error. Use `do`/`catch` where a value arrives at runtime (user input, network data). Never show `try!` on user-supplied input. The convention is explained to readers once, in getting-started.md; other pages follow it without restating it.

**Example file template:**
```markdown
# [Feature Name]

Brief description of what this example demonstrates.

## Prerequisites
- List any setup requirements

## Example

\`\`\`swift
import stellarsdk

// Complete, runnable example
\`\`\`

## Notes
- Important considerations
- Links to related documentation
```

## Quality Checklist

Before publishing or updating documentation, verify:

### Accuracy
- [ ] All class names match actual SDK
- [ ] All method names match actual SDK
- [ ] All property names match actual SDK
- [ ] All types are correct
- [ ] All examples verified against SDK source code

### Completeness
- [ ] No undefined variables in examples
- [ ] The `import` statement is shown
- [ ] SDK initialization code included
- [ ] Error handling appropriate for context

### Clarity
- [ ] Comments explain WHY, not WHAT
- [ ] Real-world use cases shown
- [ ] Links to related documentation
- [ ] Testnet or Public net noted
- [ ] No changelog residue: no "rather than"/"instead of" clause whose second branch is former behavior or a hypothetical defect

### Strategy Alignment
- [ ] Targets SDK users (not contributors)
- [ ] No UIKit/SwiftUI code
- [ ] No internal implementation details
- [ ] No hypothetical code
- [ ] Concise and professional tone

## Common Mistakes to Avoid

### 1. Hypothetical Code

**Wrong:**
```swift
// DON'T: This class doesn't exist in the SDK
class StellarService {
    let sdk: StellarSDK

    func getBalance(accountId: String) async -> String {
        // Custom wrapper logic
    }
}
```

**Right:**
```swift
// DO: Use actual SDK classes
let sdk = StellarSDK.testNet()
let response = await sdk.accounts.getAccountDetails(accountId: accountId)
switch response {
case .success(let details):
    for balance in details.accountBalances {
        // Process balances
    }
case .failure(let error):
    print("Error: \(error)")
}
```

### 2. Framework-Specific Code

**Wrong:**
```swift
// DON'T: This is UIKit-specific
class StellarViewController: UIViewController {
    var sdk: StellarSDK!

    override func viewDidLoad() {
        super.viewDidLoad()
        // ...
    }
}
```

**Right:**
```swift
// DO: Show direct SDK usage
let sdk = StellarSDK.testNet()
let response = await sdk.accounts.getAccountDetails(accountId: accountId)
```

### 3. Missing Import Statement

**Wrong:**
```swift
// DON'T: Missing import
let keyPair = try! KeyPair.generateRandomKeyPair()
```

**Right:**
```swift
// DO: Include the import
import stellarsdk

let keyPair = try! KeyPair.generateRandomKeyPair()
```

### 4. Over-Explanation

**Wrong:**
```swift
// DON'T: Repeat what the code obviously does
// This line calls the generateRandomKeyPair() method on the KeyPair class
// which returns a newly generated KeyPair instance with a random seed
let keyPair = try! KeyPair.generateRandomKeyPair()
```

**Right:**
```swift
// DO: Explain the purpose or context
// Generate a new keypair for account creation
let keyPair = try! KeyPair.generateRandomKeyPair()
```

### 5. Incomplete Examples

**Wrong:**
```swift
// DON'T: Undefined variables
try transaction.sign(keyPair: keyPair, network: .testnet)
let response = await sdk.transactions.submitTransaction(transaction: transaction)
```

**Right:**
```swift
// DO: Show complete flow
import stellarsdk

let sdk = StellarSDK.testNet()
// sourceSecretSeed: String for your funded testnet account, loaded from secure storage
// destinationAccountId: String for an existing testnet destination account
let sourceKeyPair = try! KeyPair(secretSeed: sourceSecretSeed)
let operation = try! PaymentOperation(
    sourceAccountId: nil,
    destinationAccountId: destinationAccountId,
    asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
    amount: 10.0
)
let response = await sdk.accounts.getAccountDetails(accountId: sourceKeyPair.accountId)
switch response {
case .success(let account):
    let transaction = try! Transaction(
        sourceAccount: account,
        operations: [operation],
        memo: nil
    )
    try transaction.sign(keyPair: sourceKeyPair, network: .testnet)
    let submitResponse = await sdk.transactions.submitTransaction(transaction: transaction)
    // Handle response
case .failure(let error):
    print("Error: \(error)")
}
```

## Documentation Structure

```
docs/
├── README.md                    # Documentation hub with learning paths
├── quick-start.md              # 15-minute fast path to first transaction
├── getting-started.md          # Fundamentals: installation, keys, accounts
├── sdk-usage.md                # All SDK features organized by use case
├── error-handling.md           # Error types, result codes, and debugging
├── soroban.md                  # Soroban smart contract development
├── smart-accounts/             # OpenZeppelin smart account namespace
│   ├── README.md              # Overview, architecture, quick start
│   ├── onboarding.md          # Concepts: signers, context rules, policies, deployer, relayer, verifier, indexer
│   ├── api-reference.md       # Public symbol reference for the smart-account namespace
│   ├── webauthn-ios.md        # iOS WebAuthn setup (Associated Domains + AASA)
│   └── webauthn-macos.md      # macOS WebAuthn setup
├── sep/
│   ├── README.md              # SEP overview and selection guide
│   ├── sep-01.md              # stellar.toml configuration
│   ├── sep-02.md              # Federation protocol
│   ├── sep-05.md              # Mnemonic and key derivation
│   ├── sep-06.md              # Programmatic deposit/withdrawal
│   ├── sep-07.md              # URI scheme for signing
│   ├── sep-08.md              # Regulated assets
│   ├── sep-09.md              # Standard KYC fields
│   ├── sep-10.md              # Web authentication
│   ├── sep-11.md              # Transaction representation
│   ├── sep-12.md              # KYC API
│   ├── sep-23.md              # Strkey encoding
│   ├── sep-24.md              # Interactive deposit/withdrawal
│   ├── sep-29.md              # Account memo requirements
│   ├── sep-30.md              # Account recovery
│   ├── sep-38.md              # Anchor quotes
│   ├── sep-45.md              # Contract account authentication
│   ├── sep-51.md              # XDR-JSON conversion
│   └── sep-53.md              # Message signing and verification
├── migration/                 # Migration guides, one per release
│   ├── 3.10.0.md              # Migrating to 3.10.0
│   └── 3.12.0.md              # Migrating to 3.12.0
└── documentation-strategy.md   # This file
```

**Root-level files (README.md, CONTRIBUTING.md):**
- README.md remains in project root as the primary entry point
- Links to docs/ for detailed documentation
- Contains quick start, installation, and feature overview

## Review Process

### For New Documentation

1. **Write** following this strategy
2. **Verify** against SDK source code
3. **Test** code examples run correctly
4. **Review** against quality checklist
5. **Cross-reference** links and navigation
6. **Publish** and update related docs

### For Existing Documentation

1. **Audit** against quality checklist
2. **Identify** violations such as hypothetical code or framework code
3. **Fix** issues systematically
4. **Verify** improvements maintain value
5. **Update** cross-references
6. **Document** changes

### Quarterly Maintenance

Every 3 months:
- Verify SDK method/class names still accurate
- Test code examples against latest SDK version
- Check for broken links
- Review new SDK features for documentation needs
- Update Stellar/SEP specification links

## Metrics for Success

Good documentation achieves:

**Quantitative:**
- Zero undefined variables in examples
- 100% accuracy (method names, class names match SDK)
- All examples include the required `import` statement
- All links functional

**Qualitative:**
- Developers can copy-paste examples and they work
- AI agents can understand and use the SDK correctly
- Clear learning path from beginner to advanced
- Fast time-to-first-transaction (Quick Start goal: 15 minutes)

## Related Documents

- [Quick Start Guide](quick-start.md) - 15-minute fast path to first transaction
- [Getting Started Guide](getting-started.md) - Fundamentals
- [SDK Usage](sdk-usage.md) - Practical code patterns
- [Soroban Guide](soroban.md) - Smart contract development
- [SEP Protocols](sep/README.md) - Stellar Ecosystem Proposals

---

**Last Updated**: 2026-10-13

**Next Review**: 2027-01-13 (Quarterly maintenance)
