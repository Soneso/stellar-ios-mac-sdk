#!/usr/bin/env python3
"""Exercise path checks in isolated temporary git repositories."""

import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest import mock

sys.path.insert(0, os.path.dirname(__file__))
import check_agents_md_paths as checker


class PathChecks(unittest.TestCase):
    """Check CLI output and status using disposable repository fixtures."""

    def setUp(self):
        """Create a git work tree with paths and ignore rules used by the cases."""
        self.root = Path(tempfile.mkdtemp(prefix="agents-paths-"))
        self.addCleanup(shutil.rmtree, self.root)
        self.env = {key: value for key, value in os.environ.items() if not key.startswith("GIT_")}
        self.env.update(GIT_CONFIG_NOSYSTEM="1", GIT_CONFIG_GLOBAL=os.devnull,
                        GIT_CEILING_DIRECTORIES=str(self.root.parent))
        subprocess.run(["git", "init", "-q", str(self.root)], env=self.env,
                       check=True, capture_output=True, text=True)
        self.put(".gitignore", "build/\noutput.md\n.claude/\n")
        for name in ("README.md", "Makefile", "docs/guide.md", ".github/workflows/tests.yml"):
            self.put(name)
        self.put("AGENTS.md")

    def put(self, name, content=""):
        """Write a fixture file and create its parent directories."""
        path = self.root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")

    def invoke(self, markdown=None, verbose=False, cwd=None, env=None, script=None, default=False):
        """Run the checker and capture its output without changing this process's cwd."""
        if markdown is not None:
            self.put("AGENTS.md", markdown)
        args = [sys.executable, str(script or Path(checker.__file__).resolve())]
        if verbose:
            args.append("-v")
        if not default:
            args.append(str(self.root))
        return subprocess.run(args, cwd=cwd or self.root, env=self.env if env is None else env,
                              capture_output=True, text=True, check=False)

    def expect(self, result, status, checked, failed=0, warned=0, lines=()):
        """Assert the exit status, complete quiet output and final summary counts."""
        self.assertEqual(result.returncode, status, result.stderr + result.stdout)
        summary = f"checked {checked}, failed {failed}, warned {warned}"
        self.assertEqual(result.stdout.splitlines(), [*lines, summary])

    def test_fences(self):
        """Ignore backtick and tilde fences, including different closing lengths."""
        self.expect(self.invoke("```py\n`missing.md`\n````\n~~~`info`\n`absent.md`\n~~~~\n"
                                "   ```\n`gone.md`\n   ```\n`README.md`\n"), 0, 1)

    def test_inline_triple(self):
        """Treat a backtick-containing info string as an inline span."""
        self.expect(self.invoke("```missing.md``` bar\n`README.md`\n"), 1, 2, 1,
                    lines=("AGENTS.md:1: FAIL `missing.md`: no such path",))
        self.expect(self.invoke("```foo``` bar\n`missing.md`"), 1, 1, 1,
                    lines=("AGENTS.md:2: FAIL `missing.md`: no such path",))

    def test_closer_text(self):
        """Keep fences open when a candidate closer has trailing text."""
        for fence in ("```", "~~~"):
            with self.subTest(fence=fence):
                text = f"{fence}\n{fence} text\n`inside.md`\n{fence}\n`outside.md`\n"
                self.expect(self.invoke(text), 1, 1, 1,
                            lines=("AGENTS.md:5: FAIL `outside.md`: no such path",))

    def test_fence_indent(self):
        """Limit fence indentation to three spaces and disallow leading tabs."""
        for indent in ("    ", "\t"):
            with self.subTest(indent=indent):
                self.expect(self.invoke(f"{indent}```\n\n`missing.md`\n"), 1, 1, 1,
                            lines=("AGENTS.md:3: FAIL `missing.md`: no such path",))

    def test_closer_nbsp(self):
        """A non-breaking space after a fence run keeps the block open."""
        for fence in ("```", "~~~"):
            with self.subTest(fence=fence):
                text = f"{fence}\n{fence}\u00a0\n`hidden.md`\n{fence}\n`README.md`\n"
                self.expect(self.invoke(text), 0, 1)

    def test_closer_spaces_tabs(self):
        """Spaces and tabs after a fence run allow the block to close."""
        for fence in ("```", "~~~"):
            with self.subTest(fence=fence):
                text = f"{fence}\n`hidden.md`\n{fence} \t \n`outside.md`\n"
                self.expect(self.invoke(text), 1, 1, 1,
                            lines=("AGENTS.md:4: FAIL `outside.md`: no such path",))

    def test_unclosed_fence(self):
        """An unclosed fence hides every following span through end of file."""
        for fence in ("```", "~~~"):
            with self.subTest(fence=fence):
                self.expect(self.invoke(f"`README.md`\n{fence}\n`hidden.md`\n\n`gone.md`"), 0, 1)

    def test_closer_short(self):
        """A closer shorter than the opening run keeps the block open."""
        for char in ("`", "~"):
            with self.subTest(char=char):
                text = f"{char * 4}\n{char * 3}\n`hidden.md`\n{char * 4}\n`README.md`\n"
                self.expect(self.invoke(text), 0, 1)

    def test_closer_other(self):
        """A closer using the other fence character keeps the block open."""
        for fence, other in (("```", "~~~"), ("~~~", "```")):
            with self.subTest(fence=fence):
                text = f"{fence}\n{other}\n`hidden.md`\n{fence}\n`README.md`\n"
                self.expect(self.invoke(text), 0, 1)

    def test_closer_indent(self):
        """Four spaces before a candidate closer keep the block open."""
        for fence in ("```", "~~~"):
            with self.subTest(fence=fence):
                text = f"{fence}\n    {fence}\n`hidden.md`\n{fence}\n`README.md`\n"
                self.expect(self.invoke(text), 0, 1)

    def test_escaped_backtick(self):
        """An escaped opener must not swallow the following path span."""
        self.expect(self.invoke("\\` literal `docs/missing.md`"), 1, 1, 1,
                    lines=("AGENTS.md:1: FAIL `docs/missing.md`: no such path",))

    def test_span_runs(self):
        """Pair exact run lengths and leave unmatched runs literal."""
        self.put("docs/a`b.md")
        self.expect(self.invoke("``docs/a`b.md``\n`unmatched\n\n"
                                "``another unmatched\n`README.md`\n"), 0, 2)
        self.assertEqual(list(checker.code_spans("``a\\`b``\n`line\nbreak`")),
                         [(1, "a\\`b"), (2, "line\nbreak")])

    def test_escape_runs(self):
        """Allow a run after an escaped backtick and literal backslashes in spans."""
        self.expect(self.invoke("\\```missing.md``"), 1, 1, 1,
                    lines=("AGENTS.md:1: FAIL `missing.md`: no such path",))
        self.assertEqual(list(checker.code_spans(r"`a\` then `README.md`")),
                         [(1, "a\\"), (1, "README.md")])

    def test_dot_readme(self):
        """Resolve the leading dot before exact-case existence checks."""
        self.expect(self.invoke("`./README.md`"), 0, 1)

    def test_dot_miss(self):
        """Classify a dot-relative miss using its normalized first segment."""
        self.expect(self.invoke("`./docs/missing.md`"), 1, 1, 1,
                    lines=("AGENTS.md:1: FAIL `./docs/missing.md`: no such path",))

    def test_dot_components(self):
        """Resolve dot components for files, classification and glob patterns."""
        self.expect(self.invoke("`docs/./guide.md` `./docs/./*.md` `./Makefile`"), 0, 3)
        self.expect(self.invoke("`./other/missing.md`"), 0, 1, warned=1,
                    lines=("AGENTS.md:1: WARN `./other/missing.md`: not a repository path",))

    def test_dot_root_miss(self):
        """Explicit dot-relative root paths are checked regardless of suffix."""
        for span in ("./corpus.json", "./gradlew"):
            with self.subTest(span=span):
                self.expect(self.invoke(f"`{span}`"), 1, 1, 1,
                            lines=(f"AGENTS.md:1: FAIL `{span}`: no such path",))

    def test_misses(self):
        """Fail misses under root entries and warn for unknown prefixes and URIs."""
        self.expect(self.invoke("`docs/missing.md`\n`other/missing.md`"), 1, 2, 1, 1,
                    ("AGENTS.md:1: FAIL `docs/missing.md`: no such path",
                     "AGENTS.md:2: WARN `other/missing.md`: not a repository path"))
        self.expect(self.invoke("`package:http/testing.dart`"), 0, 1, warned=1,
                    lines=("AGENTS.md:1: WARN `package:http/testing.dart`: not a repository path",))

    def test_directories(self):
        """Accept directories with or without a trailing slash."""
        self.expect(self.invoke("`docs` `docs/`"), 0, 2)

    def test_file_slash(self):
        """Reject a file named with a directory slash even when git ignores it."""
        for ignored in (False, True):
            with self.subTest(ignored=ignored):
                if ignored:
                    self.put(".gitignore", "README.md\n")
                self.expect(self.invoke("`README.md/`"), 1, 1, 1,
                            lines=("AGENTS.md:1: FAIL `README.md/`: a file, not a directory",))

    def test_ignored(self):
        """Accept absent ignored directories and files, retaining original slashes."""
        self.expect(self.invoke("`build/` `output.md`"), 0, 2)

    def test_globs(self):
        """Require an existing match for an asterisk glob even under ignored paths."""
        self.expect(self.invoke("`docs/*.md` `docs/*.txt` `build/*.md`"), 1, 3, 2,
                    lines=("AGENTS.md:1: FAIL `docs/*.txt`: glob matches no path",
                           "AGENTS.md:1: FAIL `build/*.md`: glob matches no path"))

    def test_glob_kinds(self):
        """Recognize question-mark and bracket globs as well as asterisks."""
        self.expect(self.invoke("`docs/guid?.md` `docs/[g]uide.md` `docs/[z]*.md`"), 1, 3, 1,
                    lines=("AGENTS.md:1: FAIL `docs/[z]*.md`: glob matches no path",))

    def test_directory_glob_match(self):
        """A glob ending in a slash passes when a directory matches."""
        (self.root / "docs/sub").mkdir()
        self.expect(self.invoke("`docs/*/`"), 0, 1)

    def test_directory_glob_miss(self):
        """Files alone cannot satisfy a glob ending in a slash."""
        self.expect(self.invoke("`docs/*/`"), 1, 1, 1,
                    lines=("AGENTS.md:1: FAIL `docs/*/`: glob matches no path",))

    def test_glob_case(self):
        """Reject case-mismatched paths returned by a case-insensitive glob traversal."""
        self.expect(self.invoke("`DOCS/*.md` `docs/G*.md`"), 1, 2, 2,
                    lines=("AGENTS.md:1: FAIL `DOCS/*.md`: glob matches no path",
                           "AGENTS.md:1: FAIL `docs/G*.md`: glob matches no path"))
        with mock.patch.object(checker.glob, "glob", return_value=["DOCS/guide.md"]):
            with mock.patch.object(sys, "argv", [checker.__file__, str(self.root)]):
                from contextlib import redirect_stdout
                import io
                self.put("AGENTS.md", "`DOCS/*.md`")
                output = io.StringIO()
                with redirect_stdout(output):
                    status = checker.main()
                self.assertEqual(status, 1)
                self.assertIn("FAIL `DOCS/*.md`: glob matches no path", output.getvalue())

    def test_exact_case(self):
        """Check exact case for intermediate and final path segments."""
        self.put("docs/Sub/file.md")
        self.expect(self.invoke("`docs/sub/file.md` `docs/Guide.md` `readme.md`"), 1, 3, 3,
                    lines=("AGENTS.md:1: FAIL `docs/sub/file.md`: no such path",
                           "AGENTS.md:1: FAIL `docs/Guide.md`: no such path",
                           "AGENTS.md:1: FAIL `readme.md`: no such path"))

    def test_skips(self):
        """Skip member tokens, switches, placeholders, identifiers and non-path text."""
        spans = (".success", ".failure/status", ".invalid", "-v", "~/.gradle", "@AGENTS.md",
                 "///", "X.Y.Z", "$HOME/x", "a b", "identifier", "corpus.json", "YYYY/x",
                 "x/.../y", "https://example/x", "<name>/x", "x>y/z", "a\\b")
        self.expect(self.invoke(" ".join(f"`{span}`" for span in spans)), 0, 0)

    def test_absolute(self):
        """Skip absolute files, globs and missing paths before checking existence."""
        spans = [str(self.root / name) for name in ("README.md", "docs/*.md", "missing.md")]
        result = self.invoke(" ".join(f"`{span}`" for span in spans), verbose=True)
        self.expect(result, 0, 0,
                    lines=tuple(f"AGENTS.md:1: SKIP `{span}`: starts with '/'" for span in spans))

    def test_skip_rules(self):
        """Each fixture is skipped by exactly one non-path predicate."""
        cases = (("whitespace", "docs/missing file.md"), ("$", "$HOME/x"),
                 ("<", "x<y/z"), (">", "x>y/z"), ("backslash", "docs\\README.md"),
                 ("...", "docs/.../missing.md"), ("://", "https://example/x"),
                 ("X.Y.Z", "docs/vX.Y.Z.md"), ("YYYY", "docs/YYYY.md"),
                 ("~", "~/missing.md"), ("-", "--config=missing.yml"),
                 ("@", "@AGENTS.md"), ("/", "/missing.md"),
                 ("dot", ".failure/status"), ("word", "identifier"))
        for rule, span in cases:
            with self.subTest(rule=rule, span=span):
                self.expect(self.invoke(f"`{span}`"), 0, 0)

    def test_hidden(self):
        """Check recognized dot paths and other hidden entries of the root."""
        self.put(".config/settings.yml")
        self.expect(self.invoke("`.github/workflows/tests.yml` `.claude/` `.gitignore` "
                                "`.config/settings.yml`"), 0, 4)

    def test_words(self):
        """Check root entries and document suffixes while rejecting a missing root file."""
        self.expect(self.invoke("`Makefile` `README.md` `missing.md`"), 1, 3, 1,
                    lines=("AGENTS.md:1: FAIL `missing.md`: no such path",))

    def test_parent(self):
        """Warn for every parent component before traversal or globbing."""
        spans = ("docs/../README.md", "../README.md", "docs/../*.md", "..")
        self.expect(self.invoke(" ".join(f"`{span}`" for span in spans)), 0, 4, warned=4,
                    lines=tuple(f"AGENTS.md:1: WARN `{span}`: not a repository path" for span in spans))

    def test_yml_miss(self):
        """A missing root file with a yml suffix fails."""
        self.expect(self.invoke("`missing.yml`"), 1, 1, 1,
                    lines=("AGENTS.md:1: FAIL `missing.yml`: no such path",))

    def test_yml_present(self):
        """An existing root file with a yml suffix passes."""
        self.put("config.yml")
        self.expect(self.invoke("`config.yml`"), 0, 1)

    def test_crlf(self):
        """CRLF and LF files produce identical verdicts and line numbers."""
        text = "```\n`hidden.md`\n```\n`README.md`\n`missing.yml`\n`other/missing.md`\n"
        lf = self.invoke(text)
        self.expect(lf, 1, 3, 1, 1,
                    ("AGENTS.md:5: FAIL `missing.yml`: no such path",
                     "AGENTS.md:6: WARN `other/missing.md`: not a repository path"))
        crlf = self.invoke(text.replace("\n", "\r\n"))
        self.assertEqual((crlf.returncode, crlf.stdout), (lf.returncode, lf.stdout))

    def test_no_agents(self):
        """Report a usage error when AGENTS.md is absent."""
        (self.root / "AGENTS.md").unlink()
        result = self.invoke()
        self.assertEqual(result.returncode, 2, result.stderr)
        self.assertIn("no AGENTS.md", result.stderr)

    def test_no_worktree(self):
        """Report a usage error outside a git work tree."""
        shutil.rmtree(self.root / ".git")
        result = self.invoke("`README.md`")
        self.assertEqual(result.returncode, 2, result.stderr)
        self.assertIn("not inside a git work tree", result.stderr)

    def test_no_git(self):
        """Report a usage error when git is unavailable."""
        result = self.invoke("`README.md`", env={**self.env, "PATH": ""})
        self.assertEqual(result.returncode, 2, result.stderr)
        self.assertIn("git unavailable", result.stderr)

    def test_cwd(self):
        """Resolve checks against the root argument from any working directory."""
        text = "`README.md` `docs/*.md` `output.md` `other/missing.md`"
        expected = self.invoke(text, verbose=True)
        actual = self.invoke(text, verbose=True, cwd=self.root / "docs")
        self.assertEqual((actual.returncode, actual.stdout), (expected.returncode, expected.stdout))
        self.assertEqual(actual.returncode, 0, actual.stderr)

    def test_verbose(self):
        """Show each pass and skip reason and keep summary counts independent of verbosity."""
        text = "`README.md` `build/` `docs/*.md` `word` `missing.md` `other/file.md`"
        result = self.invoke(text, verbose=True)
        self.expect(result, 1, 5, 1, 1,
                    ("AGENTS.md:1: PASS `README.md`: exists",
                     "AGENTS.md:1: PASS `build/`: ignored by git",
                     "AGENTS.md:1: PASS `docs/*.md`: glob matches",
                     "AGENTS.md:1: SKIP `word`: single word, not a root entry",
                     "AGENTS.md:1: FAIL `missing.md`: no such path",
                     "AGENTS.md:1: WARN `other/file.md`: not a repository path"))
        quiet = self.invoke(text)
        self.assertEqual(quiet.stdout.splitlines(), result.stdout.splitlines()[-3:])

    def test_default_root(self):
        """Default to the root two directories above the installed script."""
        script = self.root / ".github/scripts/check_agents_md_paths.py"
        script.parent.mkdir(parents=True)
        shutil.copyfile(checker.__file__, script)
        self.expect(self.invoke("`README.md`", script=script, default=True, cwd=self.root / "docs"), 0, 1)


if __name__ == "__main__":
    unittest.main(verbosity=2)
