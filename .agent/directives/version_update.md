# Version Update Directive

## Purpose

When the script version is bumped, **all** version references across the repository must be updated to stay in sync. This directive lists every file and location that contains a version string.

## Source of Truth

The canonical version is defined in:

```
script/update_qbittorrent_listening_port.sh → SCRIPT_VERSION="X.Y"
```

The header comment in the same file must match:

```
# Version: X.Y (File-First Port Reading)
```

## Files to Update

When changing the version, update **all** of the following locations:

### 1. Script (source of truth)

**File:** `script/update_qbittorrent_listening_port.sh`

| Line | What to update |
|------|----------------|
| Header comment | `# Version: X.Y (...)` |
| Variable | `SCRIPT_VERSION="X.Y"` |

### 2. README

**File:** `README.md`

| Line | What to update |
|------|----------------|
| Badge | `[![Version](https://img.shields.io/badge/version-X.Y-blue.svg)]` — note: dots become `--` and hyphens become `--` in shields.io badge URLs |
| Quick Links | `*(vX.Y)*` next to the script link |

### 3. Installation Guide

**File:** `docs/installation/setup-gluetun-qbittorrent-port-sync.md`

| Line | What to update |
|------|----------------|
| Header | `**Version:** X.Y` |

### 4. Changelog

**File:** `CHANGELOG.md`

| What to update |
|----------------|
| Add a new `## [X.Y] - YYYY-MM-DD` section under `## [Unreleased]` |
| Add a release link at the bottom: `[X.Y]: https://github.com/RzrZrx/Gluetun-qBittorrent-Port-Updater-Script-For-unRAID/releases/tag/vX.Y` |
| Include a `### Changed` bullet: `- Bumped version from \`OLD\` to \`X.Y\`` |

## Version Format

- Versions use the format `X.Y` (e.g., `3.10`).
- No suffix letters (the `-F`, `-T` convention was dropped starting with v3.10).

## Checklist

When bumping the version, verify:

- [ ] `script/update_qbittorrent_listening_port.sh` — header comment
- [ ] `script/update_qbittorrent_listening_port.sh` — `SCRIPT_VERSION` variable
- [ ] `README.md` — shields.io version badge
- [ ] `README.md` — Quick Links version reference
- [ ] `docs/installation/setup-gluetun-qbittorrent-port-sync.md` — version header
- [ ] `CHANGELOG.md` — new release section + link

## Bug Report Workflow

1. New bug reports go in `docs/issues/new/`
2. Once resolved, move to `docs/issues/responses/` with a descriptive filename
3. Add a `### Fixed` entry in the CHANGELOG under the new version
4. Credit the contributor in the script header and CHANGELOG if applicable

## Contributors

When adding a contributor, add them to the script header block in the format:

```
# Contributor:    name (https://github.com/username) - description of contribution
```
