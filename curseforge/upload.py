# -*- coding: utf-8 -*-
"""Upload the release zip. Needs env CF_TOKEN and CF_PROJECT_ID. Never commit the token."""
import json
import os
import sys
import urllib.error
import urllib.request
from pathlib import Path

ZIP = Path(r"F:\Github\addons\wow\WoWForeverRot-1.5.7.zip")
CHANGELOG = Path(__file__).with_name("CHANGELOG.md")
# Forever / camelot, from GET https://wow.curseforge.com/api/game/versions
GAME_VERSION_IDS = [17053]


def main():
    token = os.environ.get("CF_TOKEN")
    project = os.environ.get("CF_PROJECT_ID")
    if not token or not project:
        print("Set CF_TOKEN and CF_PROJECT_ID", file=sys.stderr)
        sys.exit(2)
    if not ZIP.is_file():
        print("missing zip", ZIP, file=sys.stderr)
        sys.exit(2)
    metadata = {
        "changelog": CHANGELOG.read_text(encoding="utf-8"),
        "changelogType": "markdown",
        "displayName": "WoWForeverRot 1.5.7",
        "gameVersions": GAME_VERSION_IDS,
        "releaseType": "release",
    }
    boundary = "----WFRBoundary7f3a9c"
    meta = json.dumps(metadata).encode("utf-8")
    raw = ZIP.read_bytes()
    body = b""
    body += f"--{boundary}\r\n".encode()
    body += b'Content-Disposition: form-data; name="metadata"\r\n'
    body += b"Content-Type: application/json\r\n\r\n"
    body += meta + b"\r\n"
    body += f"--{boundary}\r\n".encode()
    body += b'Content-Disposition: form-data; name="file"; filename="WoWForeverRot-1.5.7.zip"\r\n'
    body += b"Content-Type: application/zip\r\n\r\n"
    body += raw + b"\r\n"
    body += f"--{boundary}--\r\n".encode()
    url = f"https://wow.curseforge.com/api/projects/{project}/upload-file"
    req = urllib.request.Request(
        url,
        data=body,
        method="POST",
        headers={
            "X-Api-Token": token,
            "Content-Type": f"multipart/form-data; boundary={boundary}",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=120) as r:
            print(r.read().decode())
    except urllib.error.HTTPError as e:
        print("HTTP", e.code, e.read()[:2000].decode("utf-8", "replace"), file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
