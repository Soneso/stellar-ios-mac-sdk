# Contributing to the iOS Stellar SDK

Thank you for helping to improve the SDK. This guide covers bug reports, feature proposals, setup and the pull request process. The commands, the definition of done and the repository rules are in `AGENTS.md`.

## Reporting a bug

Open a bug report issue; the template asks for what you did, what happened, what you expected, the SDK version, the Xcode or Swift version, and the platform. A failing test or a short snippet that reproduces the behavior shortens the fix.

## Proposing a feature

Open a feature request issue and describe the use case and the proposed behavior. For a SEP or a protocol feature, name the specification. Discuss before writing a large change, so the design is settled before the code.

## Setting up

- Xcode as `README.md` states it, with the Swift tools version in `Package.swift`. The package builds and tests from the command line; the Commands section of `AGENTS.md` has the commands, including the filter that runs the unit suite without the long integration suite. Opening `Package.swift` in Xcode works as well.
- For the XDR generator: Docker, or Ruby with Bundler for the setup without Docker; a cold run needs network for the image and the gems. For the SEP-51 tools: Ruby with the generator's gems, Python 3, and Rust's cargo for the pinned reference CLI. For the compatibility matrices: Python 3 and network; a GitHub token raises the API rate limit. Each tool's README under `tools/` names its requirements.

Run the unit suite as `AGENTS.md` describes before you change anything, so you know the baseline is green on your machine.

## Submitting a change

1. Fork the repository and branch from `master` with a short kebab-case name that names the change.
2. Make the change with its tests. A bug fix starts with a test that fails before the fix.
3. Add an entry under `[Unreleased]` in `CHANGELOG.md`, in the section the change belongs to.
4. Run the gates listed under "Definition of done" in `AGENTS.md`.
5. Commit with an imperative subject and a body that states the motivation and what the change does. Open the pull request against `master` and describe what you verified.

The user documentation under `docs/` and the skill under `skills/` describe the released SDK and are updated on the `release-docs` branch with the release; a pull request does not change them. Describe the needed documentation change in the pull request, and the maintainer adds it on that branch. `docs/documentation-strategy.md`, `AGENTS.md` and this file are process documents: change them in the pull request that changes a fact they state. A documentation example that your change affects has a test under the integration test target; change that test in the same pull request.

## What the review checks

- The change does what the pull request says, and nothing else.
- The tests fail without the change and pass with it; unit tests mock HTTP.
- The conventions in `AGENTS.md`: typed API, `Sendable` types, documentation comments on public declarations, the error and response conventions of the API you extend.
- The CHANGELOG entry; no hand edits to generated files; no change to the user documentation or the skill.

CI runs the unit suite with coverage on a macOS runner; the Codecov project status must pass.

## Questions

Use GitHub Discussions for questions about using the SDK or about a change you plan.
