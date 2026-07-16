[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $Branch,

    [string] $MacHost = "mac",
    [string] $ValidationPath = "/Users/ryosuke/Developer/DriveLog-WindowsValidation",
    [string] $NasRemote = "ssh://ryosuke@192.168.10.121/home/ryosuke/git/DriveLog.git"
)

$ErrorActionPreference = "Stop"

if ($Branch -notmatch '^[A-Za-z0-9._/-]+$') {
    throw "Invalid branch name. Allowed characters: letters, numbers, '/', '-', '_', '.'."
}

$remoteScript = @'
set -eu
branch="$1"
validation_path="$2"
nas_remote="$3"

if [ ! -d "$validation_path/.git" ]; then
  parent="$(dirname "$validation_path")"
  mkdir -p "$parent"
  git clone --origin nas "$nas_remote" "$validation_path"
fi

cd "$validation_path"

if ! git remote | grep -qx nas; then
  git remote add nas "$nas_remote"
fi

current_url="$(git remote get-url nas)"
if [ "$current_url" != "$nas_remote" ]; then
  git remote set-url nas "$nas_remote"
fi

git fetch nas --prune

if ! git show-ref --verify --quiet "refs/remotes/nas/$branch"; then
  echo "Branch not found on NAS remote: $branch" >&2
  exit 20
fi

git switch --force-create "$branch" "nas/$branch"
git reset --hard "nas/$branch"
git clean -fdx

echo "== status =="
git status -sb
echo "== diff check =="
git diff --check
echo "== build =="
./scripts/build.sh
echo "== test =="
./scripts/test.sh
echo "== swiftlint =="
swiftlint lint --strict
echo "== swiftformat =="
swiftformat --lint .
echo "== validation complete =="
'@

$remoteScript | ssh $MacHost "bash -s -- '$Branch' '$ValidationPath' '$NasRemote'"
