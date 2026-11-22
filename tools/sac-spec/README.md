# SAC spec generator

A Stellar Asset Contract (SAC) is built into the network, so no wasm on chain carries its contract spec. The SDK embeds the spec instead: `generate_sac_spec.py` takes the spec file of a pinned upstream commit, checks its sha256, and writes it as base64 into `stellarsdk/stellarsdk/soroban/contract/SACSpec.swift`. `SACClient.specEntries()` decodes the embedded bytes.

The script is language neutral. Everything specific to this repository is in two files:

- `pin.json` names the upstream `repository`, the `commit`, the `file`, the `sha256` of that file, the `template`, and the `output`. The template and output paths are relative to the repository root.
- `SACSpec.swift.template` is the output with placeholders: `{{REPOSITORY}}`, `{{FILE}}`, `{{COMMIT}}`, `{{SHA256}}`, `{{SIZE}}` (the byte count), and `{{BASE64}}` (standard base64 on one line).

The output is generated and never edited by hand. It carries no timestamp, so a run at the same pin reproduces it byte for byte.

## Prerequisites

Python 3.9 or later; the script uses the standard library only. A run without `--source` needs network access to `raw.githubusercontent.com`.

## Running

From the repository root:

```sh
python3 tools/sac-spec/generate_sac_spec.py
```

Options:

- `--pin PATH`: the pin file. Default: `pin.json` beside the script.
- `--root DIR`: the directory the pin's `template` and `output` paths resolve against. Default: two directories above the script, the repository root.
- `--source FILE`: a local copy of the spec file, read in place of the download.

The script downloads `https://raw.githubusercontent.com/<repository>/<commit>/<file>` with a 60-second timeout, writes the output through a temporary file, and exits 0. It exits 1 and writes nothing when:

- the pin is unreadable, lacks a key, or its `commit` is not 40 or its `sha256` not 64 lowercase hex characters
- the download or a file read fails; the message names the URL or the path and the cause
- the sha256 of the spec bytes differs from the pin; the message shows both digests
- the template holds a placeholder the script does not know

## Tests

```sh
python3 -m unittest discover -s tools/sac-spec/tests
```

The tests run offline on temporary directories. They also check that the committed `SACSpec.swift` carries the pin's commit and sha256 and that its base64 has that sha256.

## Moving the pin

1. Set `commit` in `pin.json` to the new upstream commit and `sha256` to the sha256 of the spec file at that commit.
2. Run the generator.
3. Run `swift test --filter stellarsdkUnitTests`.

`stellarsdk/stellarsdkUnitTests/soroban/SACSpecUnitTests.swift` asserts the pinned commit, the sha256, the size, and the names of the contract's functions and events. A new pin, or a changed function or event set, fails it until the same commit updates its expected values.
