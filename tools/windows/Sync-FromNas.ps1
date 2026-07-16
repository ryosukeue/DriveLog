[CmdletBinding()]
param(
    [string] $Remote = "nas",
    [string] $Branch = "main"
)

$ErrorActionPreference = "Stop"

git fetch $Remote
git switch $Branch
git pull --ff-only $Remote $Branch
git status -sb
