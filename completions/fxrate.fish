# Tab-completion for the fxrate function.
#
# Mechanics note: fish has no per-registration "no-space" flag. Instead it
# suppresses the trailing space after any inserted completion whose text ends
# in one of "/=@:.,-". The staged picker relies on that native rule:
#   - year/month selections keep a trailing "-" (e.g. "2026-01-") so no space
#     is inserted and the next Tab continues drilling down in the same token;
#   - finished full dates, ranges, and --flags end in a digit or letter, so
#     they get the normal trailing space (completed argument).
# Each stage is its own `complete` call with a mutually-exclusive -n gate;
# -k preserves emission order (dates newest-first, years newest-first, months
# and days in calendar order) instead of fish alphabetizing the candidates.

# Base registration: suppress file completion for all fxrate arguments.
complete -c fxrate --no-files --erase

# Options are their own registrations. Fish only surfaces an option when the
# current token starts with "-", which is exactly the "flag as its own token,
# never mid-date" behavior, so no -n gating is needed here.
complete -c fxrate --long-option skip-no-data --description "Omit dates with no published rate from output"
complete -c fxrate --long-option pair --require-parameter --no-files --keep-order --description "Currency pair to query, e.g. USDCAD or EUR/CAD (repeatable)" -a '(_fxrate_complete_pairs)'
complete -c fxrate --long-option available-pairs --description "List available pairs and exit"

# Stage 1: unfinished year token -> months. Token "2026", "2026-", "2026-0",
# or the same as a range end-token. Candidates end in "-" so fish inserts no
# space and the next Tab continues to the month's days. Suppressed while typing
# --pair's currency value, where date candidates don't belong.
complete -c fxrate --no-files --keep-order --condition "not _fxrate_complete_pair_value; and _fxrate_complete_year_stage" -a '(_fxrate_complete_year_months)'

# Stage 2: finished month (with optional day prefix) -> that month's days.
# Token "2026-08", "2026-08-", "2026-08-1", or range end-token. A whole
# date gets the normal trailing space (finished argument).
complete -c fxrate --no-files --keep-order --condition "not _fxrate_complete_pair_value; and _fxrate_complete_month_stage" -a '(_fxrate_complete_month_days)'

# Default bucket: recent days then years. Fires for the empty token,
# partial years like "202", garbage, and fully-typed dates/ranges.
complete -c fxrate --no-files --keep-order --condition "not _fxrate_complete_pair_value; and not _fxrate_complete_year_stage; and not _fxrate_complete_month_stage" -a '(_fxrate_complete_default)'


# Splits a token into the range "start-date.." prefix (empty when the token is
# not a range end-token) and the remaining end-token portion, echoing the two
# parts on separate lines so a caller reads them as "$parts[1]" / "$parts[2]".
# Single or double dot both normalize to "..". Parsing the token once here
# avoids re-running the same regex on every consumer.
function _fxrate_complete_range_split --argument-names token
    if set -l range_match (string match -r '^(\d{4}-\d{2}-\d{2})(\.\.?)(.*)$' -- $token)
        echo "$range_match[2].."
        echo $range_match[4]
    else
        echo ""
        echo $token
    end
end

function _fxrate_complete_year_stage
    set -l parts (_fxrate_complete_range_split (commandline -ct))
    string match -qr '^\d{4}(-\d?)?$' -- $parts[2]
end

function _fxrate_complete_month_stage
    set -l parts (_fxrate_complete_range_split (commandline -ct))
    string match -qr '^\d{4}-\d{2}(-\d?)?$' -- $parts[2]
end

# True when the cursor sits in the value position of a --pair argument:
# a previous --pair token immediately before the current token, or the current
# token being a --pair=... form. Date-completion stages are mutually exclusive
# with this gate so typing a year after --pair never offers date candidates.
function _fxrate_complete_pair_value
    if string match -qr '^--pair=' -- (commandline -ct)
        return 0
    end

    set -l tokens (commandline -opc)
    if test (count $tokens) -ge 2
        and string match -q -- --pair $tokens[-1]
        return 0
    end

    return 1
end

# Emits `PAIR<Tab>Description` candidates for --pair's value, drawn from
# `fxrate --available-pairs` (`PAIR - Description` lines). Only pairs whose
# code starts with the typed prefix are offered, case-insensitively. fish only
# invokes this while completing --pair's parameter, so the gate check here is
# a belt-and-suspenders guard.
function _fxrate_complete_pairs
    _fxrate_complete_pair_value
    or return 1

    set -l prefix (commandline -ct)
    if string match -qr '^--pair=' -- $prefix
        set prefix (string replace -r '^--pair=' '' -- $prefix)
    end

    for line in (fxrate --available-pairs)
        set -l parts (string split -m1 ' - ' -- $line)
        if test (count $parts) -lt 2
            continue
        end
        if string match -qi "$prefix*" -- $parts[1]
            echo -e "$parts[1]\t$parts[2]"
        end
    end
end

function _fxrate_complete_year_months
    set -l parts (_fxrate_complete_range_split (commandline -ct))
    set -l prefix $parts[1]
    set -l rest $parts[2]
    _fxrate_complete_emit $prefix $rest (_fxrate_complete_months (string sub -l 4 $rest))
end

function _fxrate_complete_months --argument-names year
    echo -e "$year-01-\tJanuary"
    echo -e "$year-02-\tFebruary"
    echo -e "$year-03-\tMarch"
    echo -e "$year-04-\tApril"
    echo -e "$year-05-\tMay"
    echo -e "$year-06-\tJune"
    echo -e "$year-07-\tJuly"
    echo -e "$year-08-\tAugust"
    echo -e "$year-09-\tSeptember"
    echo -e "$year-10-\tOctober"
    echo -e "$year-11-\tNovember"
    echo -e "$year-12-\tDecember"
end

function _fxrate_complete_month_days
    set -l parts (_fxrate_complete_range_split (commandline -ct))
    set -l prefix $parts[1]
    set -l rest $parts[2]
    set -l year (string sub -l 4 $rest)
    set -l month (string sub -s 6 -l 2 $rest)

    # Only a real month (01-12) reaches the day list; invalid months like
    # "2026-13" would otherwise let GNU date spew an error on stderr and
    # yield a bogus candidate via an empty last-day count.
    if not string match -qr '^(0[1-9]|1[0-2])$' -- $month
        return
    end

    _fxrate_complete_emit $prefix $rest (_fxrate_complete_days $year $month)
end

function _fxrate_complete_days --argument-names year month
    set -l flavor (_fxrate_complete_date_flavor)
    for d in (seq 1 (_fxrate_complete_last_day $flavor $year $month))
        set -l dd (string pad -w 2 -c 0 $d)
        echo -e "$year-$month-$dd"
    end
end

# Compute the last day of a month. Handling leap years without hardcoding month lengths.
function _fxrate_complete_last_day --argument-names flavor year month
    if test "$flavor" = bsd
        date -j -v+1m -v-1d -f "%Y-%m-%d" "$year-$month-01" +%d
    else
        date -d "$year-$month-01 +1 month -1 day" +%d
    end
end

function _fxrate_complete_weekday --argument-names flavor date
    if test "$flavor" = bsd
        date -j -f "%Y-%m-%d" $date +%A
    else
        date -d $date +%A
    end
end

# Shared emitter for every stage: take candidate lines from the producer(s),
# keep those matching the typed prefix, and prefix the range start-date onto
# any survivors (empty prefix when the token is not a range end-token).
function _fxrate_complete_emit --argument-names prefix rest
    for line in $argv[3..-1]
        set -l c (string split -m1 \t -- $line)
        if string match -q -- "$rest*" $c[1]
            echo -e "$prefix$c[1]\t$c[2]"
        end
    end
end

function _fxrate_complete_default
    set -l parts (_fxrate_complete_range_split (commandline -ct))
    set -l prefix $parts[1]
    set -l rest $parts[2]
    _fxrate_complete_emit $prefix $rest (_fxrate_complete_recent_dates 7; _fxrate_complete_years)
end

# Generate the most recent num_days dates, ending today.
# Days 0 and 1 are labeled "Today" and "Yesterday"; older days use
# their weekday name. Dates are returned most-recent first.
function _fxrate_complete_recent_dates --argument-names num_days
    set -l flavor (_fxrate_complete_date_flavor)
    set -l cur (date +%Y-%m-%d)

    for i in (seq 0 (math $num_days - 1))
        switch $i
            case 0
                echo -e "$cur\tToday"
            case 1
                echo -e "$cur\tYesterday"
            case '*'
                echo -e "$cur\t"(_fxrate_complete_weekday $flavor $cur)
        end

        if test "$flavor" = bsd
            set cur (date -j -v-1d -f "%Y-%m-%d" $cur +%Y-%m-%d)
        else
            set cur (date -d "$cur -1 day" +%Y-%m-%d)
        end
    end
end

# Years from the current year down through 2017, newest first. The Bank of
# Canada Valet API provides daily exchange-rate data from 2017 onward;
# 2017 is the earliest available year. Year candidates keep a trailing "-"
# so selecting one continues into the year -> month stage without a space.
function _fxrate_complete_years
    for year in (seq (date +%Y) -1 2017)
        echo -e "$year-"
    end
end

# Detects whether the system date command uses BSD or GNU syntax.
# The same probe is used inline by _fxrate_iter_dates in functions/fxrate.fish.
# Used by date-related fxrate completion and date iteration helpers.
function _fxrate_complete_date_flavor
    if date -v1d >/dev/null 2>&1
        echo bsd
    else
        echo gnu
    end
end
