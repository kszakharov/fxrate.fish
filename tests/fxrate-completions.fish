#!/usr/bin/env fish
# Simple fishtape tests for fxrate's tab-completion.

source (dirname (status current-filename))/../completions/fxrate.fish


@test "offers --pair" (count (complete -C "fxrate --" | string match -r -- '--pair')) -gt 0
@test "offers --skip-no-data" (count (complete -C "fxrate --" | string match -r -- '--skip-no-data')) -gt 0
@test "offers --available-pairs" (count (complete -C "fxrate --" | string match -r -- '--available-pairs')) -gt 0

@test "typing a year drills into all 12 months" (count (complete -C "fxrate 2024-")) -eq 12

@test "a month candidate carries its name as a description" (count (complete -C "fxrate 2024-" | string match -r -- '^2024-01-\tJanuary$')) -eq 1
@test "typing a year and month drills into that month's days" (count (complete -C "fxrate 2024-01-")) -eq 31
@test "leap February gets 29 day candidates" (count (complete -C "fxrate 2024-02-")) -eq 29
@test "non-leap February gets 28 day candidates" (count (complete -C "fxrate 2023-02-")) -eq 28
@test "an invalid month offers no days" (count (complete -C "fxrate 2024-13-")) -eq 0

@test "empty token offers a year as far back as 2017" (count (complete -C "fxrate " | string match -r -- '^2017-')) -eq 1
@test "empty token never offers a year before 2017" (count (complete -C "fxrate " | string match -r -- '^2016-')) -eq 0

@test "a range end-token keeps the start date and drills into months" (count (complete -C "fxrate 2024-01-01..2024-" | string match -r -- '^2024-01-01\.\.2024-01-\t')) -eq 1
