# WebAuthn on iOS -- Setup Guide

Platform-specific guide for configuring WebAuthn passkey authentication in iOS applications using the Stellar SDK Smart Account Kit.

## Prerequisites

- iOS 16.0+ (the underlying `ASAuthorizationPlatformPublicKeyCredentialProvider` API is gated `@available(iOS 16.0, *)`).
- Xcode 14+.
- An Apple Developer account with the Associated Domains capability enabled for the App ID.
- A domain you control over HTTPS for hosting `apple-app-site-association`.

## Configure the kit

Construct `AppleWebAuthnProvider` with your relying-party `rpId` and `rpName`, then wire it into the config via `webauthnProvider`. The `rpId` and `rpName` are properties of `AppleWebAuthnProvider` — they are not fields on `OZSmartAccountConfig`.

```swift
import stellarsdk

let webAuthn = try AppleWebAuthnProvider(
    rpId: "wallet.example.com",
    rpName: "Example Smart Wallet"
)

let config = try OZSmartAccountConfig.builder(
    rpcUrl: "https://soroban-testnet.stellar.org",
    networkPassphrase: Network.testnet.passphrase,
    accountWasmHash: "your-wasm-hash-hex",
    webauthnVerifierAddress: "CB26VN37RCVNTHJZDEPK6IRO2MMTS3Z2IEO5JD5BINY2OOJ5KKJG7NKY"
)
    .webauthnProvider(webAuthn)
    .storage(KeychainStorageAdapter())
    .build()
```

The provider initializer is `throws` and validates that `rpId` and `rpName` are non-blank and that `timeout` (default 60_000 ms) is strictly positive. A `create(rpId:rpName:timeout:)` static factory is provided as an ergonomic alternative.

On iOS the system handles passkey UI presentation automatically; you do not need to assign a `presentationContextProvider`. (That property is required on macOS; see the macOS guide.)

## Add the Associated Domains entitlement (Xcode)

In Xcode:

1. Select the app target.
2. Open the **Signing & Capabilities** tab.
3. Click **+ Capability** and add **Associated Domains**.
4. Add the entry `webcredentials:wallet.example.com` (replace with your RP domain).

For development against the iOS Simulator, append the developer-mode flag so the system bypasses Apple's public AASA CDN and fetches the file directly from your origin:

```
webcredentials:wallet.example.com?mode=developer
```

The resulting `.entitlements` XML fragment looks like:

```xml
<key>com.apple.developer.associated-domains</key>
<array>
    <string>webcredentials:wallet.example.com?mode=developer</string>
</array>
```

Strip the `?mode=developer` suffix for production builds. If you use manual signing, regenerate the provisioning profile after adding the entitlement; the profile must include the Associated Domains capability or the entitlement is silently dropped at install time.

## Host the apple-app-site-association file

The RP domain must serve an AASA file at the well-known URL:

```
https://wallet.example.com/.well-known/apple-app-site-association
```

JSON template (note: no `.json` file extension on the URL):

```json
{
  "webcredentials": {
    "apps": [
      "TEAM_ID.com.example.yourapp"
    ]
  }
}
```

Replace `TEAM_ID` with your Apple Developer Team ID and `com.example.yourapp` with the host app's bundle identifier. Multiple bundle IDs (for example, an App Store build and a TestFlight build) go in the same `apps` array.

Hosting requirements:

- **HTTPS** with a valid TLS certificate.
- **Content-Type:** `application/json`.
- **No `.json` extension** on the URL.

Look up the Team ID via the Apple Developer Portal → **Membership Details**, or in Xcode → **Signing & Capabilities** under the target's signing details.

## Test on Simulator and Device

### iOS Simulator notes

The iOS Simulator supports passkeys from Xcode 14 / iOS 16 onward. With the `?mode=developer` suffix in the entitlement, the Simulator fetches the AASA file directly from your origin instead of going through Apple's developer CDN, which avoids CDN cache delays during development.

Caveats:

- Simulator passkeys are **local-only**; they are not synced via iCloud Keychain. Erase All Content and Settings deletes them.
- The Simulator still requires **network access** to fetch the AASA file even with developer mode enabled.
- Simulator authenticators cannot produce attestation statements. The SDK requests no attestation on registration, so this does not block any flow.

### Device testing

On device, the system fetches and caches the AASA file via Apple's CDN. After publishing a new AASA file, allow several minutes for the CDN cache to update, or temporarily switch the entitlement to `?mode=developer` to bypass the cache.

Devices that lack a biometric authenticator (Face ID / Touch ID) fall back to the device passcode for user verification. The WebAuthn verifier requires `UV=true`, so passcode verification is treated equivalently to biometrics on the contract side.

## Custom WebAuthn provider

If you need to integrate a non-Apple authenticator (for example, an in-process mock for unit tests, or a hardware security key bridge), implement the `WebAuthnProvider` protocol directly:

```swift
public protocol WebAuthnProvider: Sendable {
    func register(
        challenge: Data,
        userId: Data,
        userName: String
    ) async throws -> WebAuthnRegistrationResult

    func authenticate(
        challenge: Data,
        allowCredentials: [AllowCredential]?
    ) async throws -> WebAuthnAuthenticationResult
}
```

Required semantics:

- **`register`**: perform a WebAuthn create ceremony with the supplied `challenge`. Generate a secp256r1 keypair, return the credential ID, the raw 65-byte SEC1 public key (or a CBOR attestation object that the SDK can extract one from), and the raw attestation object bytes. The challenge must be used as-is.
- **`authenticate`**: perform a WebAuthn get ceremony with the supplied `challenge`. Sign with the selected credential and return the credential ID, raw authenticator data, raw client data JSON, and the DER-encoded ECDSA signature. The WebAuthn verifier requires `UV=true`, so force user verification.

Pass the conformance through `OZSmartAccountConfig.webauthnProvider` exactly as you would `AppleWebAuthnProvider`.

## Storage Adapters

Use `KeychainStorageAdapter` for production; `UserDefaultsStorageAdapter` and `InMemoryStorageAdapter` are for non-sensitive or test-only use. See the [Storage trade-offs](README.md#storage-trade-offs) table in the kit guide for the full comparison.

## Common errors

### `ASAuthorizationError` code 1001 (canceled)

The user dismissed the passkey prompt. `AppleWebAuthnProvider` maps this to `WebAuthnException.Cancelled`. Treat as a normal user-cancel; re-display the trigger UI and let the user retry.

### `ASAuthorizationError` code 1002 (invalid response)

Invalid response from the authenticator. Usually transient; ask the user to retry. If persistent, check that the device supports the requested credential parameters.

### `ASAuthorizationError` code 1004 (failed)

Indicates AASA validation failed. Verify (a) the entitlement is present in the compiled `.app`, (b) the AASA file is reachable as `application/json`, (c) the provisioning profile includes the Associated Domains capability, and (d) in development, the entitlement uses `?mode=developer`.

### `ASAuthorizationError` code 1003 (not supported)

The platform reports that the requested operation cannot be handled. Most commonly this means running on a target that does not support passkeys (older OS or a device without the required hardware). The SDK maps this to `WebAuthnException.NotSupported`.

### "Application is not associated with domain"

A surface error from `ASAuthorizationController` indicating AASA validation failed. Same checklist as 1004; typically the AASA file is missing, served with the wrong content type, or the CDN has not yet picked up changes. Switch to `?mode=developer` while iterating.

## Rotation and credential lifetime

A passkey is permanently bound to the RP ID it was registered against. There is no rebind operation; changing the `rpId` invalidates every existing credential for that account. Treat the RP domain as a long-lived identifier and pick one you control across the expected lifetime of the wallet.

Credentials sync via iCloud Keychain when the user is signed in to iCloud and has Keychain sync enabled. On a fresh device, the user can authenticate as soon as iCloud delivers the credential; plan for the case where the credential has not yet arrived when offline.

## Full Kit Initialization

```swift
import stellarsdk

let storage = KeychainStorageAdapter()
let webAuthnProvider = try AppleWebAuthnProvider(
    rpId: "wallet.example.com",
    rpName: "My Stellar App"
)

let config = try OZSmartAccountConfig.builder(
    rpcUrl: "https://soroban-testnet.stellar.org",
    networkPassphrase: Network.testnet.passphrase,
    accountWasmHash: "<wasm-hash-hex>",
    webauthnVerifierAddress: "<verifier-c-address>"
)
.webauthnProvider(webAuthnProvider)
.storage(storage)
.build()

let kit = OZSmartAccountKit.create(config: config)
```
