#!/usr/bin/env bash
#
# Regenerates the SEP-0051 conformance corpus into a scratch directory and diffs
# it against the committed corpus.json.
#
# Usage:
#   refresh_corpus.sh              Check the committed corpus against the pinned build.
#   refresh_corpus.sh --advisory   Check it against whatever build is on PATH instead,
#                                  for comparing a new reference release. Reports only;
#                                  the committed corpus is never written either way.
#
# Exit codes:
#   0  the committed corpus matches a fresh generation
#   1  drift: the diff is printed
#   2  a prerequisite is missing (reference CLI absent, or not matching the pin outside
#      advisory mode)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TMP_DIR="$SCRIPT_DIR/.tmp"
# SwiftPM resolves a `.copy` resource relative to its target directory and rejects a
# path that escapes it, so the committed corpus sits inside the unit-test target and
# is read through `Bundle.module`. Only the scratch copy lives beside this script.
COMMITTED="$REPO_ROOT/stellarsdk/stellarsdkUnitTests/sep/xdr_json/corpus.json"

ADVISORY=""
if [ "${1:-}" = "--advisory" ]; then
  ADVISORY="--advisory"
fi

# Separate scratch files, so an advisory result is never mistaken for a pinned one.
if [ -n "$ADVISORY" ]; then
  FRESH="$TMP_DIR/advisory-corpus.json"
else
  FRESH="$TMP_DIR/corpus.json"
fi

mkdir -p "$TMP_DIR"

python3 "$SCRIPT_DIR/generate_corpus.py" $ADVISORY --output "$FRESH"
status=$?
if [ "$status" -eq 2 ]; then
  exit 2
fi
if [ "$status" -ne 0 ] && [ -z "$ADVISORY" ]; then
  echo "refresh_corpus.sh: generation failed" >&2
  exit "$status"
fi
# In advisory mode a non-zero status means findings were recorded, not that the run failed.
# The diff below is the other half of the report, so it still has to be produced; a seed the
# build could not process contributes an omitted entry that the diff makes visible.
if [ "$status" -ne 0 ] && [ ! -f "$FRESH" ]; then
  echo "refresh_corpus.sh: generation produced no document" >&2
  exit 1
fi

if [ ! -f "$COMMITTED" ]; then
  echo "refresh_corpus.sh: $COMMITTED does not exist; copy $FRESH into place." >&2
  exit 1
fi

LEFT="$COMMITTED"
RIGHT="$FRESH"

if [ -n "$ADVISORY" ]; then
  # Compare renderings, not provenance. An advisory document honestly records the build that
  # produced it, so reference_version and reference_xdr_commit differ on every real release
  # and would drown out the question being asked: does anything this SDK emits change?
  # entry_count stays in the comparison, because a dropped seed is a real difference.
  NORM_LEFT="$TMP_DIR/committed-normalised.json"
  NORM_RIGHT="$TMP_DIR/advisory-normalised.json"
  if ! python3 - "$COMMITTED" "$NORM_LEFT" "$FRESH" "$NORM_RIGHT" <<'NORMALISE'
import json
import sys

PROVENANCE = ("reference_version", "reference_xdr_commit")

for source, target in ((sys.argv[1], sys.argv[2]), (sys.argv[3], sys.argv[4])):
    with open(source) as handle:
        document = json.load(handle)
    for field in PROVENANCE:
        if field in document.get("metadata", {}):
            document["metadata"][field] = "<ignored in advisory comparison>"
    with open(target, "w") as handle:
        json.dump(document, handle, ensure_ascii=False, indent=2, sort_keys=False)
        handle.write("\n")
NORMALISE
  then
    echo "refresh_corpus.sh: could not normalise the documents for comparison" >&2
    exit 2
  fi
  LEFT="$NORM_LEFT"
  RIGHT="$NORM_RIGHT"
fi

# In advisory mode the generation itself may already have reported findings; the diff
# below is the enumeration of what the new build renders differently.
if diff -u -L "$COMMITTED" -L "$FRESH" "$LEFT" "$RIGHT"; then
  if [ -n "$ADVISORY" ] && [ "$status" -ne 0 ]; then
    echo "ADVISORY: renderings match, but the run reported findings above." >&2
    exit 1
  fi
  if [ -n "$ADVISORY" ]; then
    echo "ADVISORY: every corpus rendering is unchanged under this build."
  else
    echo "No drift: corpus.json matches a fresh generation."
  fi
  exit 0
fi

echo "" >&2
if [ -n "$ADVISORY" ]; then
  echo "ADVISORY: this build renders the corpus differently from the committed file." >&2
  echo "  The diff above is the change; nothing has been written." >&2
  exit 1
fi
echo "refresh_corpus.sh: corpus.json is out of date." >&2
echo "  Regenerate it with: python3 $SCRIPT_DIR/generate_corpus.py" >&2
echo "  corpus.json is the single editable source: the unit tests read the committed" >&2
echo "  file through Bundle.module, so nothing is emitted from it and no further" >&2
echo "  regeneration step follows." >&2
exit 1
