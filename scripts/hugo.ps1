param(
    [ValidateSet("build", "server", "serve", "dev")]
    [string]$Mode = "build",

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ExtraArgs
)

$cacheDir = if ($env:HUGO_CACHEDIR) {
    $env:HUGO_CACHEDIR
} else {
    Join-Path (Get-Location) ".hugo_cache"
}

New-Item -ItemType Directory -Force -Path $cacheDir | Out-Null
$env:HUGO_CACHEDIR = $cacheDir

if ($Mode -in @("server", "serve", "dev")) {
    & hugo server -D @ExtraArgs
    exit $LASTEXITCODE
}

& hugo --minify --gc @ExtraArgs
exit $LASTEXITCODE
