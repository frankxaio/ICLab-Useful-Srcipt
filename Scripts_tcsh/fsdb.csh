#!/usr/bin/tcsh -f

# ANSI colors
if ( ! $?GREEN ) setenv GREEN '\033[0;32m'
if ( ! $?BLUE ) setenv BLUE '\033[0;34m'
if ( ! $?YELLOW ) setenv YELLOW '\033[1;33m'
if ( ! $?RED ) setenv RED '\033[0;31m'
if ( ! $?NC ) setenv NC '\033[0m'

if ( ! $?TESTBED_FILE ) setenv TESTBED_FILE ""

set SHOW_PATTERN = '(`ifdef (RTL|GATE|POST)|`endif|fsdb|sdf)'

if ( $#argv == 0 ) then
    if ( "$TESTBED_FILE" == "" || ! -f "$TESTBED_FILE" ) then
        echo "${RED}TESTBED_FILE not set or file not found${NC}"
        echo "${RED}Usage:${NC}"
        echo "  fsdb.csh {on|off}             (Turn ALL sections on/off)"
        echo "  fsdb.csh {rtl|gate|post} {on|off} (Turn specific section on/off)"
        exit 1
    endif

    echo "${BLUE}File: $TESTBED_FILE${NC}"
    grep -E "$SHOW_PATTERN" "$TESTBED_FILE"
    exit 0
endif

if ( "$TESTBED_FILE" == "" || ! -f "$TESTBED_FILE" ) then
    echo "${RED}TESTBED_FILE not exist${NC}"
    exit 1
endif

set first_arg = "$1"
set second_arg = ""
if ( $#argv > 1 ) set second_arg = "$2"

if ( "$first_arg" == "on" || "$first_arg" == "off" ) then
    set action = "$first_arg"
    foreach s ( RTL GATE POST )
        set tmp = `mktemp`
        awk -v section="$s" -v action="$action" '\
        BEGIN { in_sec = 0 } \
        { \
          if ($0 ~ "`ifdef[ \t]+" section)      { in_sec = 1 } \
          else if ($0 ~ "`endif")               { in_sec = 0 } \
          if (in_sec) { \
            orig_line = $0; \
            indent    = gensub(/^([ \t]*).*$/, "\\1", 1, orig_line); \
            body = orig_line; \
            sub(/^[ \t]*/, "", body); \
            body_no_c = body; \
            sub(/^\/\/[ \t]*/, "", body_no_c); \
            if (body_no_c ~ /^[\$](fsdbDumpfile|fsdbDumpvars)\(.*\);/) { \
              if (action == "on") { \
                $0 = indent body_no_c; \
              } else if (action == "off") { \
                $0 = indent "// " body_no_c; \
              } \
            } \
          } \
          print \
        }' "$TESTBED_FILE" > "$tmp"
        mv "$tmp" "$TESTBED_FILE"
    end
    echo "${GREEN}All sections (RTL, GATE, POST) fsdbDumpvars set to ${action}.${NC}"

    echo "${BLUE}File: $TESTBED_FILE${NC}"
    grep -E "$SHOW_PATTERN" "$TESTBED_FILE"
    exit 0
endif

set section = ""
switch ( `echo "$first_arg" | tr '[:upper:]' '[:lower:]'` )
    case rtl:
        set section = "RTL"
        breaksw
    case gate:
        set section = "GATE"
        breaksw
    case post:
        set section = "POST"
        breaksw
    default:
        echo "${RED}Usage:${NC} fsdb.csh {rtl|gate|post} {on|off}"
        exit 1
endsw

set action = "$second_arg"
if ( "$action" != "on" && "$action" != "off" ) then
    echo "${RED}Usage:${NC} fsdb.csh $section {on|off}"
    exit 1
endif

set tmp = `mktemp`
awk -v section="$section" -v action="$action" '\
BEGIN { in_sec = 0 } \
{ \
  if ($0 ~ "`ifdef[ \t]+" section)      { in_sec = 1 } \
  else if ($0 ~ "`endif")               { in_sec = 0 } \
  if (in_sec) { \
    orig_line = $0; \
    indent    = gensub(/^([ \t]*).*$/, "\\1", 1, orig_line); \
    body = orig_line; \
    sub(/^[ \t]*/, "", body); \
    body_no_c = body; \
    sub(/^\/\/[ \t]*/, "", body_no_c); \
    if (body_no_c ~ /^[\$](fsdbDumpfile|fsdbDumpvars)\(.*\);/) { \
      if (action == "on") { \
        $0 = indent body_no_c; \
      } else if (action == "off") { \
        $0 = indent "// " body_no_c; \
      } \
    } \
  } \
  print \
}' "$TESTBED_FILE" > "$tmp"
mv "$tmp" "$TESTBED_FILE"

if ( "$action" == "on" ) then
    echo "${GREEN}Uncomment ${section} fsdbDumpfile/fsdbDumpvars done.${NC}"
else
    echo "${GREEN}Comment ${section} fsdbDumpfile/fsdbDumpvars done.${NC}"
endif

echo "${BLUE}File: $TESTBED_FILE${NC}"
grep -E "$SHOW_PATTERN" "$TESTBED_FILE"

exit 0