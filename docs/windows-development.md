# Windows Development

This repository can be edited from Windows, but iOS build and device validation stay on the Mac mini.

## Layout

- Windows clone: `C:\Users\ueryo\Developer\DriveLog`
- Shared bare repository on NAS from Windows: `ssh://ryosuke@nas/home/ryosuke/git/DriveLog.git`
- Shared bare repository on NAS from Mac: `ssh://ryosuke@192.168.10.121/home/ryosuke/git/DriveLog.git`
- Mac primary working copy: `/Users/ryosuke/Developer/DriveLog`
- Mac validation clone: `/Users/ryosuke/Developer/DriveLog-WindowsValidation`

Do not copy the Mac working directory to Windows with SMB, scp, or rsync. Use Git through the NAS remote.

## Daily Start

```powershell
cd C:\Users\ueryo\Developer\DriveLog
.\tools\windows\Sync-FromNas.ps1
```

Create a feature branch for each change:

```powershell
git switch -c fix/example
```

Do not edit `main` directly from Windows.

## Commit And Push

Before committing:

```powershell
git status
git diff
git diff --cached
```

Push the feature branch to NAS:

```powershell
.\tools\windows\Push-FeatureBranch.ps1
```

or:

```powershell
git push -u nas fix/example
```

## Mac Validation From Windows

After pushing the branch:

```powershell
.\tools\windows\Invoke-MacValidation.ps1 -Branch fix/example
```

This uses the Mac validation clone and does not switch the Mac primary working copy.

## Merge Responsibility

Recommended ownership:

- Windows: edit, commit, and push feature branches.
- Mac: build, test, simulator/device validation, merge to `main`, push `main`.

## Conflict Handling

If Mac and Windows changed the same branch at the same time, stop and inspect:

```powershell
git fetch nas
git status -sb
git log --oneline --decorate --graph --all -20
```

Do not force-push `main`. Do not rewrite shared history unless explicitly approved.

## Never Commit

- `.env`, tokens, passwords, API keys
- SSH private keys
- Apple ID information
- Apple certificates, private keys, provisioning profiles
- Xcode signing/team changes unless the current issue explicitly requires them
- Machine-local logs and temporary files

## What Windows Cannot Validate

Windows cannot run:

- Xcode build
- iOS Simulator
- SwiftUI previews
- UI tests
- CoreLocation runtime behavior
- PhotoKit runtime behavior
- BackgroundTasks runtime behavior
- Device install
- TestFlight upload

Use the Mac validation helper for build/test and the Mac GUI or physical device for runtime checks.

## Mac Codex / tmux

For long-running Mac work:

```bash
ssh mac
tmux new -s drivelog
cd /Users/ryosuke/Developer/DriveLog
```

Detach with `Ctrl-b d`, resume with:

```bash
tmux attach -t drivelog
```

## Recovery

If the Windows clone is confused and has no important local changes:

```powershell
git status
git fetch nas
git switch main
git pull --ff-only nas main
```

If there are local changes, do not delete or reset them without reviewing `git diff` first.
