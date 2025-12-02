#!/usr/bin/env bash
set -euo pipefail

log_paths=("$@")
default_logs=0
if ((${#log_paths[@]} == 0)); then
    log_paths=(vcs.log syn.log)
    default_logs=1
fi

if [[ -t 1 ]]; then
    header_color=$'\033[1;34m'
    count_color=$'\033[1;36m'
    warn_color=$'\033[33m'
    ok_color=$'\033[32m'
    reset=$'\033[0m'
else
    header_color=''
    count_color=''
    warn_color=''
    ok_color=''
    reset=''
fi

if [[ -t 2 ]]; then
    err_color=$'\033[31m'
    err_reset=$reset
else
    err_color=''
    err_reset=''
fi

missing=0
processed=0
for log_path in "${log_paths[@]}"; do
    if [[ ! -f "$log_path" ]]; then
        if ((default_logs)); then
            continue
        fi
        printf '%sError:%s cannot find %s in %s\n' "$err_color" "$err_reset" "$log_path" "$(pwd)" >&2
        missing=1
        continue
    fi

    printf '%s==> %s%s\n' "$header_color" "$log_path" "$reset"
    awk -v log_path="$log_path" \
        -v count_color="$count_color" \
        -v warn_color="$warn_color" \
        -v ok_color="$ok_color" \
        -v reset="$reset" '
      BEGIN {
        no_warning_msg = ok_color "No warnings found in " log_path "." reset
      }
      /^[[:space:]]*%?[Ww]arning[-:]/ {
        line=$0
        sub(/^[[:space:]]*/,"",line)
        counts[line]++
      }
      END {
        if (!length(counts)) {
          printf "%s\n", no_warning_msg
          exit 0
        }
        PROCINFO["sorted_in"] = "@val_num_desc"
        for (line in counts)
          printf "%s%7d%s %s%s%s\n", count_color, counts[line], reset, warn_color, line, reset
      }
    ' "$log_path"
    printf '\n'
    processed=$((processed + 1))
done

if ((default_logs)) && ((processed == 0)); then
    printf '%sError:%s cannot find syn.log or vcs.log in %s\n' "$err_color" "$err_reset" "$(pwd)" >&2
    exit 1
fi

exit $missing
