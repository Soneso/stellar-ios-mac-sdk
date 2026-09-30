"""Tests for rpc_releases: release-list fetch, stable selection, and tag lookup."""

import sys
import tempfile
import unittest
import urllib.error
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "rpc"))

import rpc_releases  # noqa: E402
from rpc_releases import ReleaseLookupError, fetch_releases, find_release, select_newest_stable  # noqa: E402

from release_fixtures import FakeResponse, FakeUrlopen, release, release_list  # noqa: E402

REPO = "stellar/stellar-rpc"
FIRST_PAGE = "https://api.github.com/repos/stellar/stellar-rpc/releases?per_page=100"
SECOND_PAGE = "https://api.github.com/repositories/1/releases?per_page=100&page=2"
THIRD_PAGE = "https://api.github.com/repositories/1/releases?per_page=100&page=3"


class SelectNewestStableTest(unittest.TestCase):

    def test_selects_highest_stable_version_by_numeric_comparison(self):
        selected = select_newest_stable(release_list(), REPO)
        self.assertEqual(selected.tag, "v28.0.10")
        self.assertEqual(selected.published_date, "2026-08-27")
        self.assertEqual(selected.html_url, "https://github.com/stellar/stellar-rpc/releases/tag/v28.0.10")

    def test_tag_with_prefix_is_not_a_candidate(self):
        releases = [release("rpcclient-v24.0.0"), release("v23.0.0")]
        self.assertEqual(select_newest_stable(releases, REPO).tag, "v23.0.0")

    def test_suffixed_tag_is_not_a_candidate_even_when_not_flagged_prerelease(self):
        releases = [release("v29.0.0-rc.1"), release("v28.0.0")]
        self.assertEqual(select_newest_stable(releases, REPO).tag, "v28.0.0")

    def test_suffixless_tag_flagged_prerelease_is_not_a_candidate(self):
        releases = [release("v30.0.0", prerelease=True), release("v28.0.0")]
        self.assertEqual(select_newest_stable(releases, REPO).tag, "v28.0.0")

    def test_draft_is_filtered_before_published_at_is_read(self):
        releases = [release("v31.0.0", draft=True), release("v28.0.0")]
        self.assertIsNone(releases[0]["published_at"])
        self.assertEqual(select_newest_stable(releases, REPO).tag, "v28.0.0")

    def test_empty_list_raises(self):
        with self.assertRaisesRegex(ReleaseLookupError, r"stellar/stellar-rpc has no stable vX\.Y\.Z release"):
            select_newest_stable([], REPO)

    def test_list_without_stable_release_raises(self):
        releases = [release("rpcclient-v24.0.0"), release("v29.0.0-rc.1", prerelease=True),
                    release("v31.0.0", draft=True)]
        with self.assertRaisesRegex(ReleaseLookupError, r"has no stable vX\.Y\.Z release"):
            select_newest_stable(releases, REPO)

    def test_selected_release_without_published_at_raises(self):
        broken = release("v28.0.0")
        broken["published_at"] = None
        with self.assertRaisesRegex(ReleaseLookupError, "v28.0.0 has no valid published_at"):
            select_newest_stable([broken], REPO)


class FindReleaseTest(unittest.TestCase):

    def test_override_present_returns_that_record(self):
        found = find_release(release_list(), REPO, "v28.0.9")
        self.assertEqual(found.tag, "v28.0.9")
        self.assertEqual(found.published_date, "2026-09-05")
        self.assertEqual(found.html_url, "https://github.com/stellar/stellar-rpc/releases/tag/v28.0.9")

    def test_prerelease_override_is_allowed(self):
        found = find_release(release_list(), REPO, "v29.0.0-rc.1")
        self.assertEqual(found.tag, "v29.0.0-rc.1")

    def test_override_absent_raises(self):
        with self.assertRaisesRegex(ReleaseLookupError, "has no release tagged v26.0.0"):
            find_release(release_list(), REPO, "v26.0.0")

    def test_override_pointing_at_draft_raises(self):
        with self.assertRaisesRegex(ReleaseLookupError, "v31.0.0 is a draft"):
            find_release(release_list(), REPO, "v31.0.0")

    def test_override_outside_header_tag_form_raises(self):
        with self.assertRaisesRegex(ReleaseLookupError, "not a stellar/stellar-rpc release tag"):
            find_release(release_list(), REPO, "rpcclient-v24.0.0")

    def test_override_with_hyphen_inside_suffix_raises(self):
        releases = [*release_list(), release("v29.0.0-rc-1", prerelease=True)]
        with self.assertRaisesRegex(ReleaseLookupError, "not a stellar/stellar-rpc release tag"):
            find_release(releases, REPO, "v29.0.0-rc-1")


class FetchReleasesTest(unittest.TestCase):

    def test_follows_link_next_to_second_page_with_higher_version(self):
        fake = FakeUrlopen({
            FIRST_PAGE: FakeResponse(
                release_list(),
                link=f'<{SECOND_PAGE}>; rel="next", <{THIRD_PAGE}>; rel="last"',
            ),
            SECOND_PAGE: FakeResponse(
                [release("v28.1.0", "2026-09-25T10:00:00Z")],
                link=(f'<{FIRST_PAGE}>; rel="prev", <{THIRD_PAGE}>; rel="next", '
                      f'<{THIRD_PAGE}>; rel="last", <{FIRST_PAGE}>; rel="first"'),
            ),
            THIRD_PAGE: FakeResponse(
                [release("v1.0.0", "2024-01-01T10:00:00Z")],
                link=f'<{SECOND_PAGE}>; rel="prev", <{FIRST_PAGE}>; rel="first"',
            ),
        })
        with mock.patch.object(rpc_releases.urllib.request, "urlopen", fake):
            releases = fetch_releases(REPO, "test-token")

        self.assertEqual(fake.urls, [FIRST_PAGE, SECOND_PAGE, THIRD_PAGE])
        self.assertEqual(len(releases), len(release_list()) + 2)
        self.assertEqual(select_newest_stable(releases, REPO).tag, "v28.1.0")
        for request in fake.requests:
            self.assertEqual(request.get_header("Authorization"), "Bearer test-token")

    def test_single_page_without_link_header_stops(self):
        fake = FakeUrlopen({FIRST_PAGE: FakeResponse(release_list())})
        with mock.patch.object(rpc_releases.urllib.request, "urlopen", fake):
            releases = fetch_releases(REPO, None)
        self.assertEqual(fake.urls, [FIRST_PAGE])
        self.assertEqual(len(releases), len(release_list()))
        self.assertIsNone(fake.requests[0].get_header("Authorization"))

    def test_network_error_raises(self):
        failing = mock.Mock(side_effect=urllib.error.URLError("connection refused"))
        with mock.patch.object(rpc_releases.urllib.request, "urlopen", failing):
            with self.assertRaisesRegex(ReleaseLookupError, "connection refused"):
                fetch_releases(REPO, None)

    def test_http_error_raises(self):
        failing = mock.Mock(side_effect=urllib.error.HTTPError(FIRST_PAGE, 403, "rate limit exceeded", {}, None))
        with mock.patch.object(rpc_releases.urllib.request, "urlopen", failing):
            with self.assertRaisesRegex(ReleaseLookupError, "HTTP Error 403"):
                fetch_releases(REPO, None)

    def test_body_that_is_not_json_raises(self):
        fake = FakeUrlopen({FIRST_PAGE: FakeResponse(b"<html>unavailable</html>")})
        with mock.patch.object(rpc_releases.urllib.request, "urlopen", fake):
            with self.assertRaisesRegex(ReleaseLookupError, "invalid JSON"):
                fetch_releases(REPO, None)

    def test_json_body_that_is_not_a_release_list_raises(self):
        fake = FakeUrlopen({FIRST_PAGE: FakeResponse({"message": "Bad credentials"})})
        with mock.patch.object(rpc_releases.urllib.request, "urlopen", fake):
            with self.assertRaisesRegex(ReleaseLookupError, "expected a list of releases"):
                fetch_releases(REPO, None)

    def test_list_with_non_object_entry_raises(self):
        fake = FakeUrlopen({FIRST_PAGE: FakeResponse(["v28.0.1"])})
        with mock.patch.object(rpc_releases.urllib.request, "urlopen", fake):
            with self.assertRaisesRegex(ReleaseLookupError, "invalid release entry"):
                fetch_releases(REPO, None)

    def test_entry_with_missing_or_non_boolean_flags_or_tag_raises(self):
        variants = {
            "draft missing": {"draft": None},
            "prerelease missing": {"prerelease": None},
            "draft as string": {"draft": "false"},
            "prerelease as number": {"prerelease": 0},
            "tag_name missing": {"tag_name": None},
            "tag_name as number": {"tag_name": 28},
        }
        for label, change in variants.items():
            entry = release("v40.0.0", "2026-09-01T00:00:00Z")
            for key, value in change.items():
                if value is None:
                    del entry[key]
                else:
                    entry[key] = value
            fake = FakeUrlopen({FIRST_PAGE: FakeResponse([entry, release("v28.0.0")])})
            with self.subTest(label), mock.patch.object(rpc_releases.urllib.request, "urlopen", fake):
                with self.assertRaisesRegex(ReleaseLookupError, "invalid release entry"):
                    fetch_releases(REPO, None)

    def test_invalid_second_page_raises(self):
        failing_second = FakeUrlopen({
            FIRST_PAGE: FakeResponse(release_list(), link=f'<{SECOND_PAGE}>; rel="next"'),
            SECOND_PAGE: FakeResponse(b"not json"),
        })
        with mock.patch.object(rpc_releases.urllib.request, "urlopen", failing_second):
            with self.assertRaisesRegex(ReleaseLookupError, "invalid JSON"):
                fetch_releases(REPO, None)


class GithubTokenTest(unittest.TestCase):

    def test_environment_variable_wins(self):
        with mock.patch.dict(rpc_releases.os.environ, {"GITHUB_TOKEN": "env-token"}):
            self.assertEqual(rpc_releases.get_github_token(), "env-token")

    def test_gh_hosts_file_is_read_when_environment_variable_is_unset(self):
        with tempfile.TemporaryDirectory() as home:
            config = Path(home) / ".config" / "gh"
            config.mkdir(parents=True)
            (config / "hosts.yml").write_text("github.com:\n    oauth_token: file-token\n    user: someone\n")
            env = {key: value for key, value in rpc_releases.os.environ.items() if key != "GITHUB_TOKEN"}
            with mock.patch.dict(rpc_releases.os.environ, env, clear=True), \
                    mock.patch.object(rpc_releases.Path, "home", return_value=Path(home)):
                self.assertEqual(rpc_releases.get_github_token(), "file-token")


if __name__ == "__main__":
    unittest.main()
