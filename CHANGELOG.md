# Changelog

All notable changes to this project will be documented in this file.

## [0.1.0] - 2026-08-02

### Added

- `fxrate` function to fetch USD/CAD daily average exchange rates from the Bank of Canada Valet API.
- Support for one or more dates as arguments (`YYYY-MM-DD`).
- Defaults to yesterday's rate when no date is provided.
- Prints a notice for days with no published data (weekends, holidays).
- Exits with status 1 on API errors.
