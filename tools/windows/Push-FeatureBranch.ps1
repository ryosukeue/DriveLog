[CmdletBinding()]
param(
    [string] $Remote = "nas"
)

$ErrorActionPreference = "Stop"

$branch = (git branch --show-current).Trim()
if (-not $branch) {
    throw "Could not determine current branch."
}
if ($branch -eq "main") {
    throw "Refusing to push main from Windows. Create a feature branch first."
}
if ($branch -notmatch '^[A-Za-z0-9._/-]+$') {
    throw "Invalid branch name. Allowed characters: letters, numbers, '/', '-', '_', '.'."
}

git status -sb
git push -u $Remote $branch
