#!/usr/bin/env python3
"""Upload a signed app bundle to a Google Play track.

    scripts/play_upload.py --check                 # verify API access only
    scripts/play_upload.py path/to/app.aab         # upload to internal
    scripts/play_upload.py path/to/app.aab --track production
    scripts/play_upload.py path/to/app.aab --track production --status draft

Auth: the service account JSON at ~/.secrets/play-publisher.json
(monstruous-tasker-manager, invited to the Play Console with Admin), or
whatever PLAY_PUBLISHER_CREDENTIALS points at. Deliberately NOT
GOOGLE_APPLICATION_CREDENTIALS: release.sh exports that for the Firebase
deploy credential, which has no Play access.
"""

import argparse
import os
import sys

import requests

PACKAGE = "com.darumatic.task_monster"
API = f"https://androidpublisher.googleapis.com/androidpublisher/v3/applications/{PACKAGE}"
UPLOAD_API = f"https://androidpublisher.googleapis.com/upload/androidpublisher/v3/applications/{PACKAGE}"

# The API refuses completed releases until the app's first Console publish.
DRAFT_APP_ERROR = "Only releases with status draft may be created on draft app"


def track_body(track: str, version_code, status: str) -> dict:
    return {
        "track": track,
        "releases": [{"versionCodes": [str(version_code)], "status": status}],
    }


def commit_error_hint(resp_text: str, status: str) -> str | None:
    if DRAFT_APP_ERROR in resp_text and status == "completed":
        return (
            "The app is still unpublished (draft app): rerun with --status draft, "
            "then finish the release (name, notes, save) in the Play Console."
        )
    return None


def bearer() -> dict:
    import google.auth.transport.requests
    from google.oauth2 import service_account

    key_file = os.environ.get(
        "PLAY_PUBLISHER_CREDENTIALS",
        os.path.expanduser("~/.secrets/play-publisher.json"),
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
    ap.add_argument(
        "--status",
        default="completed",
        choices=["completed", "draft"],
        help="release status (default: completed; draft apps only accept draft)",
    )
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
        json=track_body(args.track, version_code, args.status),
    )
    if resp.status_code != 200:
        die(resp, f"assigning track {args.track}")

    resp = requests.post(f"{API}/edits/{edit_id}:commit", headers=headers)
    if resp.status_code != 200:
        hint = commit_error_hint(resp.text, args.status)
        if hint:
            print(f"HINT: {hint}", file=sys.stderr)
        die(resp, "committing edit")
    print(f"Released versionCode {version_code} to the {args.track} track ({args.status}).")


if __name__ == "__main__":
    main()
