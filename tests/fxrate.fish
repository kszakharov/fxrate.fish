set FIXTURES (dirname (status current-filename))/fixtures

source (dirname (status current-filename))/../functions/fxrate.fish

function curl
    set url    (string split -m1 '?' -- "$argv[-1]")[1]
    set params (string split -m1 '?' -- "$argv[-1]")[2]

    switch "$params"
        case "recent=1"
            cat "$FIXTURES/response recent.json"
        case "start_date=*&end_date=*"
            set dates (string match -r -g 'start_date=([0-9-]+)&end_date=([0-9-]+)' "$params")
            set start_date $dates[1]
            set end_date $dates[2]
            cat "$FIXTURES/response $start_date - $end_date.json"
        case *
            echo "Error: Unexpected URL: $url"
            exit 1
    end
end

@test "sanity: fxrate function exists" (functions -q fxrate) $status -eq 0

@test "no args, valid, has data" (fxrate) = "USD/CAD: 2026-08-21: 1.3760"

@test "single date, valid, has data: 2026-07-30" (fxrate 2026-07-30) = "USD/CAD: 2026-07-30: 1.4014"
@test "single date, valid, has data: 2026-07-31" (fxrate 2026-07-31) = "USD/CAD: 2026-07-31: 1.4029"
@test "single date, valid, no data: 2026-08-01"  (fxrate 2026-08-01) = "USD/CAD: 2026-08-01: no data"
@test "single date, invalid, bad date: 2026-07-32"  (fxrate 2026-07-32) = "USD/CAD: 2026-07-32: invalid date"

@test "date range, valid, single-day range: 2026-07-30..2026-07-30"  (echo (fxrate 2026-07-30..2026-07-30)) = "USD/CAD: 2026-07-30: 1.4014"
@test "date range, valid, multi-day range: 2026-07-30..2026-07-31"   (echo (fxrate 2026-07-30..2026-07-31)) = "USD/CAD: 2026-07-30: 1.4014 USD/CAD: 2026-07-31: 1.4029"
@test "date range, valid, reversed: 2026-07-31..2026-07-30" (echo (fxrate 2026-07-31..2026-07-30)) = "USD/CAD: 2026-07-31: 1.4029 USD/CAD: 2026-07-30: 1.4014"
@test "date range, invalid, bad start date: 2026-07-32..2026-07-30"  (echo (fxrate 2026-07-32..2026-07-30)) = "USD/CAD: 2026-07-32..2026-07-30: invalid start date"
@test "date range, invalid, bad end date: 2026-07-30..2026-07-32"    (echo (fxrate 2026-07-30..2026-07-32)) = "USD/CAD: 2026-07-30..2026-07-32: invalid end date"
