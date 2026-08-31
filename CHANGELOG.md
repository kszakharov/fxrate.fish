# Changelog

All notable changes to this project will be documented in this file.

## [0.4.0] - 2026-08-30

### Added

- `--skip-no-data` flag to omit lines for dates with no published rate, instead of printing a "no data" notice — e.g. when scanning a range for the last available rate: `fxrate --skip-no-data 2026-07-30..2026-08-01`.
- `--pair` flag (repeatable) to query currency pairs other than the default USD/CAD, e.g. `fxrate --pair EURCAD`. CAD must be the base or quote currency (e.g. `USDCAD` or `CADUSD`); pairs without CAD are rejected. Input is case-insensitive and a `/` separator is accepted (e.g. `EUR/CAD`). Repeat the flag to query several pairs at once — each date prints all requested pairs together, in the order the flags were given.
- `--available-pairs` flag to list every currency pair the Bank of Canada Valet API publishes involving CAD, noting which are reciprocal or historical series, then exit without querying any dates.

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

[0.4.0]: https://github.com/kszakharov/fxrate.fish/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/kszakharov/fxrate.fish/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/kszakharov/fxrate.fish/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/kszakharov/fxrate.fish/releases/tag/v0.1.0
