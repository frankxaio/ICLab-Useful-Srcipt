#!/usr/bin/tcsh -f

set log_paths = ($argv)
set default_logs = 0

if ( $#log_paths == 0 ) then
    set log_paths = (vcs.log syn.log)
    set default_logs = 1
endif

if ( -t 1 ) then
    set header_color = '\033[1;34m'
    set count_color = '\033[1;36m'
    set warn_color = '\033[33m'
    set ok_color = '\033[32m'
    set reset = '\033[0m'
else
    set header_color = ''
    set count_color = ''
    set warn_color = ''
    set ok_color = ''
    set reset = ''
endif

if ( -t 2 ) then
    set err_color = '\033[31m'
    set err_reset = "$reset"
else
    set err_color = ''
    set err_reset = ''
endif

set missing = 0
set processed = 0

foreach log_path ( $log_paths )
    if ( ! -f "$log_path" ) then
        if ( $default_logs == 1 ) continue
        echo "${err_color}Error:${err_reset} cannot find $log_path in `pwd`" >&2
        set missing = 1
        continue
    endif

    printf "${header_color}==> ${log_path}${reset}\n"
    awk -v log_path="$log_path" \
        -v count_color="$count_color" \
        -v warn_color="$warn_color" \
        -v ok_color="$ok_color" \
        -v reset="$reset" ' \
      BEGIN { \
        no_warning_msg = ok_color "No warnings found in " log_path "." reset \
      } \
      /^[[:space:]]*%?[Ww]arning[-:]/ { \
        line=$0; \
        sub(/^[[:space:]]*/,"",line); \
        counts[line]++; \
      } \
      END { \
        if (length(counts) == 0) { \
          printf "%s\n", no_warning_msg; \
          exit 0; \
        } \
        PROCINFO["sorted_in"] = "@val_num_desc"; \
        for (line in counts) \
          printf "%s%7d%s %s%s%s\n", count_color, counts[line], reset, warn_color, line, reset; \
      } \
    ' "$log_path"
    printf '\n'
    @ processed++
end

if ( $default_logs == 1 && $processed == 0 ) then
    echo "${err_color}Error:${err_reset} cannot find syn.log or vcs.log in `pwd`" >&2
    exit 1
endif

exit $missing