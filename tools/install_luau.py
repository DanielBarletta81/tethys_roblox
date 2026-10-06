"""Install checksum-pinned official Luau tools locally; no system installation."""
import argparse
import hashlib
import json
import platform
import urllib.request
import zipfile
from io import BytesIO
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--destination', type=Path)
    args = parser.parse_args()
    release = json.loads((ROOT / 'tools/luau-release.json').read_text())
    system = platform.system()
    archive = {'Darwin': 'luau-macos.zip', 'Linux': 'luau-ubuntu.zip'}.get(system)
    if archive is None:
        raise SystemExit('This installer supports macOS/Linux; see the official pinned release for Windows.')
    descriptor = release['archives'][archive]
    expected_url = f"https://github.com/luau-lang/luau/releases/download/{release['version']}/{archive}"
    if descriptor['url'] != expected_url:
        raise SystemExit('Unexpected Luau download URL.')
    with urllib.request.urlopen(descriptor['url'], timeout=60) as response:
        data = response.read()
    if hashlib.sha256(data).hexdigest() != descriptor['sha256']:
        raise SystemExit('Luau archive checksum mismatch; no tools installed.')
    destination = args.destination or ROOT / '.tooling' / ('luau-' + release['version'])
    destination.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(BytesIO(data)) as archive_file:
        for name in ('luau', 'luau-compile'):
            target = destination / name
            target.write_bytes(archive_file.read(name))
            target.chmod(0o755)
    print(f"Verified Luau {release['version']} installed in {destination}")


if __name__ == '__main__':
    main()
