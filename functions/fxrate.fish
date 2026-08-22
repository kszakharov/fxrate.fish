function fxrate
    if set -q DEBUG
        set -f fish_trace 1
    end

    set pair "USDCAD"
    set label "USD/CAD"
    set base_url "https://www.bankofcanada.ca/valet/observations/FX$pair/json"

    if test (count $argv) -eq 0
        set url "$base_url?recent=1"
        set response (curl -s $url)
        if test -z "$response"
            echo "Error: No response from Bank of Canada API"
            return 1
        end

        set value (echo $response | jq -r ".observations[0].FX$pair.v")
        set date  (echo $response | jq -r ".observations[0].d")

        echo "$label: $date: $value"
        return
    end

    for arg in $argv
        if string match -qr '^\d{4}-\d{2}-\d{2}$' $arg
            if not _fxrate_validate_date $arg
                echo "$label: $arg: invalid date"
                continue
            end

            set start_date $arg
            set end_date $arg
        else if string match -qr '^\d{4}-\d{2}-\d{2}\.\.\d{4}-\d{2}-\d{2}$' $arg
            set start_date (string split '..' $arg)[1]
            set end_date (string split '..' $arg)[2]
            if not _fxrate_validate_date $start_date
                echo "$label: $arg: invalid start date"
                continue
            end

            if not _fxrate_validate_date $end_date
                echo "$label: $arg: invalid end date"
                continue
            end

            if test (string replace -a '-' '' $start_date) -gt \
                    (string replace -a '-' '' $end_date)
                echo "$label: $arg: start date must not be after end date"
                continue
            end
        else
            echo "$label: $arg: invalid date format; please use YYYY-MM-DD or YYYY-MM-DD..YYYY-MM-DD"
            return 1
        end

        set url "$base_url?start_date=$start_date&end_date=$end_date"
        set response (curl -s $url)
        if test -z "$response"
            echo "Error: No response from Bank of Canada API"
            return 1
        end

        for date in (_fxrate_iter_dates $start_date $end_date)
            set value (
                echo $response |
                jq -r --arg date "$date" --arg pair "FX$pair" '(.observations[] | select(.d == $date) | .[$pair].v) // "no data"'
            )

            echo "$label: $date: $value"
        end
    end
end


function _fxrate_validate_date --argument-names date
    if not string match -qr '^\d{4}-\d{2}-\d{2}$' -- $date
        return 1
    end

    # Validate that the date actually exists (e.g. reject 2026-02-30).
    set -l normalized (date -j -f "%Y-%m-%d" $date +%Y-%m-%d 2>/dev/null
        or date -d "$date" +%Y-%m-%d 2>/dev/null)

    test "$normalized" = "$date"
end


function _fxrate_iter_dates --argument-names start end
    # Detect date flavor for platform-specific syntax.
    set -l date_flavor
    if date -v1d >/dev/null 2>&1
        set date_flavor bsd
    else
        set date_flavor gnu
    end

    set -l cur $start
    set -l end_num (string replace -a - '' $end)

    while test (string replace -a '-' '' "$cur") -le $end_num
        echo $cur
        if test $date_flavor = bsd
            set cur (date -j -v+1d -f "%Y-%m-%d" $cur +%Y-%m-%d)
        else
            set cur (date -d "$cur +1 day" +%Y-%m-%d)
        end
    end
end
