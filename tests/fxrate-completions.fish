# Simple fishtape tests for fxrate's tab-completion.

source (dirname (status current-filename))/helpers/curl.fish
source (dirname (status current-filename))/../functions/fxrate.fish
source (dirname (status current-filename))/../completions/fxrate.fish

@test "offers --pair"            (count (complete -C "fxrate --" | string match -r -- '--pair'))            -eq 1
@test "offers --skip-no-data"    (count (complete -C "fxrate --" | string match -r -- '--skip-no-data'))    -eq 1
@test "offers --available-pairs" (count (complete -C "fxrate --" | string match -r -- '--available-pairs')) -eq 1

@test "--pa narrows to --pair only"            (complete -C "fxrate --pa") = "--pair	Currency pair to query, e.g. USDCAD or EUR/CAD (repeatable)"
@test "--sk narrows to --skip-no-data only"    (complete -C "fxrate --sk") = "--skip-no-data	Omit dates with no published rate from output"
@test "--av narrows to --available-pairs only" (complete -C "fxrate --av") = "--available-pairs	List available pairs and exit"

@test "typing a year drills into all 12 months" (count (complete -C "fxrate 2024-")) -eq 12
@test "a partial year+month digit narrows to matching months" (count (complete -C "fxrate 2024-0")) -eq 9
@test "the year drilldown also works for years outside the recent list" (count (complete -C "fxrate 1999-")) -eq 12

@test "a month candidate carries its name as a description" (count (complete -C "fxrate 2024-" | string match -r -- '^2024-01-\tJanuary$')) -eq 1
@test "typing a year and month drills into that month's days" (count (complete -C "fxrate 2024-01-")) -eq 31
@test "a partial day digit narrows to matching days" (count (complete -C "fxrate 2024-01-1")) -eq 10
@test "leap February gets 29 day candidates" (count (complete -C "fxrate 2024-02-")) -eq 29
@test "non-leap February gets 28 day candidates" (count (complete -C "fxrate 2023-02-")) -eq 28
@test "an invalid month offers no days" (count (complete -C "fxrate 2024-13-")) -eq 0
@test "month 00 offers no days either" (count (complete -C "fxrate 2024-00-")) -eq 0

@test "empty token offers a year as far back as 2017" (count (complete -C "fxrate " | string match -r -- '^2017-')) -eq 1
@test "empty token never offers a year before 2017" (count (complete -C "fxrate " | string match -r -- '^2016-')) -eq 0
@test "garbage input offers no completions at all" (count (complete -C "fxrate abc")) -eq 0

@test "a range end-token keeps the start date and drills into months" (count (complete -C "fxrate 2024-01-01..2024-" | string match -r -- '^2024-01-01\.\.2024-01-\t')) -eq 1
@test "a single dot in a range end-token behaves the same as a double dot" (count (complete -C "fxrate 2024-01-01.2024-" | string match -r -- '^2024-01-01\.\.2024-01-\t')) -eq 1

@test "fxrate --pair empty value offers all pair candidates"    (count (complete -C "fxrate --pair "))     -eq 54
@test "fxrate --pair US narrows to USDCAD only"                 (count (complete -C "fxrate --pair US"))   -eq 1
@test "fxrate --pair EUR narrows to EURCAD only"                (count (complete -C "fxrate --pair EUR"))  -eq 1
@test "fxrate --pair CAD narrows to CADUSD only"                (count (complete -C "fxrate --pair CAD"))  -eq 27
@test "fxrate --pair=US form works"                             (count (complete -C "fxrate --pair=US"))   -eq 1
@test "fxrate --pair=US completes to full --pair=USDCAD token"  (complete -C "fxrate --pair=US") = "--pair=USDCAD	US dollar in Canadian dollars"
@test "fxrate --pair US completes to USDCAD with description"   (complete -C "fxrate --pair US") = "USDCAD	US dollar in Canadian dollars"
@test "pair candidates carry correct descriptions"              (count (complete -C "fxrate --pair " | string match -r -- '^CADUSD\tCanadian dollar in US dollars \(reciprocal\)$')) -eq 1
@test "typing a date after --pair offers no date completions"   (count (complete -C "fxrate --pair 2026")) -eq 0
