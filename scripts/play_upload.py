#!/usr/bin/env python3
"""Upload a signed app bundle to a Google Play track.

    scripts/play_upload.py --check                 # verify API access only
    scripts/play_upload.py path/to/app.aab         # upload to internal
    scripts/play_upload.py path/to/app.aab --track production

Auth: the service account JSON pointed at by GOOGLE_APPLICATION_CREDENTIALS
(default: ~/.secrets/task-monster-firebase.json — monster-deployer, which is
also invited to the Play Console with release permission for this app).
"""

import argparse
import os
import sys

import google.auth.transport.requests
import requests
from google.oauth2 import service_account

PACKAGE = "com.darumatic.task_monster"
API = f"https://androidpublisher.googleapis.com/androidpublisher/v3/applications/{PACKAGE}"
UPLOAD_API = f"https://androidpublisher.googleapis.com/upload/androidpublisher/v3/applications/{PACKAGE}"


def bearer() -> dict:
    key_file = os.environ.get(
        "GOOGLE_APPLICATION_CREDENTIALS",
        os.path.expanduser("~/.secrets/task-monster-firebase.json"),
    )
    creds = service_account.Credentials.from_service_account_file(
        key_file, scopes=["https://www.googleapis.com/auth/androidpublisher"]
    )
    creds.refresh(google.auth.transport.requests.Request())
    return {"Authorization": f"Bearer {creds.token}"}


def die(resp: requests.Response, doing: str):
    sys.exit(f"ERROR {doing}: HTTP {resp.status_code}\n{resp.text}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("aab", nargs="?", help="path to the .aab to upload")
    ap.add_argument("--track", default="internal", help="Play track (default: internal)")
    ap.add_argument("--check", action="store_true", help="only verify API access")
    args = ap.parse_args()
    if not args.check and not args.aab:
        ap.error("an .aab path is required unless --check is given")

    headers = bearer()

    resp = requests.post(f"{API}/edits", headers=headers, json={})
    if resp.status_code != 200:
        die(resp, "creating edit (is the service account invited in Play Console, and does the app exist?)")
    edit_id = resp.json()["id"]
    print(f"API access OK — edit {edit_id}")

    if args.check:
        requests.delete(f"{API}/edits/{edit_id}", headers=headers)
        return

    print(f"Uploading {args.aab} ...")
    with open(args.aab, "rb") as f:
        resp = requests.post(
            f"{UPLOAD_API}/edits/{edit_id}/bundles?uploadType=media",
            headers={**headers, "Content-Type": "application/octet-stream"},
            data=f,
            timeout=600,
        )
    if resp.status_code != 200:
        die(resp, "uploading bundle")
    version_code = resp.json()["versionCode"]
    print(f"Uploaded versionCode {version_code}")

    resp = requests.put(
        f"{API}/edits/{edit_id}/tracks/{args.track}",
        headers=headers,
        json={
            "track": args.track,
            "releases": [{"versionCodes": [str(version_code)], "status": "completed"}],
        },
    )
    if resp.status_code != 200:
        die(resp, f"assigning track {args.track}")

    resp = requests.post(f"{API}/edits/{edit_id}:commit", headers=headers)
    if resp.status_code != 200:
        die(resp, "committing edit")
    print(f"Released versionCode {version_code} to the {args.track} track.")


if __name__ == "__main__":
    main()
