"""SDK version lookup shared by the Horizon, RPC and SEP generators."""

import plistlib
from pathlib import Path


def get_sdk_version(sdk_root: Path) -> str:
    """
    Read CFBundleShortVersionString from the SDK Info.plist.

    Raises when the file cannot be read or holds no version, because the
    SDK Version header line must name the SDK release.
    """
    plist_path = sdk_root / "stellarsdk" / "stellarsdk" / "Info.plist"
    try:
        with open(plist_path, 'rb') as f:
            plist = plistlib.load(f)
    except (OSError, plistlib.InvalidFileException) as e:
        raise ValueError(f"Cannot read the SDK version from {plist_path}: {e}") from e
    version = plist.get('CFBundleShortVersionString') if isinstance(plist, dict) else None
    if not isinstance(version, str) or not version.strip():
        raise ValueError(f"{plist_path} has no CFBundleShortVersionString")
    return version
