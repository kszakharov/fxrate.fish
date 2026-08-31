# fxrate.fish

A [fisher](https://github.com/jorgebucaran/fisher) plugin for fetching daily average exchange rates from the [Bank of Canada Valet API](https://www.bankofcanada.ca/valet/).
Supports currency pairs where CAD is either the base or quote currency, e.g. USD/CAD, EUR/CAD, and CAD/USD.
Written in fish, requiring only `curl` and `jq`.

## Install

With [fisher](https://github.com/jorgebucaran/fisher):

```shell
fisher install kszakharov/fxrate.fish
```

## Usage

```shell
fxrate [-h] [--available-pairs] [--skip-no-data] [--pair PAIR ...] [DATE|START..END ...]
```

### Arguments

| Argument            | Description                                                                                                                                                                                                            |
| ------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `DATE`              | A single date (`YYYY-MM-DD`) to query. Repeatable — pass several to query multiple days, and freely mix with `START..END` ranges.                                                                                      |
| `START..END`        | A date range (`YYYY-MM-DD..YYYY-MM-DD`) to query every day in between, inclusive. Printed in the order given (ascending or descending). Repeatable — pass several ranges, and freely mix with single `DATE` arguments. |
| `--pair PAIR`       | FX currency pair to query, e.g. `USDCAD` or `EUR/CAD`. Must contain CAD as either the base or quote currency. Repeatable to fetch several pairs in one request. Defaults to `USDCAD` if omitted.                       |
| `--skip-no-data`    | Omit days with no published rate (weekends, holidays) instead of printing a "no data" notice.                                                                                                                          |
| `--available-pairs` | List every currency pair the Bank of Canada Valet API publishes rates for, then exit without querying any dates.                                                                                                       |
| `-h`, `--help`      | Print usage information and exit.                                                                                                                                                                                      |

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

The pair must consist of two three-letter currency codes. `/` is also accepted between the currency codes:

```shell
$ fxrate --pair EUR/CAD
EUR/CAD: 2026-07-30: 1.6136
```

CAD must be either the **base currency** or **quote currency**. Pairs that do not contain CAD are unsupported:

```shell
$ fxrate --pair EURGBP
Error: unsupported pair: EURGBP; CAD must be the base or quote currency, e.g. USDCAD or CADUSD
```

Input is normalized to uppercase before validation, so lowercase currency codes are accepted:

```shell
$ fxrate --pair eurcad
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

A pair with an invalid format stops execution before any request is made:

```shell
$ fxrate --pair EURCA
Error: invalid pair: EURCA; please use three-letter currency codes, e.g. USDCAD or USD/CAD
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

Pass `--available-pairs` to list every currency pair the Bank of Canada Valet API publishes rates for, then exit without querying any dates:

```shell
$ fxrate --available-pairs
AUDCAD - rate of the Australian dollar expressed in Canadian dollars, for 1 unit of Australian dollar
BRLCAD - rate of the Brazilian real expressed in Canadian dollars, for 1 unit of Brazilian real
CADAUD - rate of the Canadian dollar expressed in Australian dollars, for 1 unit of Canadian dollar
...
```

If the API cannot be reached or returns no usable data, an error is printed:

```shell
$ fxrate
Error: No response from Bank of Canada API
```

The command exits with status 1 on a malformed argument, an unsupported `--pair` value, or an unreachable/unparseable API response.
Invalid-but-well-formed dates are skipped and remaining arguments are still processed.
`--available-pairs` follows the same rule: status 1 if the API is unreachable, 0 otherwise.

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
