"""Unit tests for play_upload.py's pure logic (no network, no credentials).

    python3 -m unittest discover scripts
"""

import unittest

from play_upload import DRAFT_APP_ERROR, commit_error_hint, track_body


class TrackBodyTest(unittest.TestCase):
    def test_completed_release(self):
        body = track_body("internal", 22, "completed")
        self.assertEqual(
            body,
            {
                "track": "internal",
                "releases": [{"versionCodes": ["22"], "status": "completed"}],
            },
        )

    def test_draft_release_stringifies_version_code(self):
        body = track_body("production", "23", "draft")
        self.assertEqual(body["releases"][0]["status"], "draft")
        self.assertEqual(body["releases"][0]["versionCodes"], ["23"])


class CommitErrorHintTest(unittest.TestCase):
    def test_hints_on_draft_app_error_with_completed_status(self):
        hint = commit_error_hint(f'{{"message": "{DRAFT_APP_ERROR}"}}', "completed")
        self.assertIn("--status draft", hint)

    def test_no_hint_when_already_uploading_a_draft(self):
        self.assertIsNone(commit_error_hint(DRAFT_APP_ERROR, "draft"))

    def test_no_hint_for_unrelated_errors(self):
        self.assertIsNone(commit_error_hint("quota exceeded", "completed"))


if __name__ == "__main__":
    unittest.main()
