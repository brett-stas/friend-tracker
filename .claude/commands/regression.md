Run the full regression suite for the Friend Tracker app and report results.

Execute these steps in order:

## Step 1 — Static analysis
Run `flutter analyze` and report any errors or warnings. If there are errors, list each one with its file and line number.

## Step 2 — Unit & widget tests
Run `flutter test test/unit test/widget --reporter expanded` and report:
- Total tests passed / failed
- Any failing test names and their error messages
- Any new failures compared to the last known baseline of 77 passing tests

## Step 3 — Summary
After both steps, print a clear PASS or FAIL verdict:
- **PASS** — analyze clean + all tests green
- **FAIL** — list every issue found

If anything fails, suggest the likely cause and next steps to fix it.
