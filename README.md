# fxrate.fish

A [fisher](https://github.com/jorgebucaran/fisher) plugin for fetching US Dollar / Canadian Dollar (USD/CAD) daily average exchange rates from the [Bank of Canada Valet API](https://www.bankofcanada.ca/valet/). Written in fish, requiring only `curl` and `jq`.

## Install

With [fisher](https://github.com/jorgebucaran/fisher):

```shell
fisher install kszakharov/fxrate.fish
```

## Usage

```shell
fxrate [--skip-no-data] [DATE|START..END ...]
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

The command exits with status 1 on a malformed argument or an unreachable/unparseable API response. Invalid-but-well-formed dates are skipped and remaining arguments are still processed.

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
