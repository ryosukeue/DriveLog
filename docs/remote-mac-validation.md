# Remote Mac Validation

Windows edits are validated on the Mac mini through SSH.

## Command

From the Windows clone:

```powershell
.\tools\windows\Invoke-MacValidation.ps1 -Branch fix/example
```

The branch name is restricted to letters, numbers, `/`, `-`, `_`, and `.` to avoid shell injection.

## Mac Validation Clone

Path:

```text
/Users/ryosuke/Developer/DriveLog-WindowsValidation
```

This clone is disposable and separate from:

```text
/Users/ryosuke/Developer/DriveLog
```

The helper may hard-reset and clean the validation clone only. It must not modify the primary Mac working copy.

## Validation Steps

The helper runs:

```bash
git fetch nas --prune
git switch --force-create <branch> nas/<branch>
git reset --hard nas/<branch>
git clean -fdx
git diff --check
./scripts/build.sh
./scripts/test.sh
swiftlint lint --strict
swiftformat --lint .
```

## After Success

On Mac, merge intentionally:

```bash
cd /Users/ryosuke/Developer/DriveLog
git fetch nas
git switch main
git pull --ff-only nas main
git switch <branch>
git pull --ff-only nas <branch>
```

Then merge according to the issue's workflow. Run build/test again before pushing `main`.

## Device Install

Use Xcode on Mac for simulator or physical device install. Do not move signing material to Windows.
