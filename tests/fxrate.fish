set FIXTURES (dirname (status current-filename))/fixtures

source (dirname (status current-filename))/../functions/fxrate.fish

function curl
    set url    (string split -m1 '?' -- "$argv[-1]")[1]
    set params (string split -m1 '?' -- "$argv[-1]")[2]

    switch "$params"
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

@test "fxrate function exists" (functions -q fxrate) $status -eq 0

@test "Valid date: 2026-07-30" (fxrate 2026-07-30) = "USD/CAD: 2026-07-30: 1.4014"
@test "Valid date: 2026-07-31" (fxrate 2026-07-31) = "USD/CAD: 2026-07-31: 1.4029"
@test "Valid date: 2026-08-01" (fxrate 2026-08-01) = "USD/CAD: 2026-08-01: no data"
@test "Invalid date: 2026-07-32" (fxrate 2026-07-32) = "USD/CAD: 2026-07-32: invalid date"
