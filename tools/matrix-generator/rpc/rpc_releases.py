"""
GitHub release lookup for the RPC matrix tools.

Standard library only, so that generate_rpc_matrix.py runs without third-party
packages. extract_rpc_methods.py uses the same functions for its release lookups.

Every failure raises ReleaseLookupError: a request error, an invalid response, or
a release list without a matching release. Callers exit non-zero and write nothing.
"""

import http.client
import json
import os
import re
import urllib.error
import urllib.request
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Optional

GITHUB_API_BASE = "https://api.github.com"
USER_AGENT = "stellar-ios-sdk-matrix-generator"
REQUEST_TIMEOUT_SECONDS = 30
PAGE_SIZE = 100

# A stable release tag: vX.Y.Z with no suffix.
STABLE_TAG = re.compile(r"v(\d+)\.(\d+)\.(\d+)")
# A tag that may name a release in a matrix header, prerelease suffixes included.
# Other tags in the same repository (for example rpcclient-v24.0.0) do not fit the
# header's version field.
RELEASE_TAG = re.compile(r"v\d+\.\d+\.\d+(?:-[0-9A-Za-z.]+)?")
PUBLISHED_DATE = re.compile(r"\d{4}-\d{2}-\d{2}")
LINK_NEXT = re.compile(r'<([^<>]+)>\s*;\s*rel="next"')


class ReleaseLookupError(RuntimeError):
    """A release list could not be fetched, was invalid, or held no matching release."""


@dataclass(frozen=True)
class Release:
    """One GitHub release as cited in a matrix header."""

    version: str
    release_date: str
    html_url: str
    prerelease: bool


def get_github_token() -> Optional[str]:
    """
    Return a GitHub token for authenticated API requests, or None.

    Checks the GITHUB_TOKEN environment variable, then the oauth_token entry of the
    gh CLI config (~/.config/gh/hosts.yml). Authenticated requests get 5,000
    requests per hour, unauthenticated ones 60.
    """
    token = os.environ.get("GITHUB_TOKEN")
    if token:
        return token

    gh_config_path = Path.home() / ".config" / "gh" / "hosts.yml"
    if not gh_config_path.exists():
        return None
    try:
        content = gh_config_path.read_text()
    except OSError:
        return None
    # Line-based read of "oauth_token: TOKEN" keeps this module free of a YAML parser.
    for line in content.split("\n"):
        if "oauth_token:" in line:
            token = line.split("oauth_token:", 1)[1].strip()
            if token:
                return token
    return None


def fetch_releases(owner: str, repo: str, token: Optional[str]) -> list[dict[str, Any]]:
    """
    Fetch every release of a GitHub repository.

    Requests pages of PAGE_SIZE entries and follows the Link rel="next" header until
    no next page remains. Every entry must be an object with a string tag_name and
    boolean draft and prerelease flags. The API lists releases in creation order, so
    callers select by version, never by position.
    """
    releases: list[dict[str, Any]] = []
    url: Optional[str] = f"{GITHUB_API_BASE}/repos/{owner}/{repo}/releases?per_page={PAGE_SIZE}"
    while url:
        page, link_header = _get_json(url, token)
        if not isinstance(page, list):
            raise ReleaseLookupError(f"GET {url} returned no list of release objects")
        for entry in page:
            _check_entry(entry, url)
        releases.extend(page)
        url = _next_page_url(link_header)
    return releases


def select_newest_stable(releases: list[dict[str, Any]], repo: str) -> Release:
    """
    Return the release with the highest stable version from a fetch_releases list.

    Candidates have a tag of the form vX.Y.Z, draft false and prerelease false. The
    highest version wins by numeric comparison of the three components.
    """
    candidates = []
    for entry in releases:
        if entry["draft"] or entry["prerelease"]:
            continue
        match = STABLE_TAG.fullmatch(entry["tag_name"])
        if match:
            candidates.append((tuple(int(part) for part in match.groups()), entry))

    if not candidates:
        raise ReleaseLookupError(
            f"{repo} has no stable release (tag vX.Y.Z, draft false, prerelease false)"
        )
    _, newest = max(candidates, key=lambda candidate: candidate[0])
    return _to_release(newest, repo)


def find_release(releases: list[dict[str, Any]], tag: str, repo: str) -> Release:
    """
    Return the non-draft release with the given tag from a fetch_releases list.

    A prerelease qualifies. The tag must have the form vX.Y.Z, optionally with a
    prerelease suffix, because it becomes the version field of a matrix header.
    """
    if not RELEASE_TAG.fullmatch(tag):
        raise ReleaseLookupError(
            f"{tag!r} is not a {repo} release tag of the form vX.Y.Z or vX.Y.Z-suffix"
        )
    matches = [entry for entry in releases if entry["tag_name"] == tag]
    if not matches:
        raise ReleaseLookupError(f"{repo} has no release with tag {tag}")
    published = [entry for entry in matches if not entry["draft"]]
    if not published:
        raise ReleaseLookupError(f"{repo} release {tag} is a draft")
    return _to_release(published[0], repo)


def _to_release(entry: dict[str, Any], repo: str) -> Release:
    """Build a Release from a non-draft entry; the released date is published_at, first ten characters."""
    tag = entry["tag_name"]
    published_at = entry.get("published_at")
    html_url = entry.get("html_url")
    if not isinstance(published_at, str) or not PUBLISHED_DATE.match(published_at):
        raise ReleaseLookupError(f"{repo} release {tag} has no valid published_at: {published_at!r}")
    if not isinstance(html_url, str) or not html_url.startswith("https://"):
        raise ReleaseLookupError(f"{repo} release {tag} has no valid html_url: {html_url!r}")
    return Release(
        version=tag,
        release_date=published_at[:10],
        html_url=html_url,
        prerelease=entry["prerelease"],
    )


def _check_entry(entry: Any, url: str) -> None:
    """Raise unless a release entry has a string tag_name and boolean draft and prerelease flags."""
    if not (isinstance(entry, dict)
            and isinstance(entry.get("tag_name"), str)
            and isinstance(entry.get("draft"), bool)
            and isinstance(entry.get("prerelease"), bool)):
        raise ReleaseLookupError(
            f"GET {url} returned an invalid release entry (needs string tag_name, boolean draft "
            f"and prerelease): {entry!r:.200}"
        )


def _get_json(url: str, token: Optional[str]) -> tuple[Any, Optional[str]]:
    """GET a GitHub API URL; return the decoded JSON body and the Link header."""
    request = urllib.request.Request(url)
    request.add_header("User-Agent", USER_AGENT)
    request.add_header("Accept", "application/vnd.github+json")
    if token:
        request.add_header("Authorization", f"Bearer {token}")

    try:
        with urllib.request.urlopen(request, timeout=REQUEST_TIMEOUT_SECONDS) as response:
            body = response.read()
            link_header = response.headers.get("Link")
    except urllib.error.HTTPError as e:
        raise ReleaseLookupError(f"GET {url} failed: HTTP {e.code} {e.reason}") from e
    except (OSError, http.client.HTTPException) as e:
        raise ReleaseLookupError(f"GET {url} failed: {e}") from e

    try:
        return json.loads(body), link_header
    except (UnicodeDecodeError, json.JSONDecodeError) as e:
        raise ReleaseLookupError(f"GET {url} returned invalid JSON: {e}") from e


def _next_page_url(link_header: Optional[str]) -> Optional[str]:
    """Return the rel="next" URL of a Link header, or None on the last page."""
    if not link_header:
        return None
    match = LINK_NEXT.search(link_header)
    return match.group(1) if match else None
