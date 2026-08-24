# fxrate.fish

A [fisher](https://github.com/jorgebucaran/fisher) plugin for fetching daily average exchange rates from the [Bank of Canada Valet API](https://www.bankofcanada.ca/valet/). Any published pair works, e.g. USD/CAD, EUR/CAD, GBP/JPY. Written in fish, requiring only `curl` and `jq`.

## Install

With [fisher](https://github.com/jorgebucaran/fisher):

```shell
fisher install kszakharov/fxrate.fish
```

## Usage

```shell
fxrate [--skip-no-data] [--pair PAIR ...] [DATE|START..END ...]
```

With no arguments, `fxrate` prints recent rate:

```shell
$ fxrate
USD/CAD: 2026-07-30: 1.4014
```

Pass one or more dates (`YYYY-MM-DD`) to query specific days:

```shell
$ fxrate 2026-07-30
USD/CAD: 2026-07-30: 1.4014
```

```shell
$ fxrate 2026-07-30 2026-07-31
USD/CAD: 2026-07-30: 1.4014
USD/CAD: 2026-07-31: 1.4029
```

Pass a date range (`YYYY-MM-DD..YYYY-MM-DD`) to query every day in between:

```shell
$ fxrate 2026-07-30..2026-08-01
USD/CAD: 2026-07-30: 1.4014
USD/CAD: 2026-07-31: 1.4029
USD/CAD: 2026-08-01: no data
```

Days with no published rate (weekends, holidays) print a notice:

```shell
$ fxrate 2026-08-01
USD/CAD: 2026-08-01: no data
```

Pass `--skip-no-data` to omit those days entirely instead, e.g. when scanning a range for the last available rate:

```shell
$ fxrate --skip-no-data 2026-07-30..2026-08-01
USD/CAD: 2026-07-30: 1.4014
USD/CAD: 2026-07-31: 1.4029
```

Pass a pair with `--pair` to query something other than USD/CAD:

```shell
$ fxrate --pair EURCAD
EUR/CAD: 2026-07-30: 1.6136
```

Repeat `--pair` to fetch several pairs in one request; each date prints all pairs together in flag order:

```shell
$ fxrate --pair EURCAD --pair USDCAD 2026-07-30..2026-07-31
EUR/CAD: 2026-07-30: 1.6136
USD/CAD: 2026-07-30: 1.4014
EUR/CAD: 2026-07-31: 1.6145
USD/CAD: 2026-07-31: 1.4029
```

A pair that is not six uppercase letters stops execution before any request is made:

```shell
$ fxrate --pair eurgbp
Error: invalid pair: eurgbp; please use six-letter currency codes, e.g. EURCAD
```

Invalid dates print a notice and are skipped; malformed arguments stop execution:

```shell
$ fxrate 2026-07-32
USD/CAD: 2026-07-32: invalid date
```

```shell
$ fxrate not-a-date
USD/CAD: not-a-date: invalid date format; please use YYYY-MM-DD or YYYY-MM-DD..YYYY-MM-DD
```

If the API cannot be reached or returns no usable data, an error is printed:

```shell
$ fxrate
Error: No response from Bank of Canada API
```

The command exits with status 1 on a malformed argument, an invalid `--pair` value, or an unreachable/unparseable API response. Invalid-but-well-formed dates are skipped and remaining arguments are still processed.

## Debugging

Set `DEBUG` to enable fish command tracing:

```shell
$ DEBUG=1 fxrate 2026-07-30
```

## Requirements

- `fish`
- `jq`
- `curl`

## Testing

Run the test suite with [fishtape](https://github.com/jorgebucaran/fishtape):

```shell
fishtape tests/*.fish
```

Tests mock `curl` and require no network access.
