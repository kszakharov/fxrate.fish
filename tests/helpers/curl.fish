set FIXTURES (dirname (status current-filename))/../fixtures

function curl
    set url    (string split -m1 '?' -- "$argv[-1]")[1]
    set params (string split -m1 '?' -- "$argv[-1]")[2]

    switch "$url"
        case "https://www.bankofcanada.ca/valet/lists/series/json"
            cat "$FIXTURES/series.json"
        case "https://www.bankofcanada.ca/valet/observations/FX*/json"
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
                    echo "Error: Unsupported request: $url?$params"
                    exit 1
            end
        case *
            echo "Error: Unexpected URL: $url"
            exit 1
    end
end
