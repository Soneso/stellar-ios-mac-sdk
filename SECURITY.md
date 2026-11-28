# Security policy

## Reporting a vulnerability

Report a vulnerability privately through [GitHub's private vulnerability reporting](https://github.com/Soneso/stellar-ios-mac-sdk/security/advisories/new). The form is also under **Report a vulnerability** in the repository's **Security and quality** tab. Do not open a public issue or pull request for a vulnerability.

Include:

- the affected SDK version
- the platform or runtime
- a description of the vulnerability
- safe reproduction steps or a minimal proof of concept
- the impact

Leave private keys, secret seeds, tokens, and personal data out of the report.

## What happens next

The maintainer acknowledges each report within 2 business days, assesses it, and tells the reporter the result. A vulnerability the maintainer confirms is fixed in a new release. The maintainer coordinates disclosure with the reporter and publishes a GitHub security advisory when the fixed release is available. Until then, keep the details private. With the reporter's consent, the advisory credits them.

## Supported versions

Only the latest stable release receives security fixes. Older releases get no backports, and prereleases are not supported.

## Scope

This policy covers vulnerabilities in the SDK code of this repository. Report a vulnerability in a dependency to that project, and here as well when it affects users of the SDK. Report a vulnerability in the Stellar network or protocol to the [Stellar Development Foundation's bug bounty program](https://stellar.org/grants-and-funding/bug-bounty).
