#!/usr/bin/env bash
#
# Print the SEP-0051 XDR-JSON reference rendering of a single XDR value.
#
# Usage:
#   probe.sh <TYPE> <BASE64>     Decode one base64 value and print its XDR-JSON.
#   probe.sh --schema <TYPE>     Print the JSON schema for a type.
#   probe.sh --types             List every type the reference CLI knows.
#   probe.sh --check             Verify the reference CLI matches the pin and exit.
#
# TYPE is the reference CLI's own spelling (ScVal, PoolId, SError), not this SDK's
# (SCValXDR, PoolIDXDR, ErrorXDR). The two differ in acronym casing, in the
# reserved-name escape and in this SDK's XDR suffix, so guessing one from the
# other fails. name_map.rb writes the mapping to type_map.json.
#
# The reference build is pinned in oracle-pin.json and verified on every run:
# XDR-JSON key spellings differ between reference releases, so a probe taken from
# an unpinned build is not evidence about the current spec.
#
# Set STELLAR_XDR to point at a different binary; PATH is used otherwise.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PIN_FILE="$SCRIPT_DIR/oracle-pin.json"
CLI="${STELLAR_XDR:-stellar-xdr}"

die() {
  echo "probe.sh: $*" >&2
  exit 2
}

json_field() {
  python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))[sys.argv[2]])' "$PIN_FILE" "$1"
}

# The header comment block is the usage text, so the two never drift apart.
usage() {
  awk 'NR == 1 { next } /^#/ { sub(/^# ?/, ""); print; next } { exit }' "${BASH_SOURCE[0]}"
}

# Usage is answerable without the reference CLI, so it is dispatched before the
# checks that need one.
case "${1:-}" in
  "" | -h | --help)
    usage
    exit 0
    ;;
esac

[ -f "$PIN_FILE" ] || die "missing pin file: $PIN_FILE"

if ! command -v "$CLI" >/dev/null 2>&1 && [ ! -x "$CLI" ]; then
  die "reference CLI '$CLI' not found. Install it with:
    $(json_field install)
  then ensure it is on PATH (cargo installs into ~/.cargo/bin), or set STELLAR_XDR."
fi

# `version` prints the tool version on line 1 and the vendored xdr commit on line 2.
verify_pin() {
  local want_version want_xdr got_version got_xdr version_line
  want_version="$(json_field version)"
  want_xdr="$(json_field xdr_commit)"

  local out
  out="$("$CLI" version 2>/dev/null)" || die "'$CLI version' failed; is '$CLI' the XDR reference CLI?"

  version_line="$(printf '%s\n' "$out" | head -1)"
  got_version="$(printf '%s\n' "$version_line" | awk '{print $2}')"
  got_xdr="$(printf '%s\n' "$out" | awk '/^xdr:/ {print $2}')"

  if [ "$got_version" != "$want_version" ] || [ "$got_xdr" != "$want_xdr" ]; then
    die "reference CLI does not match the pin.
    want: version $want_version, xdr $want_xdr
    got:  version ${got_version:-unknown}, xdr ${got_xdr:-unknown}
  Install the pinned build with:
    $(json_field install)
  If the pin is being deliberately advanced, update oracle-pin.json and re-run
  'ruby name_map.rb --diff' before trusting any probe from the new build."
  fi
}

verify_pin

case "${1:-}" in
  --check)
    echo "reference CLI matches the pin: $("$CLI" version | head -1)"
    ;;
  --types)
    "$CLI" types list
    ;;
  --schema)
    [ $# -eq 2 ] || die "usage: probe.sh --schema <TYPE>"
    "$CLI" types schema --type "$2"
    ;;
  *)
    [ $# -eq 2 ] || die "usage: probe.sh <TYPE> <BASE64>"
    printf '%s' "$2" | "$CLI" decode --type "$1" --input single-base64 --output json
    ;;
esac
