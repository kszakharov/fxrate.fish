function _fxrate_iter_dates --argument-names start end
    set -l cur $start
    set -l end_num (string replace -a - '' $end)
    while test (string replace -a '-' '' "$cur") -le $end_num
        echo $cur
        # Advance by one day; try macOS/BSD date first, then GNU date.
        set cur (date -j -v+1d -f "%Y-%m-%d" $cur +%Y-%m-%d 2>/dev/null
            or date -d "$cur +1 day" +%Y-%m-%d)
    end
end


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
        exit 0
    end

    for arg in $argv
        if string match -qr '^\d{4}-\d{2}-\d{2}$' $arg
            set start_date $arg
            set end_date $arg
        else if string match -qr '^\d{4}-\d{2}-\d{2}\.\.\d{4}-\d{2}-\d{2}$' $arg
            set start_date (string split '..' $arg)[1]
            set end_date (string split '..' $arg)[2]
        else
            echo "Error: Invalid date format. Please use YYYY-MM-DD."
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
