# WebAuthn on macOS -- Setup Guide

Platform-specific guide for configuring WebAuthn passkey authentication in macOS applications using the Stellar SDK Smart Account Kit.

## Prerequisites

- macOS 13.0+ (Ventura; the underlying `ASAuthorizationPlatformPublicKeyCredentialProvider` API is gated `@available(macOS 13.0, *)`).
- Xcode 14+.
- An Apple Developer account.
- A domain you control over HTTPS for hosting `apple-app-site-association`.
- Developer ID signing, App Store signing, or the App Sandbox entitlement for Associated Domains.

## Configure the kit

Construct `AppleWebAuthnProvider` with your relying-party `rpId` and `rpName`, assign a `presentationContextProvider` (required on macOS), then wire the provider into the config via `webauthnProvider`. The `rpId` and `rpName` are properties of `AppleWebAuthnProvider` — they are not fields on `OZSmartAccountConfig`.

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

Set `presentationContextProvider` once at setup time and leave it assigned. The provider retains it strongly; you do not need to manage the lifetime explicitly. Mutating the property while a ceremony is in flight is not supported.

## Add the Associated Domains entitlement (Xcode)

In Xcode:

1. Select the macOS app target.
2. Open the **Signing & Capabilities** tab.
3. Click **+ Capability** and add **Associated Domains**.
4. Add the entry `webcredentials:wallet.example.com` (replace with your RP domain).

For development, append the developer-mode flag so the system bypasses Apple's public AASA CDN and fetches the file directly from your origin:

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

Strip the `?mode=developer` suffix for production builds.

macOS signing notes:

- Associated Domains requires the app to be **signed**, either with a Developer ID for distribution outside the Mac App Store, or with App Store signing. Ad-hoc signed binaries fail the entitlement check.
- Sandboxed apps need `com.apple.security.app-sandbox` enabled with appropriate network entitlements so the system can fetch the AASA file on launch.
- If you use manual signing, regenerate the provisioning profile after adding the entitlement.

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

Replace `TEAM_ID` with your Apple Developer Team ID and `com.example.yourapp` with the host app's bundle identifier. If a single domain hosts both an iOS and a macOS variant of the same wallet, list both bundle identifiers in the `apps` array.

Hosting requirements:

- **HTTPS** with a valid TLS certificate.
- **Content-Type:** `application/json`.
- **No `.json` extension** on the URL.

Look up the Team ID via the Apple Developer Portal → **Membership Details**, or in Xcode → **Signing & Capabilities** under the target's signing details.

## Test on Device

macOS does not have a Simulator; testing happens on the development machine itself. With the `?mode=developer` suffix in the entitlement, the system fetches the AASA file directly from your origin instead of going through Apple's developer CDN.

### macOS developer-mode requirement (critical)

macOS requires an explicit, per-machine opt-in before the system will honour the `?mode=developer` AASA fetch path for debug builds. Run this once on each development machine:

```
sudo swcutil developer-mode -e true
```

Without this opt-in, every passkey ceremony from a debug build returns `ASAuthorizationError` code 1004 even when the entitlement, AASA file, and signing are all correct. The setting persists across reboots. Launch from Xcode with the debugger attached for `?mode=developer` to take effect.

### macOS presentation anchor (required)

Unlike iOS, macOS requires `ASAuthorizationController` to know which window should display the passkey sheet. See the **Configure the kit** section above for the `presentationContextProvider` assignment; failing to wire it is the most common cause of code 1004 on macOS.

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

Pass the conformance through `OZSmartAccountConfig.webauthnProvider` exactly as you would `AppleWebAuthnProvider`. A custom conformance does not need to deal with macOS presentation anchors; that requirement is specific to the `AuthenticationServices`-backed provider.

## Storage Adapters

Use `KeychainStorageAdapter` for production; `UserDefaultsStorageAdapter` and `InMemoryStorageAdapter` are for non-sensitive or test-only use. See the [Storage trade-offs](README.md#storage-trade-offs) table in the kit guide for the full comparison.

macOS specific: sandboxed apps may need `com.apple.security.keychain-access-groups` for Keychain access. Use `UserDefaultsStorageAdapter` if this is constrained.

## Common errors

### `ASAuthorizationError` code 1001 (canceled)

The user dismissed the passkey prompt. `AppleWebAuthnProvider` maps this to `WebAuthnException.Cancelled`. Treat as a normal user-cancel; re-display the trigger UI and let the user retry.

### `ASAuthorizationError` code 1002 (invalid response)

Invalid response from the authenticator. Usually transient; ask the user to retry. If persistent, check that the device supports the requested credential parameters.

### `ASAuthorizationError` code 1004 (failed)

On macOS this code has three distinct common causes; check them in order:

1. **No presentation anchor.** `presentationContextProvider` is `nil`, or the `presentationAnchor(for:)` callback returns a hidden or detached window. Set the property before invoking any flow and return a visible `NSWindow`.
2. **Developer mode not enabled.** The machine has not had `sudo swcutil developer-mode -e true` run on it, or the app was launched from Finder rather than from Xcode with the debugger attached.
3. **AASA validation failed.** The `Associated Domains` entitlement is missing or misconfigured, the AASA file is unreachable, the file does not list your exact `TEAM_ID.bundle.identifier`, or the provisioning profile does not include the Associated Domains capability.

### `ASAuthorizationError` code 1003 (not supported)

The platform reports that the requested operation cannot be handled. On macOS this usually indicates an unsupported OS version or a configuration that disables passkey use. The SDK maps this to `WebAuthnException.NotSupported`.

### "Application is not associated with domain"

A surface error from `ASAuthorizationController` indicating AASA validation failed. On macOS the most likely cause is that developer mode is not enabled and the AASA file is not yet served from the public CDN. Enable developer mode and confirm Xcode-launched runs.

## Rotation and credential lifetime

A passkey is permanently bound to the RP ID it was registered against. There is no rebind operation; changing the `rpId` invalidates every existing credential for that account. Treat the RP domain as a long-lived identifier and pick one you control across the expected lifetime of the wallet.

Credentials sync via iCloud Keychain when the user is signed in to iCloud and has Keychain sync enabled. A passkey registered on a Mac is then available on the user's iPhone, iPad, and other Macs signed in to the same Apple ID, as long as the same RP ID is configured on each platform.

## Full Kit Initialization

```swift
import stellarsdk

let storage = KeychainStorageAdapter()
let webAuthnProvider = try AppleWebAuthnProvider(
    rpId: "wallet.example.com",
    rpName: "My Stellar App"
)
webAuthnProvider.presentationContextProvider = WindowPresentationProvider()

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
