# Changelog

All notable changes to this project will be documented in this file.

## [0.3.0] - 2026-08-22

### Added

- Date ranges: pass `START..END` (e.g. `fxrate 2026-07-30..2026-08-01`) to print every day in between, inclusive. Ranges can be given in either order (ascending or descending) and print in the order given.
- `DEBUG` environment variable enables fish command tracing, for troubleshooting.
- Date arguments are now validated. A malformed argument (anything other than `YYYY-MM-DD` or `YYYY-MM-DD..YYYY-MM-DD`) prints an error and exits with status 1. A well-formed but nonexistent date (e.g. `2026-02-30`) prints an "invalid date" notice, is skipped, and any remaining arguments are still processed.

### Fixed

- `fxrate` with no arguments now works on Linux. It previously shelled out to `date -v-1d`, a macOS/BSD-only flag; on Linux (GNU `date`) this produced no output at all, so the command silently did nothing. It now asks the Bank of Canada API directly for the most recently published rate.

## [0.2.0] - 2026-08-17

### Changed

- No-data output now includes the currency pair label (e.g., `USD/CAD: 2026-08-01: no data`).

## [0.1.0] - 2026-08-02

### Added

- `fxrate` function to fetch USD/CAD daily average exchange rates from the Bank of Canada Valet API.
- Support for one or more dates as arguments (`YYYY-MM-DD`).
- Defaults to yesterday's rate when no date is provided.
- Prints a notice for days with no published data (weekends, holidays).
- Exits with status 1 on API errors.
