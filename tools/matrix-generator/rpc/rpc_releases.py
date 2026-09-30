"""
GitHub release lookup for extract_rpc_methods.py and generate_rpc_matrix.py.

Standard library only, so that generate_rpc_matrix.py runs without third-party
packages. Every lookup raises ReleaseLookupError on a request error, an invalid
response, or when no release qualifies; callers never substitute a default.
"""

import http.client
import json
import os
import re
import urllib.request
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Optional

GITHUB_API_BASE = "https://api.github.com"
STELLAR_RPC_REPO = "stellar/stellar-rpc"
USER_AGENT = "stellar-ios-mac-sdk-matrix-generator/1.0"
REQUEST_TIMEOUT_SECONDS = 30
RELEASES_PER_PAGE = 100

# Stable release tags: "v28.0.1" qualifies; "v29.0.0-rc.1" and "rpcclient-v24.0.0" do not.
_STABLE_TAG = re.compile(r"v(\d+)\.(\d+)\.(\d+)")
# Tags a caller may name: stable or prerelease ("v29.0.0-rc.1"); "rpcclient-v24.0.0" does not qualify.
_RELEASE_TAG = re.compile(r"v\d+\.\d+\.\d+(?:-[0-9A-Za-z.]+)?")
_PUBLISHED_AT = re.compile(r"\d{4}-\d{2}-\d{2}T")
_LINK_ENTRY = re.compile(r'<([^>]+)>\s*;\s*rel="([^"]+)"')


class ReleaseLookupError(RuntimeError):
    """A release list could not be read, or no release matches the request."""


@dataclass(frozen=True)
class Release:
    """The fields of one GitHub release that a matrix header cites."""

    tag: str
    published_date: str  # First ten characters of published_at (YYYY-MM-DD, UTC).
    html_url: str


def get_github_token() -> Optional[str]:
    """Return a GitHub token from GITHUB_TOKEN or the gh CLI hosts file, or None."""
    token = os.environ.get("GITHUB_TOKEN")
    if token:
        return token

    hosts_file = Path.home() / ".config" / "gh" / "hosts.yml"
    try:
        content = hosts_file.read_text(encoding="utf-8")
    except OSError:
        return None
    for line in content.splitlines():
        if "oauth_token:" in line:
            value = line.split("oauth_token:", 1)[1].strip()
            if value:
                return value
    return None


def resolve_release(repo: str, tag: Optional[str], token: Optional[str]) -> Release:
    """Return the release of *repo* ("owner/name") named by *tag*, or the newest stable one.

    With *tag*, find_release() applies: the tag has the form vX.Y.Z or
    vX.Y.Z-suffix, and the release exists and is not a draft; a prerelease
    qualifies. Without *tag*, select_newest_stable() applies.
    """
    releases = fetch_releases(repo, token)
    if tag is None:
        return select_newest_stable(releases, repo)
    return find_release(releases, repo, tag)


def fetch_releases(repo: str, token: Optional[str]) -> list[dict[str, Any]]:
    """Return every release of *repo* ("owner/name"), following Link rel="next" until the last page."""
    url: Optional[str] = f"{GITHUB_API_BASE}/repos/{repo}/releases?per_page={RELEASES_PER_PAGE}"
    releases: list[dict[str, Any]] = []
    while url is not None:
        page, link_header = _get_json(url, token)
        if not isinstance(page, list):
            raise ReleaseLookupError(f"GET {url} returned {type(page).__name__}, expected a list of releases")
        for entry in page:
            _check_entry(entry, url)
        releases.extend(page)
        url = _next_page_url(link_header)
    return releases


def select_newest_stable(releases: list[dict[str, Any]], repo: str) -> Release:
    """Return the highest vX.Y.Z release by numeric semver that is neither a draft nor a prerelease.

    GitHub lists releases in creation order and its "latest" flag follows creation
    too, so neither identifies the newest version. The prerelease flag excludes
    suffix-less tags as well.
    """
    candidates = [
        entry for entry in releases
        if not entry["draft"] and not entry["prerelease"] and _STABLE_TAG.fullmatch(entry["tag_name"])
    ]
    if not candidates:
        raise ReleaseLookupError(f"{repo} has no stable vX.Y.Z release")
    newest = max(candidates, key=lambda entry: _semver_key(entry["tag_name"]))
    return _to_release(newest, repo)


def find_release(releases: list[dict[str, Any]], repo: str, tag: str) -> Release:
    """Return the non-draft release tagged *tag* (vX.Y.Z or vX.Y.Z-suffix); prereleases qualify."""
    if not _RELEASE_TAG.fullmatch(tag):
        raise ReleaseLookupError(f"{tag!r} is not a {repo} release tag of the form vX.Y.Z or vX.Y.Z-suffix")
    tagged = [entry for entry in releases if entry["tag_name"] == tag]
    if not tagged:
        raise ReleaseLookupError(f"{repo} has no release tagged {tag}")
    published = [entry for entry in tagged if not entry["draft"]]
    if not published:
        raise ReleaseLookupError(f"{repo} release {tag} is a draft")
    return _to_release(published[0], repo)


def _get_json(url: str, token: Optional[str]) -> tuple[Any, Optional[str]]:
    """GET *url* from the GitHub API and return the decoded body and the Link header."""
    headers = {"User-Agent": USER_AGENT, "Accept": "application/vnd.github+json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    request = urllib.request.Request(url, headers=headers)
    try:
        with urllib.request.urlopen(request, timeout=REQUEST_TIMEOUT_SECONDS) as response:
            body = response.read()
            link_header = response.headers.get("Link")
    except (OSError, http.client.HTTPException) as exc:
        raise ReleaseLookupError(f"GET {url} failed: {exc}") from exc
    try:
        return json.loads(body.decode("utf-8")), link_header
    except ValueError as exc:
        raise ReleaseLookupError(f"GET {url} returned invalid JSON: {exc}") from exc


def _check_entry(entry: Any, url: str) -> None:
    """Raise unless *entry* carries the fields that release selection reads."""
    if not (
        isinstance(entry, dict)
        and isinstance(entry.get("tag_name"), str)
        and isinstance(entry.get("draft"), bool)
        and isinstance(entry.get("prerelease"), bool)
    ):
        raise ReleaseLookupError(
            f"GET {url} returned an invalid release entry "
            f"(needs string tag_name, boolean draft and prerelease): {entry!r:.200}"
        )


def _next_page_url(link_header: Optional[str]) -> Optional[str]:
    """Return the target of the first Link entry whose relation types include "next", or None."""
    if not link_header:
        return None
    for target, relations in _LINK_ENTRY.findall(link_header):
        if "next" in relations.split():
            return target
    return None


def _semver_key(tag: str) -> tuple[int, int, int]:
    """Return the numeric (major, minor, patch) of a _STABLE_TAG tag."""
    major, minor, patch = _STABLE_TAG.fullmatch(tag).groups()
    return int(major), int(minor), int(patch)


def _to_release(entry: dict[str, Any], repo: str) -> Release:
    """Build a Release from one non-draft list entry."""
    tag = entry["tag_name"]
    published_at = entry.get("published_at")
    html_url = entry.get("html_url")
    if not isinstance(published_at, str) or not _PUBLISHED_AT.match(published_at):
        raise ReleaseLookupError(f"{repo} release {tag} has no valid published_at: {published_at!r}")
    if not isinstance(html_url, str) or not html_url.startswith("https://"):
        raise ReleaseLookupError(f"{repo} release {tag} has no valid html_url: {html_url!r}")
    return Release(tag=tag, published_date=published_at[:10], html_url=html_url)
