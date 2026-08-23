function fxrate
    if set -q DEBUG
        set -f fish_trace 1
    end

    argparse 'skip-no-data' -- $argv
    or return 1

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
        set -l start_date
        set -l end_date
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
        else
            echo "$label: $arg: invalid date format; please use YYYY-MM-DD or YYYY-MM-DD..YYYY-MM-DD"
            return 1
        end

        # Bank of Canada API requires start_date <= end_date; the chronological
        # query bounds are derived independently of the order dates are printed in.
        set -l query_start $start_date
        set -l query_end $end_date
        if test (string replace -a '-' '' $start_date) -gt \
                (string replace -a '-' '' $end_date)
            set query_start $end_date
            set query_end $start_date
        end

        set url "$base_url?start_date=$query_start&end_date=$query_end"
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

            if set -q _flag_skip_no_data
                and test "$value" = "no data"
                continue
            end

            echo "$label: $date: $value"
        end
    end
end


function _fxrate_validate_date --argument-names date
    if not string match -qr '^\d{4}-\d{2}-\d{2}$' -- $date
        return 1
    end

    set -l normalized (date -j -f "%Y-%m-%d" $date +%Y-%m-%d 2>/dev/null
        or date -d "$date" +%Y-%m-%d 2>/dev/null)

    test "$normalized" = "$date"
end


# Prints every date from $from to $to inclusive: ascending if from < to,
# descending if from > to, a single date if from == to.
function _fxrate_iter_dates --argument-names from to
    set -l date_flavor
    if date -v1d >/dev/null 2>&1
        set date_flavor bsd
    else
        set date_flavor gnu
    end

    set -l to_num (string replace -a '-' '' $to)
    set -l step "+1"
    if test (string replace -a '-' '' $from) -gt $to_num
        set step "-1"
    end

    set -l cur $from
    while true
        echo $cur
        if test (string replace -a '-' '' $cur) -eq $to_num
            break
        end

        if test $date_flavor = bsd
            set cur (date -j -v"$step"d -f "%Y-%m-%d" $cur +%Y-%m-%d)
        else
            set cur (date -d "$cur $step day" +%Y-%m-%d)
        end
    end
end
