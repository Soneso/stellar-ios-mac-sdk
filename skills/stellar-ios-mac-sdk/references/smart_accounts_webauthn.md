# Smart Accounts — WebAuthn Providers and Storage Adapters

Platform-injected `WebAuthnProvider` and `OZStorageAdapter` for `OZSmartAccountConfig`. Core kit operations live in [smart_accounts.md](./smart_accounts.md); signer, context-rule, policy, and multi-signer flows live in [smart_accounts_policies.md](./smart_accounts_policies.md).

Everything in this file is exposed by a single module import:

```swift
import stellarsdk
```

There is no submodule. `WebAuthnProvider`, `AppleWebAuthnProvider`, `WebAuthnAllowCredential`, `OZStorageAdapter`, `OZStoredCredential`, `OZKeychainStorageAdapter`, `OZUserDefaultsStorageAdapter`, `OZInMemoryStorageAdapter`, and the result/update DTOs are all available after `import stellarsdk`.

This SDK targets **iOS and macOS only**. The Apple provider is gated `@available(iOS 16.0, macOS 13.0, *)`; there is no tvOS / watchOS / visionOS provider.

## Table of Contents

- [Overview](#overview)
- [Common Interfaces](#common-interfaces)
  - [`WebAuthnProvider` protocol](#webauthnprovider-protocol)
  - [`WebAuthnRegistrationResult`](#webauthnregistrationresult)
  - [`WebAuthnAuthenticationResult`](#webauthnauthenticationresult)
  - [`WebAuthnAllowCredential`](#webauthnallowcredential)
  - [`OZStorageAdapter` protocol](#ozstorageadapter-protocol)
  - [`OZStoredCredential`, `OZStoredSession`, `OZStoredCredentialUpdate`](#ozstoredcredential-ozstoredsession-ozstoredcredentialupdate)
  - [`OZInMemoryStorageAdapter`](#ozinmemorystorageadapter)
- [iOS](#ios)
- [macOS](#macos)
- [Choosing an OZStorageAdapter](#choosing-an-ozstorageadapter)
- [Implementing a custom OZStorageAdapter](#implementing-a-custom-ozstorageadapter)
- [Implementing a custom WebAuthnProvider](#implementing-a-custom-webauthnprovider)
- [iOS / macOS setup checklist](#ios--macos-setup-checklist)

---

## Overview

`WebAuthnProvider` and `OZStorageAdapter` are the two pluggable dependencies the smart-account kit needs from the host application:

- **`WebAuthnProvider`** drives the platform passkey ceremonies — registration (create) and authentication (assert). The SDK never talks to `AuthenticationServices` directly from the kit; it calls the provider you inject. `AppleWebAuthnProvider` is the shipped iOS/macOS implementation.
- **`OZStorageAdapter`** persists `OZStoredCredential` records and the reconnection `OZStoredSession`. The SDK ships `OZKeychainStorageAdapter` (encrypted, production), `OZUserDefaultsStorageAdapter` (scoped, non-encrypted), and `OZInMemoryStorageAdapter` (tests / ephemeral only).

Both are injected through `OZSmartAccountConfig`, which keeps the kit platform-agnostic and testable:

```swift
let config = try OZSmartAccountConfig(
    rpcUrl: "https://soroban-testnet.stellar.org",
    networkPassphrase: Network.testnet.passphrase,
    accountWasmHash: "your-wasm-hash-hex",
    webauthnVerifierAddress: "your-verifier-c-address",
    webauthnProvider: webAuthn,   // a WebAuthnProvider
    storage: storage              // an OZStorageAdapter
)
```

The direct throwing initializer is the primary path; the two inject points are `webauthnProvider:` (`WebAuthnProvider? = nil`) and `storage:` (`OZStorageAdapter = OZInMemoryStorageAdapter()`). `OZSmartAccountConfig.builder(...)` is a fluent alternative with identical validation if you prefer chaining.

`webauthnProvider` is **optional** in the config (`WebAuthnProvider?`). A provider is required for any flow that creates or signs with a passkey (wallet creation, transaction signing, signer changes). Read-only flows do not need one. `storage` is **non-optional** and defaults to `OZInMemoryStorageAdapter()` when not supplied — fine for tests, never for production.

```swift
// WRONG: shipping production with the default storage
let config = try OZSmartAccountConfig(/* ... */)  // storage == OZInMemoryStorageAdapter()
//   Credentials and session are lost on app restart.
// CORRECT: inject a persistent adapter
let config = try OZSmartAccountConfig(/* ... */, storage: OZKeychainStorageAdapter())
```

The relying-party identity (`rpId`, `rpName`) is set on `AppleWebAuthnProvider`, not on `OZSmartAccountConfig`. `OZSmartAccountConfig` has no `rpId` or `rpName` fields.

---

## Common Interfaces

The protocols and DTOs below are shared by every provider and adapter, shipped and custom.

### `WebAuthnProvider` protocol

```swift
public protocol WebAuthnProvider: Sendable {
    func register(
        challenge: Data,
        userId: Data,
        userName: String
    ) async throws -> WebAuthnRegistrationResult

    func authenticate(
        challenge: Data,
        allowCredentials: [WebAuthnAllowCredential]?
    ) async throws -> WebAuthnAuthenticationResult
}
```

`Sendable` is required — the protocol crosses actor/task boundaries inside the transaction pipeline. Both methods are `async throws`. Thrown errors are `WebAuthnException` subclasses (`RegistrationFailed`, `AuthenticationFailed`, `NotSupported`, `Cancelled`).

```swift
// WRONG: provider.register(challenge: "challenge-string", ...)  — challenge is Data, not String
// CORRECT: provider.register(challenge: challengeData, userId: userIdData, userName: "Alice")

// WRONG: provider.authenticate(challenge: data)  — allowCredentials is a required argument label
// CORRECT: provider.authenticate(challenge: data, allowCredentials: nil)
//   or:     provider.authenticate(challenge: data, allowCredentials: WebAuthnAllowCredential.fromIds([idData]))
```

The `challenge` MUST be passed to the authenticator as-is in both methods. For `register` it binds the credential to the deployment; for `authenticate` it is the authorization-payload hash that authorizes the transaction.

### `WebAuthnRegistrationResult`

```swift
public struct WebAuthnRegistrationResult: Equatable, Hashable, Sendable {
    public let credentialId: Data        // raw credential ID bytes
    public let publicKey: Data           // 65-byte uncompressed secp256r1 (0x04 || X || Y), or raw platform bytes
    public let attestationObject: Data   // raw CBOR attestation object
    public let transports: [String]?     // e.g. ["internal"], ["hybrid", "usb"]
    public let deviceType: String?       // "singleDevice" or "multiDevice"
    public let backedUp: Bool?           // true when the passkey is cloud-synced

    public init(
        credentialId: Data,
        publicKey: Data,
        attestationObject: Data,
        transports: [String]? = nil,
        deviceType: String? = nil,
        backedUp: Bool? = nil
    )
}
```

```swift
// WRONG: result.publicKey.count == 33   — that is the compressed point form
// CORRECT: result.publicKey.count == 65 && result.publicKey.first == 0x04
//   If the platform returns COSE/SPKI/attestation bytes instead, populate `publicKey` with the
//   raw bytes plus `attestationObject`; `SmartAccountUtils.extractPublicKeyFromRegistration` derives the 65-byte key.
```

### `WebAuthnAuthenticationResult`

```swift
public struct WebAuthnAuthenticationResult: Equatable, Hashable, Sendable {
    public let credentialId: Data
    public let authenticatorData: Data   // >= 37 bytes: rpIdHash(32) + flags(1) + signCount(4) + ...
    public let clientDataJSON: Data      // embeds the challenge as base64url, no padding
    public let signature: Data           // DER-encoded ECDSA P-256

    public init(
        credentialId: Data,
        authenticatorData: Data,
        clientDataJSON: Data,
        signature: Data
    )
}
```

The kit normalizes the DER `signature` to the 64-byte compact low-S `r || s` form Soroban requires, via `SmartAccountUtils.normalizeSignature`. Providers return DER exactly as the platform delivers it — do **not** pre-normalize (double-normalization corrupts the signature).

### `WebAuthnAllowCredential`

```swift
public struct WebAuthnAllowCredential: Equatable, Hashable, Sendable {
    public let id: Data                  // raw credential ID bytes
    public let transports: [String]?     // "internal" | "hybrid" | "usb" | "ble" | "nfc"

    public init(id: Data, transports: [String]? = nil)

    public static func fromId(_ id: Data) -> WebAuthnAllowCredential
    public static func fromIds(_ ids: [Data]) -> [WebAuthnAllowCredential]
}
```

Passed to `authenticate(challenge:allowCredentials:)` to constrain which passkey the authenticator offers and to carry transport hints. When `allowCredentials` is `nil`, discoverable-credential selection is used (the user picks the passkey).

```swift
// Restrict to a known credential, hinting cross-device:
let cred = WebAuthnAllowCredential(id: credentialIdData, transports: ["internal", "hybrid"])
let result = try await provider.authenticate(challenge: challenge, allowCredentials: [cred])

// Or from a list of raw IDs, no transports:
let creds = WebAuthnAllowCredential.fromIds([idA, idB])
```

### `OZStorageAdapter` protocol

All adapters implement the same contract. Method names are short (`save` / `get` / `delete`), not `saveCredential` / `getCredential`.

```swift
public protocol OZStorageAdapter: AnyObject, Sendable {
    // Credentials
    func save(credential: OZStoredCredential) async throws
    func get(credentialId: String) async throws -> OZStoredCredential?
    func getByContract(contractId: String) async throws -> [OZStoredCredential]
    func getAll() async throws -> [OZStoredCredential]
    func delete(credentialId: String) async throws
    func update(credentialId: String, updates: OZStoredCredentialUpdate) async throws
    func clear() async throws
    // Sessions
    func saveSession(_ session: OZStoredSession) async throws
    func getSession() async throws -> OZStoredSession?
    func clearSession() async throws
}
```

```swift
// WRONG: storage.saveCredential(cred)            // method is save(credential:)
// CORRECT: try await storage.save(credential: cred)
// WRONG: storage.getCredential("abc")            // method is get(credentialId:)
// CORRECT: try await storage.get(credentialId: "abc")
// WRONG: storage.getAllCredentials()             // method is getAll()
// CORRECT: try await storage.getAll()
// WRONG: storage.deleteCredential("abc")         // method is delete(credentialId:)
// CORRECT: try await storage.delete(credentialId: "abc")
```

Contract notes:

- `save` uses **upsert** semantics — a credential with the same ID is overwritten.
- `update` applies a partial `OZStoredCredentialUpdate`: non-nil fields overwrite, nil fields are left unchanged. There is no way to set a previously non-nil field back to nil via `update` — call `save` with a full replacement, or construct a fresh `OZStoredCredential`. `update` throws `SmartAccountCredentialException.NotFound` for an unknown ID.
- `clear` removes **all** credentials AND the stored session (hard reset).
- `getSession()` returns `nil` both when no session exists and when the stored session is expired; the adapter auto-clears expired sessions on read. After app restart always check the return value.
- Errors surface as `SmartAccountStorageException.ReadFailed` / `SmartAccountStorageException.WriteFailed`.

### `OZStoredCredential`, `OZStoredSession`, `OZStoredCredentialUpdate`

```swift
public struct OZStoredCredential: Sendable {
    public let credentialId: String                       // Base64URL-encoded
    public let publicKey: Data                            // 65-byte 0x04-prefixed secp256r1
    public let contractId: String?                        // C… strkey, nil until derived
    public let deploymentStatus: OZCredentialDeploymentStatus
    public let deploymentError: String?
    public let createdAt: Int64                           // ms since epoch
    public let lastUsedAt: Int64?
    public let nickname: String?
    public let isPrimary: Bool
    public let transports: [String]?                      // e.g. "usb", "nfc", "ble", "internal"
    public let deviceType: String?                        // "singleDevice" | "multiDevice"
    public let backedUp: Bool?

    public init(
        credentialId: String,
        publicKey: Data,
        contractId: String? = nil,
        deploymentStatus: OZCredentialDeploymentStatus = .pending,
        deploymentError: String? = nil,
        createdAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        lastUsedAt: Int64? = nil,
        nickname: String? = nil,
        isPrimary: Bool = false,
        transports: [String]? = nil,
        deviceType: String? = nil,
        backedUp: Bool? = nil
    )

    public func copyWith(/* every field, all nil-defaulted */) -> OZStoredCredential
    public func applyUpdate(_ updates: OZStoredCredentialUpdate) -> OZStoredCredential
}

public enum OZCredentialDeploymentStatus: String, Sendable, CaseIterable {
    case pending = "PENDING"
    case failed  = "FAILED"
    // No `success` case: a credential is deleted from storage on successful deployment,
    // so the only persistent states are PENDING and FAILED.
}

public struct OZStoredSession: Sendable, Equatable, Hashable {
    public let credentialId: String
    public let contractId: String
    public let connectedAt: Int64       // ms since epoch
    public let expiresAt: Int64         // ms since epoch
    public init(credentialId: String, contractId: String, connectedAt: Int64, expiresAt: Int64)
    public var isExpired: Bool          // now >= expiresAt
}

public struct OZStoredCredentialUpdate: Sendable, Equatable, Hashable {
    public let deploymentStatus: OZCredentialDeploymentStatus?
    public let deploymentError: String?
    public let contractId: String?
    public let lastUsedAt: Int64?
    public let nickname: String?
    public let isPrimary: Bool?
    public let transports: [String]?
    public let deviceType: String?
    public let backedUp: Bool?
    public init(/* every field, all nil-defaulted */)
}
```

`OZStoredCredential.transports` is the persisted copy of the WebAuthn transport hints captured at registration. It feeds `WebAuthnAllowCredential` construction for later `authenticate` ceremonies, which is what enables device-aware passkey selection (including the cross-device hybrid flow).

```swift
// WRONG: trying to clear a field via update with nil — nil means "no change", not "set to nil"
let u = OZStoredCredentialUpdate(nickname: nil)   // nickname stays whatever it was
// CORRECT: to reset a field, save a full replacement credential with the field explicitly nil
try await storage.save(credential: OZStoredCredential(
    credentialId: existing.credentialId,
    publicKey: existing.publicKey,
    nickname: nil
))
```

### `OZInMemoryStorageAdapter`

Tests and ephemeral / throwaway use only. Process-memory, not persistent, not encrypted. Every instance compares equal to every other (so two otherwise-equal `OZSmartAccountConfig` values that both default storage compare equal).

```swift
let storage = OZInMemoryStorageAdapter()  // the OZSmartAccountConfig default
```

Tests / ephemeral use only; inject a persistent adapter in production (see [Overview](#overview)).

---

## iOS

`AppleWebAuthnProvider` wraps `ASAuthorizationPlatformPublicKeyCredentialProvider` from `AuthenticationServices`. On iOS the system presents the passkey UI automatically — no presentation anchor is needed (that is a macOS requirement).

### Prerequisites

- iOS 16.0+ (the provider is gated `@available(iOS 16.0, *)`).
- Xcode 14+.
- An Apple Developer account with the **Associated Domains** capability enabled for the App ID.
- A domain you control, served over HTTPS, hosting `apple-app-site-association`.

### Swift Package Manager

`AppleWebAuthnProvider` needs no extra package — it uses the built-in `AuthenticationServices` framework. Add the SDK itself via SPM (`stellarsdk`) per the SDK's main installation instructions; no additional WebAuthn dependency is required.

### Construct `AppleWebAuthnProvider`

```swift
@available(iOS 16.0, macOS 13.0, *)
public final class AppleWebAuthnProvider: NSObject, WebAuthnProvider, @unchecked Sendable {
    public static let defaultTimeoutMs: Int64 = 60_000

    public let rpId: String
    public let rpName: String
    public let timeout: Int64    // ms; default AppleWebAuthnProvider.defaultTimeoutMs == 60000
    public var presentationContextProvider: ASAuthorizationControllerPresentationContextProviding?  // macOS-only

    public init(rpId: String, rpName: String, timeout: Int64 = AppleWebAuthnProvider.defaultTimeoutMs) throws
    public static func create(rpId: String, rpName: String, timeout: Int64 = AppleWebAuthnProvider.defaultTimeoutMs) throws -> AppleWebAuthnProvider
}
```

The initializer **throws**: `rpId` and `rpName` must be non-blank and `timeout` must be strictly positive, otherwise it throws a `SmartAccountConfigurationException.InvalidConfig` (the nested catchable class), constructed via the `.invalidConfig(details:)` factory. `create(...)` is an ergonomic alternative that performs identical validation.

```swift
let webAuthn = try AppleWebAuthnProvider(
    rpId: "wallet.example.com",
    rpName: "Example Smart Wallet"
)
// or: let webAuthn = try AppleWebAuthnProvider.create(rpId: "wallet.example.com", rpName: "Example Smart Wallet")
```

```swift
// WRONG: rpId = "https://wallet.example.com"
// CORRECT: rpId = "wallet.example.com"   — bare domain; the webcredentials: entitlement uses the same form.
```

On iOS, do **not** set `presentationContextProvider`; leave it `nil`. The system handles presentation.

`register()` on Apple platforms always returns `transports: ["internal"]` — the platform authenticator is the Secure Enclave / iCloud Keychain. The SDK persists these hints in `OZStoredCredential.transports` and, on a later sign, builds `WebAuthnAllowCredential` values carrying them. But Apple's credential descriptor (`ASAuthorizationPlatformPublicKeyCredentialDescriptor`) has no transport field, so `authenticate()` maps `allowCredentials` to credential IDs only — the hints are not forwarded at the OS boundary, and Apple drives hybrid / cross-device ("use a passkey on another device" QR) presentation itself. Pass transports through for portability; do not expect a `"hybrid"` hint to force the QR flow on Apple platforms.

### Associated Domains entitlement (Xcode)

1. Select the app target → **Signing & Capabilities** → **+ Capability** → **Associated Domains**.
2. Add the entry `webcredentials:wallet.example.com` (your RP domain).

For development against the iOS Simulator, append `?mode=developer` so the system fetches the AASA file directly from your origin instead of through Apple's CDN:

```
webcredentials:wallet.example.com?mode=developer
```

The compiled `.entitlements` fragment:

```xml
<key>com.apple.developer.associated-domains</key>
<array>
    <string>webcredentials:wallet.example.com?mode=developer</string>
</array>
```

Strip `?mode=developer` before Release — it bypasses Apple's CDN and can fail in the field; optionally enforce with a Release-only Run Script phase that fails the build if the built `.entitlements` still contains it. With manual signing, regenerate the provisioning profile after adding the capability, or the entitlement is silently dropped at install.

```xml
<!-- WRONG: scheme included -->
<string>webcredentials:https://wallet.example.com</string>
<!-- CORRECT: bare domain -->
<string>webcredentials:wallet.example.com</string>
```

### Host apple-app-site-association

Serve at the well-known URL (no `.json` extension on the path):

```
https://wallet.example.com/.well-known/apple-app-site-association
```

```json
{
  "webcredentials": {
    "apps": [
      "TEAM_ID.com.example.yourapp"
    ]
  }
}
```

Replace `TEAM_ID` with your Apple Developer Team ID (Apple Developer portal → Membership Details, or Xcode → Signing & Capabilities) and the bundle identifier with the host app's. Multiple bundle IDs (App Store + TestFlight) go in the same `apps` array.

Hosting requirements: HTTPS with a valid TLS certificate, `Content-Type: application/json`, no `.json` extension, no redirects.

```
WRONG: "apps": ["com.example.yourapp"]               — missing the Team ID prefix
CORRECT: "apps": ["TEAM_ID.com.example.yourapp"]      — team-prefixed application identifier
```

The `TEAM_ID.bundle.identifier` in the AASA file must exactly equal the team that signs the build. A mismatch fails AASA validation (surfaces as ASAuthorizationError 1004), even when the entitlement and file are otherwise correct.

### Storage adapters (iOS)

```swift
@available(iOS 13.0, macOS 10.15, *)
public final actor OZKeychainStorageAdapter: OZStorageAdapter {
    public static let defaultServiceName: String = "com.soneso.stellar.smartaccount"
    public init(serviceName: String = OZKeychainStorageAdapter.defaultServiceName, shim: OZSecItemShim = OZRealSecItemShim())
}

public final actor OZUserDefaultsStorageAdapter: OZStorageAdapter {
    public static let defaultSuiteName: String = "com.soneso.stellar.smartaccount"
    public init(suiteName: String = OZUserDefaultsStorageAdapter.defaultSuiteName) throws
}
```

- **`OZKeychainStorageAdapter`** — production storage backed by iOS Keychain Services with `kSecAttrAccessibleAfterFirstUnlock`. Survives reinstall (unless explicitly deleted) and can sync via iCloud Keychain. Override `serviceName` to scope isolated stores. The `shim` parameter exists for tests; production callers omit it.
- **`OZUserDefaultsStorageAdapter`** — scoped `UserDefaults(suiteName:)` storage. Suitable for non-production builds; **not encrypted at rest**. The initializer throws if `UserDefaults(suiteName:)` returns nil.
- **`OZInMemoryStorageAdapter`** — process-memory only; not for production.

See [Choosing an OZStorageAdapter](#choosing-an-ozstorageadapter) for the production-vs-test tradeoff.

```swift
let storage = OZKeychainStorageAdapter()                          // default service name
let storage = OZKeychainStorageAdapter(serviceName: "com.yourapp.stellar")  // or scope it
```

### Full kit initialization (iOS)

```swift
import stellarsdk

@available(iOS 16.0, *)
func buildKit() throws -> OZSmartAccountKit {
    let storage = OZKeychainStorageAdapter()
    let webAuthn = try AppleWebAuthnProvider(
        rpId: "wallet.example.com",
        rpName: "My Stellar App"
    )

    let config = try OZSmartAccountConfig(
        rpcUrl: "https://soroban-testnet.stellar.org",
        networkPassphrase: Network.testnet.passphrase,
        accountWasmHash: "<wasm-hash-hex>",
        webauthnVerifierAddress: "<verifier-c-address>",
        webauthnProvider: webAuthn,
        storage: storage
    )

    return OZSmartAccountKit.create(config: config)
}
```

### Troubleshooting (iOS)

- **`ASAuthorizationError` 1001 (canceled)** — User dismissed the sheet. Mapped to `WebAuthnException.Cancelled`. Surface as a neutral state and let the user retry.
- **`ASAuthorizationError` 1002 (invalid response)** — Usually transient; ask the user to retry. If persistent, check the device supports the requested credential parameters.
- **`ASAuthorizationError` 1004 (failed)** — AASA validation failed. Verify: the entitlement is present in the compiled `.app`; the AASA file is reachable as `application/json`; the provisioning profile includes Associated Domains; and during development the entitlement carries `?mode=developer`.
- **`ASAuthorizationError` 1003 (not supported)** — Target cannot handle passkeys (older OS or missing hardware). Mapped to `WebAuthnException.NotSupported`.
- **"Application is not associated with domain"** — AASA validation failure surfaced by `ASAuthorizationController`. Same checklist as 1004; switch to `?mode=developer` while iterating to bypass CDN caching.
- **Passkeys on the Simulator** — Supported from Xcode 14 / iOS 16. Use `?mode=developer` so the Simulator fetches the AASA file directly. Simulator passkeys are local-only (not iCloud-synced) and cannot produce attestation statements; the SDK requests no attestation, so this does not block any flow. A Simulator run without a provisioning profile needs `keychain-access-groups` to reach the Keychain (see [Storage adapters (macOS)](#storage-adapters-macos)).
- **First-install delay** — On device, Apple's CDN may take up to a minute to fetch the association file. Retry `register()` after a short wait, or use `?mode=developer`.
- **Credential not found on `authenticate()`** — No passkey exists for this `rpId` on the device. Create one first, or enable iCloud Keychain so a passkey synced from another device is available.

---

## macOS

`AppleWebAuthnProvider` is the same class as on iOS. The differences are signing constraints, entitlements, and a **required** presentation context.

### Prerequisites

- macOS 13.0+ (Ventura; the provider is gated `@available(iOS 16.0, macOS 13.0, *)`).
- Xcode 14+.
- An Apple Developer account.
- A domain you control, served over HTTPS, hosting `apple-app-site-association`.
- Developer ID signing, App Store signing, **or** the App Sandbox entitlement — Associated Domains is ignored without one.

### Swift Package Manager

Same as iOS — no extra WebAuthn package; `AppleWebAuthnProvider` uses `AuthenticationServices`.

### `presentationContextProvider` is required on macOS

Unlike iOS, `ASAuthorizationController` on macOS needs a presentation context to anchor the passkey sheet to an `NSWindow`. Without it the system fails with `ASAuthorizationError` code 1004. The property lives on `AppleWebAuthnProvider`:

```swift
public var presentationContextProvider: ASAuthorizationControllerPresentationContextProviding?
```

Assign it once at setup, before any registration or authentication call. The provider retains it strongly; do not manage its lifetime manually, and do not mutate it while a ceremony is in flight.

```swift
import stellarsdk
import AuthenticationServices
import AppKit

final class WindowPresentationProvider: NSObject,
    ASAuthorizationControllerPresentationContextProviding {

    func presentationAnchor(
        for controller: ASAuthorizationController
    ) -> ASPresentationAnchor {
        return NSApplication.shared.keyWindow
            ?? NSApplication.shared.windows.first
            ?? ASPresentationAnchor()
    }
}

let webAuthn = try AppleWebAuthnProvider(
    rpId: "wallet.example.com",
    rpName: "Example Smart Wallet"
)
webAuthn.presentationContextProvider = WindowPresentationProvider()
```

```swift
// WRONG (macOS): leaving presentationContextProvider unset
let webAuthn = try AppleWebAuthnProvider(rpId: "wallet.example.com", rpName: "My Wallet")
// register/authenticate fail with WebAuthnException.RegistrationFailed / AuthenticationFailed
// wrapping "Authenticator operation failed" (ASAuthorizationError 1004).
// CORRECT (macOS): set the anchor before any sign operation.
webAuthn.presentationContextProvider = WindowPresentationProvider()
```

### Associated Domains entitlement (Xcode)

1. Select the macOS app target → **Signing & Capabilities** → **+ Capability** → **Associated Domains**.
2. Add `webcredentials:wallet.example.com` (append `?mode=developer` for local development).
3. For sandboxed builds, also add **App Sandbox** and the network-client entitlement so the system can fetch the AASA file.

```xml
<!-- YourApp.entitlements -->
<key>com.apple.developer.associated-domains</key>
<array>
    <string>webcredentials:wallet.example.com?mode=developer</string>
</array>

<!-- Sandboxed builds: -->
<key>com.apple.security.app-sandbox</key>
<true/>

<!-- Network access for Soroban RPC / Horizon: -->
<key>com.apple.security.network.client</key>
<true/>
```

macOS signing notes:

- Associated Domains requires a **signed** app — Developer ID for distribution outside the Mac App Store, or App Store signing. Ad-hoc signed binaries fail the entitlement check.
- Strip `?mode=developer` for production.
- With manual signing, regenerate the provisioning profile after adding the capability.

### macOS developer-mode opt-in (critical)

macOS needs a per-machine opt-in before honoring the `?mode=developer` AASA fetch path for debug builds. Run once per development machine:

```
sudo swcutil developer-mode -e true
```

Without it, every passkey ceremony from a debug build returns `ASAuthorizationError` 1004 even when entitlement, AASA file, and signing are correct. The setting persists across reboots. Launch from Xcode with the debugger attached for `?mode=developer` to take effect.

```
WRONG: relying on ?mode=developer alone on macOS without the per-machine opt-in
  → every ceremony fails with code 1004.
CORRECT: run `sudo swcutil developer-mode -e true` once, then launch from Xcode.
```

### Host apple-app-site-association (macOS)

Same file and rules as iOS:

```
https://wallet.example.com/.well-known/apple-app-site-association
```

```json
{
  "webcredentials": {
    "apps": [
      "TEAM_ID.com.example.yourapp"
    ]
  }
}
```

A single domain can cover both an iOS and a macOS build — list both bundle identifiers in the `apps` array when Team ID matches. HTTPS, `application/json`, no `.json` extension, no redirects.

```
WRONG: testing macOS against http://localhost — macOS validates against a real DAL domain; there is no localhost exemption.
CORRECT: use a real staging domain, or mkcert + /etc/hosts for local development.
```

### Storage adapters (macOS)

`OZKeychainStorageAdapter` and `OZUserDefaultsStorageAdapter` are the same adapters as iOS. A signed app (including a sandboxed macOS app) reaches the Keychain via its default access group with no extra entitlement; only unsigned test binaries / CI need `keychain-access-groups` (fall back to `OZUserDefaultsStorageAdapter` there if it is constrained). Consider a distinct `serviceName` / `suiteName` on macOS to keep stores separate from an iOS companion app that shares the Bundle ID family.

```swift
let storage = OZKeychainStorageAdapter(serviceName: "com.yourapp.stellar.macos")
// or non-encrypted: try OZUserDefaultsStorageAdapter(suiteName: "com.yourapp.stellar.macos")
```

### Full kit initialization (macOS)

Identical to the [iOS kit init](#full-kit-initialization-ios) above, plus set `webAuthn.presentationContextProvider = anchorProvider` before any sign call (see [`presentationContextProvider` is required on macOS](#presentationcontextprovider-is-required-on-macos)).

### Troubleshooting (macOS)

macOS shares the [iOS troubleshooting table](#troubleshooting-ios); the macOS-only deltas:

- **`ASAuthorizationError` 1004** has two extra causes beyond AASA validation, check in order: (1) **no presentation anchor** — `presentationContextProvider` is nil or `presentationAnchor(for:)` returns a hidden/detached window; set it and return a visible `NSWindow`; (2) **developer mode not enabled** — `sudo swcutil developer-mode -e true` was not run, or the app launched from Finder instead of Xcode with the debugger.
- **Associated Domains ignored** — the system silently skips fetching AASA without Developer ID / App Store signing or App Sandbox. Enable App Sandbox (dev) or sign with Developer ID (distribution).
- **Passkeys synced from iOS missing** — verify iCloud Keychain is enabled on both devices, both are signed into the same Apple ID, and `rpId` matches exactly.
- **Keychain access in tests / CI** — if `OZKeychainStorageAdapter` throws unexpected `OSStatus`-derived `SmartAccountStorageException`s, the host is almost certainly an unsigned test binary / CI runner (or a Simulator run without a profile); see [Storage adapters (macOS)](#storage-adapters-macos) for the `keychain-access-groups` rule and fallback.

---

## Choosing an OZStorageAdapter

| Use case | iOS | macOS |
|----------|-----|-------|
| Production | `OZKeychainStorageAdapter` (encrypted, optional iCloud sync) | `OZKeychainStorageAdapter`, or `OZUserDefaultsStorageAdapter` per distribution constraints |
| Non-production / quick local builds | `OZUserDefaultsStorageAdapter` (public data only) | `OZUserDefaultsStorageAdapter` with a dedicated suite |
| Unit tests / ephemeral use (never in production) | `OZInMemoryStorageAdapter` | `OZInMemoryStorageAdapter` |

`OZStoredCredential` contains **public keys only**, so the bar is lower than for private-key storage — but session tokens and contract IDs are privacy-sensitive. Prefer Keychain in production.

---

## Implementing a custom OZStorageAdapter

Implement the protocol directly for unusual backends (an app-specific encrypted store, a server-side DB, etc.). The adapter must be a reference type (`AnyObject`) and `Sendable`; the simplest way to satisfy thread safety is an `actor`.

```swift
import stellarsdk

actor MyStorageAdapter: OZStorageAdapter {
    private var credentials: [String: OZStoredCredential] = [:]
    private var session: OZStoredSession?
    private let backend: MyEncryptedStore

    init(backend: MyEncryptedStore) { self.backend = backend }

    func save(credential: OZStoredCredential) async throws {
        do { try backend.upsert(credential) }
        catch { throw SmartAccountStorageException.writeFailed(key: credential.credentialId, cause: error) }
    }

    func get(credentialId: String) async throws -> OZStoredCredential? {
        do { return try backend.load(credentialId) }
        catch { throw SmartAccountStorageException.readFailed(key: credentialId, cause: error) }
    }

    func getByContract(contractId: String) async throws -> [OZStoredCredential] {
        try backend.all().filter { $0.contractId == contractId }
    }

    func getAll() async throws -> [OZStoredCredential] {
        try backend.all()
    }

    func delete(credentialId: String) async throws {
        try backend.remove(credentialId)   // no-op when absent
    }

    func update(credentialId: String, updates: OZStoredCredentialUpdate) async throws {
        guard let existing = try backend.load(credentialId) else {
            throw SmartAccountCredentialException.notFound(credentialId: credentialId)
        }
        try backend.upsert(existing.applyUpdate(updates))   // non-nil fields overwrite; nil = keep
    }

    func clear() async throws {
        try backend.removeAllCredentials()
        try backend.removeSession()        // clear() wipes credentials AND session
    }

    func saveSession(_ session: OZStoredSession) async throws {
        try backend.putSession(session)    // overwrites any prior session
    }

    func getSession() async throws -> OZStoredSession? {
        guard let s = try backend.loadSession() else { return nil }
        if s.isExpired {                   // expired => return nil AND clear
            try backend.removeSession()
            return nil
        }
        return s
    }

    func clearSession() async throws {
        try backend.removeSession()
    }
}
```

Contracts to satisfy:

- **Thread safety** — concurrent callers; an `actor` (as above) or explicit locking.
- **Upsert `save`** — overwrite on matching `credentialId`.
- **Partial `update`** — apply non-nil fields via `OZStoredCredential.applyUpdate(_:)`; never overwrite with nil; throw `SmartAccountCredentialException.notFound(credentialId:)` for unknown IDs.
- **`clear`** — remove all credentials AND the session.
- **Expired-session read** — `getSession()` returns nil when `OZStoredSession.isExpired`, and clears the stored row.
- **Errors** — wrap failures in `SmartAccountStorageException.readFailed(key:cause:)` / `SmartAccountStorageException.writeFailed(key:cause:)`.

---

## Implementing a custom WebAuthnProvider

Most apps use `AppleWebAuthnProvider`. Reasons to implement your own: a deterministic test double for CI, a hardware-key bridge, or a non-Apple authenticator.

`register()` and `authenticate()` must produce output the on-chain WebAuthn verifier can validate, which imposes strict format requirements:

| Field | Requirement |
|-------|-------------|
| `WebAuthnRegistrationResult.publicKey` | 65 bytes, uncompressed secp256r1 (`0x04 \|\| X(32) \|\| Y(32)`). If the platform returns COSE/SPKI/attestation, supply the raw bytes plus `attestationObject` and `SmartAccountUtils.extractPublicKeyFromRegistration` derives the key. |
| `WebAuthnRegistrationResult.credentialId` | Raw bytes. The SDK Base64URL-encodes for storage. |
| `WebAuthnRegistrationResult.attestationObject` | Raw CBOR object as delivered. Used by the SDK's fallback key extraction. |
| `WebAuthnAuthenticationResult.signature` | DER-encoded ECDSA P-256. The SDK normalizes to 64-byte compact low-S. Do **not** pre-normalize. |
| `WebAuthnAuthenticationResult.authenticatorData` | ≥ 37 bytes (`rpIdHash(32) + flags(1) + signCount(4) + …`). The UV flag must be set — the verifier rejects otherwise. Force user verification (`.required`). |
| `WebAuthnAuthenticationResult.clientDataJSON` | Must embed the SDK-provided `challenge` as base64url **without** padding, per the WebAuthn spec. |

```swift
import stellarsdk

final class MyCustomWebAuthnProvider: WebAuthnProvider, @unchecked Sendable {
    let rpId: String
    let rpName: String

    init(rpId: String, rpName: String) {
        self.rpId = rpId
        self.rpName = rpName
    }

    func register(
        challenge: Data,
        userId: Data,
        userName: String
    ) async throws -> WebAuthnRegistrationResult {
        // 1. Run a WebAuthn create ceremony against your stack, passing `challenge` as-is.
        // 2. Extract credentialId, the 65-byte uncompressed public key, and the attestation object.
        // 3. Optionally parse authenticator-data flags for deviceType / backedUp.
        return WebAuthnRegistrationResult(
            credentialId: Data(/* raw bytes */),
            publicKey: Data(/* 65 bytes: 0x04 + X + Y */),
            attestationObject: Data(/* CBOR */),
            transports: ["internal"],
            deviceType: "singleDevice",
            backedUp: false
        )
    }

    func authenticate(
        challenge: Data,
        allowCredentials: [WebAuthnAllowCredential]?
    ) async throws -> WebAuthnAuthenticationResult {
        // 1. Run a WebAuthn get ceremony, passing `challenge` as-is and forcing user verification.
        // 2. If allowCredentials is non-nil, constrain the picker to those IDs.
        // 3. Return the raw DER signature (no normalization here).
        return WebAuthnAuthenticationResult(
            credentialId: Data(/* selected credential ID */),
            authenticatorData: Data(/* >= 37 bytes, UV flag set */),
            clientDataJSON: Data(/* embeds challenge as base64url, no padding */),
            signature: Data(/* DER */)
        )
    }
}
```

Wrap native errors into `WebAuthnException.registrationFailed(reason:cause:)`, `WebAuthnException.authenticationFailed(reason:cause:)`, `WebAuthnException.cancelled(cause:)`, or `WebAuthnException.notSupported(details:cause:)` so the kit's error-handling paths work. Inject via the `webauthnProvider:` argument of `OZSmartAccountConfig(...)` exactly as you would `AppleWebAuthnProvider`. A custom provider does not need to deal with macOS presentation anchors — that requirement is specific to the `AuthenticationServices`-backed `AppleWebAuthnProvider`.

```swift
// WRONG: returning compressed secp256r1 (33 bytes) or bare X||Y (64 bytes) as publicKey.
// CORRECT: 65 bytes starting with 0x04, or supply attestationObject for SDK extraction.

// WRONG: clientDataJSON encoding the challenge with standard base64 (+ /, padding).
// CORRECT: base64url (- _) without padding — the WebAuthn spec.
```

---

## iOS / macOS setup checklist

| Step | iOS | macOS |
|------|-----|-------|
| Minimum OS | iOS 16.0 | macOS 13.0 (Ventura) |
| Choose `rpId` (bare domain, no scheme) | `wallet.example.com` | `wallet.example.com` |
| Publish `.well-known/apple-app-site-association` | required | required |
| App identifier in AASA `apps` | `TEAM_ID.bundle.id` | `TEAM_ID.bundle.id` |
| Xcode capability | Associated Domains `webcredentials:<rpId>` | Associated Domains `webcredentials:<rpId>` + App Sandbox / Developer ID |
| Development AASA fetch | `?mode=developer` on the entitlement | `?mode=developer` **and** `sudo swcutil developer-mode -e true` |
| Provider | `try AppleWebAuthnProvider(rpId:rpName:)` | `try AppleWebAuthnProvider(rpId:rpName:)` |
| Presentation anchor | not needed | **`presentationContextProvider` required** |
| Storage (production) | `OZKeychainStorageAdapter` | `OZKeychainStorageAdapter` |
| Inject into config | `OZSmartAccountConfig(…, webauthnProvider:, storage:)` | `OZSmartAccountConfig(…, webauthnProvider:, storage:)` |
| Localhost development | not supported | not supported |

After per-platform setup, every kit call is identical across iOS and macOS. See [smart_accounts.md](./smart_accounts.md) for kit operations and [smart_accounts_policies.md](./smart_accounts_policies.md) for signer, context-rule, policy, and multi-signer flows.
