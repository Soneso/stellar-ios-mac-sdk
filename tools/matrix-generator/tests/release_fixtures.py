"""Release-list fixtures and a fake urlopen shared by the RPC tool tests."""

import json
from typing import Optional


def release(tag: str, published_at: Optional[str] = None, prerelease: bool = False, draft: bool = False) -> dict:
    """One entry of a GitHub release list. Drafts carry published_at null, as the API returns them."""
    return {
        "tag_name": tag,
        "draft": draft,
        "prerelease": prerelease,
        "published_at": None if draft else (published_at or "2026-01-01T00:00:00Z"),
        "html_url": f"https://github.com/stellar/stellar-rpc/releases/tag/{tag}",
    }


def release_list() -> list:
    """
    A release list in creation order, which differs from version order.

    The first stable-looking entry in list order is v28.0.9; the highest stable
    version is v28.0.10. Higher tags are a draft, a suffixed prerelease, and a
    suffix-less tag flagged prerelease.
    """
    return [
        release("rpcclient-v24.0.0", "2026-09-20T10:00:00Z"),
        release("v31.0.0", draft=True),
        release("v29.0.0-rc.1", "2026-09-15T10:00:00Z", prerelease=True),
        release("v30.0.0", "2026-09-10T10:00:00Z", prerelease=True),
        release("v28.0.9", "2026-09-05T10:00:00Z"),
        release("v28.0.10", "2026-08-27T18:40:46Z"),
        release("v27.1.1", "2026-07-01T10:00:00Z"),
    ]


class FakeResponse:
    """A urlopen response with a body and an optional Link header."""

    def __init__(self, body, link: Optional[str] = None):
        self._body = body if isinstance(body, bytes) else json.dumps(body).encode("utf-8")
        self.headers = {"Link": link} if link else {}

    def read(self) -> bytes:
        return self._body

    def __enter__(self):
        return self

    def __exit__(self, *exc_info):
        return False


class FakeUrlopen:
    """Serves FakeResponse objects by exact URL and records every request."""

    def __init__(self, pages: dict):
        self.pages = pages
        self.requests = []

    def __call__(self, request, timeout=None):
        self.requests.append(request)
        return self.pages[request.full_url]

    @property
    def urls(self) -> list:
        return [request.full_url for request in self.requests]
