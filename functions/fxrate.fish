function fxrate
    set pair "USDCAD"
    set label "USD/CAD"
    set base_url "https://www.bankofcanada.ca/valet/observations/FX$pair/json"

    if test (count $argv) -eq 0
        set -a argv (date -v-1d "+%Y-%m-%d")
    end

    for req_date in $argv
        set url "$base_url?start_date=$req_date&end_date=$req_date"
        set response (curl -s $url)
        if test -z "$response"
            echo "Error: No response from Bank of Canada API"
            return 1
        end

        set value (echo $response | jq -r ".observations[0].FX$pair.v")
        set date  (echo $response | jq -r ".observations[0].d")

        if test "$value" = "null" -o -z "$value"
            echo "$label: $req_date: no data"
        else
            echo "$label: $date: $value"
        end
    end
end
