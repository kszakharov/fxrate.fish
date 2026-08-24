set FIXTURES (dirname (status current-filename))/fixtures

source (dirname (status current-filename))/../functions/fxrate.fish

function curl
    set url    (string split -m1 '?' -- "$argv[-1]")[1]
    set params (string split -m1 '?' -- "$argv[-1]")[2]

    set series (string match -r -g '/observations/FX([A-Z,]+)/json' "$url" |
        string split ',' | string replace -r '^FX' '' | string join '+')

    switch "$params"
        case "recent=1"
            cat "$FIXTURES/recent_$series.json"
        case "start_date=*&end_date=*"
            set dates (string match -r -g 'start_date=([0-9-]+)&end_date=([0-9-]+)' "$params")
            set start_date $dates[1]
            set end_date $dates[2]
            cat "$FIXTURES/$start_date"_"$end_date"_$series.json
        case *
            echo "Error: Unexpected URL: $url"
            exit 1
    end
end

@test "sanity: fxrate function exists" (functions -q fxrate) $status -eq 0

@test "no args, valid, has data" (fxrate) = "USD/CAD: 2026-07-30: 1.4014"

@test "single date, valid, has data: 2026-07-30"   (fxrate 2026-07-30) = "USD/CAD: 2026-07-30: 1.4014"
@test "single date, valid, has data: 2026-07-31"   (fxrate 2026-07-31) = "USD/CAD: 2026-07-31: 1.4029"
@test "single date, valid, no data: 2026-08-01"    (fxrate 2026-08-01) = "USD/CAD: 2026-08-01: no data"
@test "single date, invalid, bad date: 2026-07-32" (fxrate 2026-07-32) = "USD/CAD: 2026-07-32: invalid date"

@test "date range, valid, single-day range: 2026-07-30..2026-07-30" (echo (fxrate 2026-07-30..2026-07-30)) = "USD/CAD: 2026-07-30: 1.4014"
@test "date range, valid, multi-day range: 2026-07-30..2026-07-31"  (echo (fxrate 2026-07-30..2026-07-31)) = "USD/CAD: 2026-07-30: 1.4014 USD/CAD: 2026-07-31: 1.4029"
@test "date range, valid, reversed: 2026-07-31..2026-07-30"         (echo (fxrate 2026-07-31..2026-07-30)) = "USD/CAD: 2026-07-31: 1.4029 USD/CAD: 2026-07-30: 1.4014"
@test "date range, invalid, bad start date: 2026-07-32..2026-07-30" (echo (fxrate 2026-07-32..2026-07-30)) = "USD/CAD: 2026-07-32..2026-07-30: invalid start date"
@test "date range, invalid, bad end date: 2026-07-30..2026-07-32"   (echo (fxrate 2026-07-30..2026-07-32)) = "USD/CAD: 2026-07-30..2026-07-32: invalid end date"

@test "flag --skip-no-data, no args, has no effect on recent"                           (echo (fxrate --skip-no-data))                        = "USD/CAD: 2026-07-30: 1.4014"
@test "flag --skip-no-data, single date, has data: 2026-07-30"                          (echo (fxrate --skip-no-data 2026-07-30))             = "USD/CAD: 2026-07-30: 1.4014"
@test "flag --skip-no-data, single date, no data is omitted: 2026-08-01"                (echo (fxrate --skip-no-data 2026-08-01))             = ""
@test "flag --skip-no-data, date range, no-data day is omitted: 2026-07-30..2026-08-01" (echo (fxrate --skip-no-data 2026-07-30..2026-08-01)) = "USD/CAD: 2026-07-30: 1.4014 USD/CAD: 2026-07-31: 1.4029"

@test "flag --pair, recent, single custom pair"                             (fxrate --pair EURCAD) = "EUR/CAD: 2026-07-30: 1.6136"
@test "flag --pair, single date, single custom pair: 2026-07-30"            (fxrate --pair EURCAD 2026-07-30) = "EUR/CAD: 2026-07-30: 1.6136"
@test "flag --pair, date range, single custom pair: 2026-07-30..2026-07-31" (echo (fxrate --pair EURCAD 2026-07-30..2026-07-31)) = "EUR/CAD: 2026-07-30: 1.6136 EUR/CAD: 2026-07-31: 1.6145"

@test "flag --pair, explicit USDCAD matches default output, recent"     (fxrate --pair USDCAD) = "USD/CAD: 2026-07-30: 1.4014"
@test "flag --pair, explicit USDCAD matches default output, date range" (echo (fxrate --pair USDCAD 2026-07-30..2026-07-31)) = "USD/CAD: 2026-07-30: 1.4014 USD/CAD: 2026-07-31: 1.4029"

@test "flag --pair, repeated, respects flag order: EURCAD then USDCAD" (echo (fxrate --pair EURCAD --pair USDCAD 2026-07-30..2026-07-31)) = "EUR/CAD: 2026-07-30: 1.6136 USD/CAD: 2026-07-30: 1.4014 EUR/CAD: 2026-07-31: 1.6145 USD/CAD: 2026-07-31: 1.4029"
@test "flag --pair, repeated, respects flag order: USDCAD then EURCAD" (echo (fxrate --pair USDCAD --pair EURCAD 2026-07-30..2026-07-31)) = "USD/CAD: 2026-07-30: 1.4014 EUR/CAD: 2026-07-30: 1.6136 USD/CAD: 2026-07-31: 1.4029 EUR/CAD: 2026-07-31: 1.6145"

@test "flag --pair, repeated, multi-pair range prints date-major with flag-order pairs" (echo (fxrate --pair EURCAD --pair USDCAD 2026-07-31..2026-07-30)) = "EUR/CAD: 2026-07-31: 1.6145 USD/CAD: 2026-07-31: 1.4029 EUR/CAD: 2026-07-30: 1.6136 USD/CAD: 2026-07-30: 1.4014"

@test "flag --pair, repeated, range prints no data for missing series on a day" (echo (fxrate --pair USDCAD --pair EURCAD 2026-07-30..2026-08-01)) = "USD/CAD: 2026-07-30: 1.4014 EUR/CAD: 2026-07-30: 1.6136 USD/CAD: 2026-07-31: 1.4029 EUR/CAD: 2026-07-31: 1.6145 USD/CAD: 2026-08-01: no data EUR/CAD: 2026-08-01: no data"
@test "flag --pair + --skip-no-data, repeated, range omits exactly the no-data lines" (echo (fxrate --skip-no-data --pair USDCAD --pair EURCAD 2026-07-30..2026-08-01)) = "USD/CAD: 2026-07-30: 1.4014 EUR/CAD: 2026-07-30: 1.6136 USD/CAD: 2026-07-31: 1.4029 EUR/CAD: 2026-07-31: 1.6145"

@test "flag --pair, invalid, lowercase is rejected"       (fxrate --pair eurgbp)            = "Error: invalid pair: eurgbp; please use six-letter currency codes, e.g. EURCAD"
@test "flag --pair, invalid, wrong length is rejected"    (fxrate --pair EURCA)             = "Error: invalid pair: EURCA; please use six-letter currency codes, e.g. EURCAD"
@test "flag --pair, invalid, exits 1"                     (fxrate --pair eurgbp >/dev/null) $status -eq 1
@test "flag --pair, invalid, rejected before any request" (fxrate --pair eurgbp 2026-07-30) = "Error: invalid pair: eurgbp; please use six-letter currency codes, e.g. EURCAD"
