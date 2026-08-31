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
complete -c fxrate --long-option pair --require-parameter --no-files --description "Currency pair to query, e.g. USDCAD or EUR/CAD (repeatable)"
complete -c fxrate --long-option available-pairs --description "List available pairs and exit"

# Stage 1: unfinished year token -> months. Token "2026", "2026-", "2026-0",
# or the same as a range end-token. Candidates end in "-" so fish inserts no
# space and the next Tab continues to the month's days. Suppressed while typing
# --pair's currency value, where date candidates don't belong.
complete -c fxrate --no-files --keep-order --condition "_fxrate_complete_year_stage" -a '(_fxrate_complete_year_months)'

# Stage 2: finished month (with optional day prefix) -> that month's days.
# Token "2026-08", "2026-08-", "2026-08-1", or range end-token. A whole
# date gets the normal trailing space (finished argument).
complete -c fxrate --no-files --keep-order --condition "_fxrate_complete_month_stage" -a '(_fxrate_complete_month_days)'

# Default bucket: recent days then years. Fires for the empty token,
# partial years like "202", garbage, and fully-typed dates/ranges.
complete -c fxrate --no-files --keep-order --condition "not _fxrate_complete_year_stage; and not _fxrate_complete_month_stage" -a '(_fxrate_complete_default)'


# Splits a token into the range "start-date.." prefix (empty when the token is
# not a range end-token) and the remaining end-token portion, echoing the two
# parts on separate lines so a caller reads them as "$parts[1]" / "$parts[2]".
# Single or double dot both normalize to "..". Parsing the token once here
# avoids re-running the same regex on every consumer.
function _fxrate_complete_range_split --argument-names tok
    if set -l m (string match -r '^(\d{4}-\d{2}-\d{2})(\.\.?)(.*)$' -- $tok)
        echo "$m[2].."
        echo $m[4]
    else
        echo ""
        echo $tok
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

function _fxrate_complete_year_months
    set -l parts (_fxrate_complete_range_split (commandline -ct))
    set -l prefix $parts[1]
    set -l rest $parts[2]
    _fxrate_complete_emit $prefix $rest (_fxrate_complete_months (string sub -l 4 $rest))
end

function _fxrate_complete_months --argument-names year
    for month in 01 02 03 04 05 06 07 08 09 10 11 12
        echo -e "$year-$month-\t"(_fxrate_complete_month_name $month)
    end
end

function _fxrate_complete_month_name --argument-names month
    switch $month
        case 01; echo January
        case 02; echo February
        case 03; echo March
        case 04; echo April
        case 05; echo May
        case 06; echo June
        case 07; echo July
        case 08; echo August
        case 09; echo September
        case 10; echo October
        case 11; echo November
        case 12; echo December
    end
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
    for y in (seq (date +%Y) -1 2017)
        echo -e "$y-"
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
