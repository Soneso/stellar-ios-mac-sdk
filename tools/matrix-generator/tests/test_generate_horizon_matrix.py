"""Tests for generate_horizon_matrix: an unreadable SDK version fails the run before any request."""

import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "horizon"))

import generate_horizon_matrix  # noqa: E402


class SdkVersionTest(unittest.TestCase):

    def test_unreadable_sdk_version_exits_non_zero_before_any_request(self):
        with tempfile.TemporaryDirectory() as tmp:
            sdk_root = Path(tmp)
            (sdk_root / "stellarsdk" / "stellarsdk" / "service").mkdir(parents=True)
            output = sdk_root / "HORIZON_COMPATIBILITY_MATRIX.md"
            request = mock.Mock(side_effect=AssertionError("no request expected"))
            with mock.patch.object(generate_horizon_matrix, "urlopen", request), \
                    self.assertLogs(generate_horizon_matrix.logger, "ERROR") as logs:
                status = generate_horizon_matrix.HorizonMatrixGenerator(sdk_root).generate(output_path=str(output))
            self.assertEqual(status, 1)
            self.assertFalse(output.exists())
        request.assert_not_called()
        self.assertIn("Info.plist", logs.output[0])


if __name__ == "__main__":
    unittest.main()
