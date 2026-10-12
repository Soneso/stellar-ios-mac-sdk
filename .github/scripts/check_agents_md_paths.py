#!/usr/bin/env python3
"""Check repository paths in root AGENTS.md with exact case on every filesystem.

Usage: check_agents_md_paths.py [-v] [REPO_ROOT]
The default root is two directories above this script; all checks use that
root regardless of the current directory. Exit 0 without failures, 1 with
failures, or 2 for missing AGENTS.md, a non-work-tree root or unavailable git.

Fences have up to three leading spaces and at least three backticks or
tildes. Backtick info strings cannot contain backticks. Closers use the same
character, at least the opening length, and only spaces or tabs afterwards.
Outside fences, equal-length backtick runs delimit spans without crossing
blank lines. Backslashes escape characters outside spans, but are literal
inside. Unmatched runs are literal. Spans retain their opening line number.

Skip spans containing whitespace, $, <, >, a backslash, ..., ://, X.Y.Z or
YYYY, or starting with ~, -, @ or /. Normalize one leading ./ and dot
components before classification and existence checks. Dot-prefixed names
are skipped unless their first segment is a root entry or .github,
.gitignore or .claude. Other single words are skipped unless root entries
or ending in .md, .yml or .yaml. Spans starting with ./ are exempt from the
single-word skip. Parent components always warn when checked.

Globs containing *, ? or [ pass with an exact-case match using root_dir.
Other paths pass on exact-case existence; a trailing slash requires a
directory. Missing paths pass if git check-ignore accepts the original span,
including its slash. Other misses fail for root files or existing first
segments, and otherwise warn that they are not repository paths.

Print FAIL and WARN lines; -v also prints SKIP reasons and PASS reasons
(exists, ignored by git, glob matches). End with checked, failed and warned
counts, excluding skipped spans from checked.
"""

import argparse
import glob
import os
import re
import subprocess
import sys

NOT_PATH_SUBSTRINGS = ("$", "<", ">", "\\", "...", "://", "X.Y.Z", "YYYY")
DOCUMENT_SUFFIXES = (".md", ".yml", ".yaml")
DOT_ROOT_NAMES = {".github", ".gitignore", ".claude"}
FENCE = re.compile(r"^ {0,3}(`{3,}|~{3,})(.*)$")
RUN = re.compile(r"`+")


def code_spans(markdown):
    """Yield opening line numbers and contents of inline spans outside fences."""
    lines = markdown.split("\n")
    fence = None
    for index, line in enumerate(lines):
        match = FENCE.match(line)
        if fence is not None:
            if (match and match[1][0] == fence[0] and len(match[1]) >= len(fence)
                    and not match[2].strip(" \t")):
                fence = None
            lines[index] = ""
        elif match and (match[1][0] == "~" or "`" not in match[2]):
            fence = match[1]
            lines[index] = ""
    text = "\n".join(lines)
    cursor = 0
    while cursor < len(text):
        if text[cursor] == "\\":
            cursor += 2
            continue
        opening = RUN.match(text, cursor)
        if not opening:
            cursor += 1
            continue
        closing = re.search(r"(?<!`)`{" + str(len(opening[0])) + r"}(?!`)|\n[ \t]*\n",
                            text[opening.end():])
        if closing and closing[0].startswith("`"):
            end = opening.end() + closing.start()
            yield text.count("\n", 0, cursor) + 1, text[opening.end():end]
            cursor = opening.end() + closing.end()
        else:
            cursor = opening.end()


def normalize(span):
    """Remove leading ./ and dot components while retaining a directory slash."""
    path = "/".join(part for part in span.removeprefix("./").split("/") if part not in ("", "."))
    return path + ("/" if path and span.endswith("/") else "")


def skip_reason(span, path, root_entries):
    """Return a skip reason for a non-path span, or None when it is checked."""
    if any(char.isspace() for char in span):
        return "contains whitespace"
    for part in NOT_PATH_SUBSTRINGS:
        if part in span:
            return f"contains {part!r}"
    if span.startswith(("~", "-", "@", "/")):
        return f"starts with {span[0]!r}"
    if ".." in path.split("/"):
        return None
    first = path.split("/")[0]
    if path.startswith(".") and first not in root_entries | DOT_ROOT_NAMES:
        return "dot-prefixed token, not a root entry"
    if (not span.startswith("./") and "/" not in path and not path.endswith(DOCUMENT_SUFFIXES)
            and path not in root_entries):
        return "single word, not a root entry"
    return None


def exists_exact(root, relative):
    """Return whether each path segment exists with exactly the requested case."""
    path = root
    for part in filter(None, relative.rstrip("/").split("/")):
        if not os.path.isdir(path) or part not in os.listdir(path):
            return False
        path = os.path.join(path, part)
    return True


def git_ignores(root, span):
    """Return whether git ignores the span as written, including its slash."""
    return subprocess.run(["git", "check-ignore", "-q", "--", span], cwd=root,
                          stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                          check=False).returncode == 0


def verdict(root, span, path, root_entries):
    """Return the PASS, FAIL or WARN level and its explanation."""
    if ".." in path.split("/"):
        return "WARN", "not a repository path"
    if any(char in path for char in "*?["):
        if any(exists_exact(root, match) for match in glob.glob(path, root_dir=root)):
            return "PASS", "glob matches"
        return "FAIL", "glob matches no path"
    if exists_exact(root, path.rstrip("/")):
        if path.endswith("/") and not os.path.isdir(os.path.join(root, path.rstrip("/"))):
            return "FAIL", "a file, not a directory"
        return "PASS", "exists"
    if git_ignores(root, span):
        return "PASS", "ignored by git"
    if "/" not in path or path.split("/")[0] in root_entries:
        return "FAIL", "no such path"
    return "WARN", "not a repository path"


def main(argv=None):
    """Check the selected repository and return its failure status."""
    default_root = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
    parser = argparse.ArgumentParser(description="Check the paths AGENTS.md names.")
    parser.add_argument("root", nargs="?", default=default_root, help="repository root")
    parser.add_argument("-v", "--verbose", action="store_true", help="also list skips and passes")
    args = parser.parse_args(argv)
    root = os.path.abspath(args.root)
    if not os.path.isfile(os.path.join(root, "AGENTS.md")):
        parser.error("no AGENTS.md under repository root")
    try:
        git = subprocess.run(["git", "rev-parse", "--is-inside-work-tree"], cwd=root,
                             capture_output=True, text=True, check=False)
    except OSError as error:
        parser.error(f"git unavailable: {error}")
    if git.returncode or git.stdout.strip() != "true":
        parser.error("repository root is not inside a git work tree")
    root_entries = set(os.listdir(root))
    with open(os.path.join(root, "AGENTS.md"), encoding="utf-8") as handle:
        markdown = handle.read()
    checked = failed = warned = 0
    for line, span in code_spans(markdown):
        path = normalize(span)
        reason = skip_reason(span, path, root_entries)
        if reason is not None:
            level = "SKIP"
        else:
            checked += 1
            level, reason = verdict(root, span, path, root_entries)
            failed += level == "FAIL"
            warned += level == "WARN"
        if args.verbose or level in ("FAIL", "WARN"):
            display = span.replace("\n", r"\n").replace("\r", r"\r")
            print(f"AGENTS.md:{line}: {level} `{display}`: {reason}")
    print(f"checked {checked}, failed {failed}, warned {warned}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
