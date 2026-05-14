# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Repository organization and standardization
- `.gitignore` file
- `CONTRIBUTING.md` guidelines
- GitHub issue and PR templates
- This changelog

### Changed
- Restructured directories to follow Unix conventions (lowercase)
- Renamed `Setup/` to `docs/` for better discoverability
- Standardized documentation filenames to lowercase-with-hyphens
- Organized setup guides into `docs/installation/` subdirectory
- Updated README.md with corrected links and improved structure

---

## [3.10] - 2026-05-14

### Fixed
- **qBittorrent 5.x Login Failure:** qBittorrent 4.6+/5.x changed `/api/v2/auth/login` from returning `"Ok."` (HTTP 200) to an empty body (HTTP 204 No Content). The `qb_login()` function now detects success by the presence of a `QBT_SID` cookie in the cookie jar instead of checking the response body. This is version-agnostic and works with both old and new qBittorrent versions. (Fix by u/ddavidtran)

### Changed
- Bumped version from `3.9-F` to `3.10`
- Removed `-f` (fail silently) flag from login curl call to prevent suppression of HTTP 204 responses
- Added `-o /dev/null` to discard response body explicitly

---

## [3.9-F] - 2026-03-08

### Fixed
- **Gluetun API Deadlock:** Newer Gluetun versions deadlock when the up-command script calls `GET /v1/portforward` (lock inversion). Script now reads the port from `/tmp/gluetun/forwarded_port` first (file-first strategy), with the API as a fallback for manual runs only.
- **Windows Line Endings (CRLF):** Scripts edited on Windows had `\r\n` line endings causing `not found` errors on Alpine Linux due to `#!/bin/sh\r` shebang. Fixed by converting to LF line endings.

### Added
- `.gitattributes` to enforce LF line endings for `*.sh` files across all platforms
- `PORT_FILE` variable (`/tmp/gluetun/forwarded_port`) for file-based port reading
- Detailed bug report: [gluetun-api-deadlock-portforward.md](docs/issues/responses/gluetun-api-deadlock-portforward.md)

### Changed
- Bumped version from `3.8-T` to `3.9-F`
- Increased `CURL_TIMEOUT` from `15` to `30` seconds (for API fallback path)

---

## [3.8-T] - Current Release

### Features
- Automatic synchronization of qBittorrent listening port with Gluetun forwarded port
- Web API authentication with qBittorrent
- Error handling and logging
- Support for major VPN providers (PIA, ProtonVPN, etc.)
- Compatible with Unraid 6.12.14 and Unraid 7

### Requirements
- Gluetun container with port forwarding enabled
- qBittorrent container using Gluetun's network stack
- qBittorrent Web UI enabled with authentication

---

## Previous Versions

Previous versions are available in the `deprecated/` directory for reference.

---

[Unreleased]: https://github.com/RzrZrx/Gluetun-qBittorrent-Port-Updater-Script-For-unRAID/compare/main...HEAD
[3.10]: https://github.com/RzrZrx/Gluetun-qBittorrent-Port-Updater-Script-For-unRAID/releases/tag/v3.10
[3.9-F]: https://github.com/RzrZrx/Gluetun-qBittorrent-Port-Updater-Script-For-unRAID/releases/tag/v3.9-F
[3.8-T]: https://github.com/RzrZrx/Gluetun-qBittorrent-Port-Updater-Script-For-unRAID/releases/tag/v3.8-T
