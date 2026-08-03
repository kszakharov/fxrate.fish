# fxrate.fish

A [fisher](https://github.com/jorgebucaran/fisher) plugin for fetching US Dollar / Canadian Dollar (USD/CAD) daily average exchange rates from the [Bank of Canada Valet API](https://www.bankofcanada.ca/valet/). Written in fish, requiring only `curl` and `jq`.

## Install

With [fisher](https://github.com/jorgebucaran/fisher):

```shell
fisher install kszakharov/fxrate.fish
```

## Usage

```shell
fxrate [DATE ...]
```

With no arguments, `fxrate` prints yesterday's rate:

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

Days with no published rate (weekends, holidays) print a notice:

```shell
$ fxrate 2026-08-01
USD/CAD: 2026-08-01: no data
```

If the API cannot be reached or returns no usable data, an error is printed:

```shell
$ fxrate
Error: No response from Bank of Canada API
```

The command exits with status 1 whenever any error occurs (invalid date, missing `jq`, unreachable API, unparseable response); when multiple dates are given, the remaining dates are still processed.

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
