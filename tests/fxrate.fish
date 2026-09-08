source (dirname (status current-filename))/helpers/curl.fish
source (dirname (status current-filename))/../functions/fxrate.fish

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

@test "flag --pair, repeated, reversed range still prints date-major in flag order" (echo (fxrate --pair EURCAD --pair USDCAD 2026-07-31..2026-07-30)) = "EUR/CAD: 2026-07-31: 1.6145 USD/CAD: 2026-07-31: 1.4029 EUR/CAD: 2026-07-30: 1.6136 USD/CAD: 2026-07-30: 1.4014"

@test "flag --pair, repeated, range prints no data for missing series on a day" (echo (fxrate --pair USDCAD --pair EURCAD 2026-07-30..2026-08-01)) = "USD/CAD: 2026-07-30: 1.4014 EUR/CAD: 2026-07-30: 1.6136 USD/CAD: 2026-07-31: 1.4029 EUR/CAD: 2026-07-31: 1.6145 USD/CAD: 2026-08-01: no data EUR/CAD: 2026-08-01: no data"
@test "flag --pair + --skip-no-data, repeated, range omits exactly the no-data lines" (echo (fxrate --skip-no-data --pair USDCAD --pair EURCAD 2026-07-30..2026-08-01)) = "USD/CAD: 2026-07-30: 1.4014 EUR/CAD: 2026-07-30: 1.6136 USD/CAD: 2026-07-31: 1.4029 EUR/CAD: 2026-07-31: 1.6145"

@test "flag --pair, unsupported currency pair is rejected" (fxrate --pair eurgbp)            = "Error: unsupported pair: eurgbp; CAD must be the base or quote currency, e.g. USDCAD or CADUSD"
@test "flag --pair, unsupported, with date"                (fxrate --pair eurgbp 2026-07-30) = "Error: unsupported pair: eurgbp; CAD must be the base or quote currency, e.g. USDCAD or CADUSD"
@test "flag --pair, unsupported, exits 1"                  (fxrate --pair eurgbp >/dev/null) $status -eq 1
@test "flag --pair, invalid, wrong length is rejected"     (fxrate --pair EURCA)             = "Error: invalid pair: EURCA; please use three-letter currency codes, e.g. USDCAD or USD/CAD"

@test "flag --pair, slash notation"                      (fxrate --pair USD/CAD) = "USD/CAD: 2026-07-30: 1.4014"
@test "flag --pair, slash notation, lowercase"           (fxrate --pair usd/cad) = "USD/CAD: 2026-07-30: 1.4014"
@test "flag --pair, slash notation, CAD base"            (fxrate --pair CAD/USD) = "CAD/USD: 2026-07-30: 0.7136"
@test "flag --pair, slash notation, CAD base, lowercase" (fxrate --pair cad/usd) = "CAD/USD: 2026-07-30: 0.7136"

@test "flag --pair, slash notation, trailing slash is invalid" (fxrate --pair USD/CAD/) = "Error: invalid pair: USD/CAD/; please use three-letter currency codes, e.g. USDCAD or USD/CAD"
@test "flag --pair, slash notation, leading slash is invalid"  (fxrate --pair /USD/CAD) = "Error: invalid pair: /USD/CAD; please use three-letter currency codes, e.g. USDCAD or USD/CAD"
@test "flag --pair, slash in wrong position is rejected"       (fxrate --pair US/DCAD)  = "Error: invalid pair: US/DCAD; please use three-letter currency codes, e.g. USDCAD or USD/CAD"

@test "before --available-pairs, cache variable does not exist"    (not set -q _fxrate_cache_available_pairs) $status -eq 0
@test "flag --available-pairs, lists default pair: USDCAD"         (echo (fxrate --available-pairs | grep -E "^USDCAD"))                     = "USDCAD - US dollar in Canadian dollars"
@test "flag --available-pairs, lists two pairs: CADUSD and USDCAD" (echo (fxrate --available-pairs | grep -E "^(CADUSD|USDCAD)"))            = "CADUSD - Canadian dollar in US dollars (reciprocal) USDCAD - US dollar in Canadian dollars"
@test "flag --available-pairs, ignores date argument"              (echo (fxrate --available-pairs 2026-07-30 | grep -E "^(CADUSD|USDCAD)")) = "CADUSD - Canadian dollar in US dollars (reciprocal) USDCAD - US dollar in Canadian dollars"
@test "after --available-pairs, cache variable exists"             (set -q _fxrate_cache_available_pairs) $status -eq 0

@test "flag --clean-cache, clears cache and exits 0"            (fxrate --clean-cache) $status -eq 0
@test "after --clean-cache, cache variable does not exist"      (not set -q _fxrate_cache_available_pairs) $status -eq 0

# README-driven tests: each documented `$ fxrate ...` example is executed
# and its output is checked against the output documented in README.md.
set README (dirname (status current-filename))/../README.md

@test "sanity: README.md exists" -e $README

# Extract every shell block from README.md
set -l content (string collect < $README)
set -l blocks (string match -ra '(?s)```shell\n(.*?)\n```' -- $content)

for block in $blocks
    set -l lines (string split \n -- $block)

    if not string match -qr '^\$ fxrate\b' -- $lines[1]
        continue
    end

    set -l cmd_args (string trim -- (string replace -r '^\$ fxrate' '' -- $lines[1]))
    set -l output_lines
    if test (count $lines) -gt 1
        set output_lines $lines[2..]
    end

    set -l desc "README: fxrate $cmd_args"
    if test -z "$cmd_args"
        set desc "README: fxrate (no args)"
    end

    if test (count $output_lines) -eq 0
        @echo "skipping (no documented output to check): $desc"
        return
    end

    for line in $output_lines
        if string match -q '*...*' -- $line
            @echo "skipping (truncated sample output): $desc"
            return
        end
    end

    if test (count $output_lines) -eq 1 -a "$output_lines[1]" = "Error: No response from Bank of Canada API"
        @echo "skipping (needs an unreachable-API mock, see tests/fxrate.fish): $desc"
        return
    end

    set -l tokens
    if test -n "$cmd_args"
        set tokens (string split ' ' -- $cmd_args)
        set tokens (string match -rv '^$' -- $tokens)
    end

    set -l actual_str (string join ' ' -- (fxrate $tokens))
    set -l expected_str (string join ' ' -- $output_lines)

    @test $desc $actual_str = $expected_str
end
