# Portable installation helpers (PortableApps.com directory layout).
#
# Layout of one portable installation, directly below $portabledir:
#   <id>\App\            extracted application files (manifest '$dir')
#   <id>\Data\           application data (manifest '$persist_dir', not linked)
#   <id>\Other\Scoop\    scoop-manifest.json, scoop-install.json
#
# These helpers only compute paths and inspect the disk; they never change
# the meaning of appdir/versiondir/persistdir used by normal installations.

function Assert-PortableDir {
    if (!$portabledir) {
        abort "Portable directory is not configured.`nSet the SCOOP_PORTABLE environment variable or run: scoop config PORTABLE_PATH <path>"
    }
}

# Plain app name of an app spec ('bucket/app', path or URL -> 'app'), same normalisation as ensure_none_failed.
# Needed because Get-Dependency returns 'bucket/app' while the user typed 'app'.
function Get-AppBaseName($spec) {
    return ($spec -split '/|\\')[-1] -replace '\.json$', ''
}

# Installed identity of a portable app: '<app>_v<version>'.
# Manifests that already carry the version in their name (e.g. 'NotepadPlusPlus_v8.6')
# are not suffixed a second time.
function Get-PortableId($app, $version) {
    $app = sanitary_path $app
    $suffix = "_v$version"
    if ($app.EndsWith($suffix, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $app
    }
    return "$app$suffix"
}

function Get-PortableRootDir($id) { "$portabledir\$(sanitary_path $id)" }
function Get-PortableAppDir($id) { "$(Get-PortableRootDir $id)\App" }
function Get-PortableDataDir($id) { "$(Get-PortableRootDir $id)\Data" }
function Get-PortableMetaDir($id) { "$(Get-PortableRootDir $id)\Other\Scoop" }

# A directory counts as a Scoop portable installation only if it has our install info.
function Test-PortableInstalled($id) {
    if (!$portabledir) { return $false }
    return Test-Path "$(Get-PortableMetaDir $id)\scoop-install.json" -PathType Leaf
}

function Get-PortableInstalled {
    if (!$portabledir -or !(Test-Path $portabledir -PathType Container)) { return @() }
    return @(Get-ChildItem $portabledir -Directory | Where-Object { Test-PortableInstalled $_.Name } | ForEach-Object { $_.Name })
}
