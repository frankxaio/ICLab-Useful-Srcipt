#!/usr/bin/env bash
set -euo pipefail

# ANSI colors; keep existing values if caller already exported them
: "${GREEN:=\033[0;32m}"
: "${BLUE:=\033[0;34m}"
: "${YELLOW:=\033[1;33m}"
: "${RED:=\033[0;31m}"
: "${NC:=\033[0m}"

TESTBED_FILE="${TESTBED_FILE:-}"

to_section() {
  case "$(printf '%s' "${1:-}" | tr '[:upper:]' '[:lower:]')" in
    rtl)  echo "RTL"  ;;
    gate) echo "GATE" ;;
    post) echo "POST" ;;
    *)    return 1    ;;
  esac
}

process_file() {
  local file="$1" section="$2" action="$3"
  local tmp
  tmp=$(mktemp)

  awk -v section="$section" -v action="$action" '
    BEGIN { in_sec = 0 }
    {
      if ($0 ~ "`ifdef[ \t]+" section)      { in_sec = 1 }
      else if ($0 ~ "`endif")               { in_sec = 0 }

      if (in_sec) {
        orig_line = $0
        indent    = gensub(/^([ \t]*).*$/, "\\1", 1, orig_line)

        body = orig_line
        sub(/^[ \t]*/, "", body)                     # strip indent

        body_no_c = body
        sub(/^\/\/[ \t]*/, "", body_no_c)            # strip leading // if present

        if (body_no_c ~ /^\$(fsdbDumpfile|fsdbDumpvars)\(.*\);/) {
          if (action == "on") {
            $0 = indent body_no_c                     # restore indent + body (no //)
          } else if (action == "off") {
            $0 = indent "// " body_no_c               # force single comment marker
          }
        }
      }
      print
    }
  ' "$file" >"$tmp"

  mv "$tmp" "$file"
}

show_state() {
  local file="$1"
  echo -e "${BLUE}File: $file${NC}"
  for sect in RTL GATE POST; do
    echo -e "${GREEN}In ${sect}${NC}"
    awk '/`ifdef '"$sect"'/,/`endif/ {if ($0 ~ /sdf_/)  print}' "$file" || true
    awk '/`ifdef '"$sect"'/,/`endif/ {if ($0 ~ /fsdb/)  print}' "$file" || true
  done
}

print_help() {
  echo -e "${RED}Usage:${NC}"
  echo -e "  fsdb.bash {on|off}             (Turn ALL sections on/off)"
  echo -e "  fsdb.bash {rtl|gate|post} {on|off} (Turn specific section on/off)"
  echo -e "${YELLOW}Example:${NC} TESTBED_FILE=TESTBED.v bash fsdb.bash on"
}

main() {
  # 0. Check arguments exists
  if [[ $# -eq 0 ]]; then
    if [[ -z "$TESTBED_FILE" || ! -f "$TESTBED_FILE" ]]; then
      echo -e "${RED}TESTBED_FILE not set or file not found${NC}"
      print_help
      return 1
    fi
    show_state "$TESTBED_FILE"
    print_help
    return 0
  fi

  # 1. Check File existence
  if [[ -z "$TESTBED_FILE" || ! -f "$TESTBED_FILE" ]]; then
    echo -e "${RED}${TESTBED_FILE:-TESTBED_FILE} not exist${NC}"
    return 1
  fi

  local first_arg="${1:-}"
  local second_arg="${2:-}"

  # --- New Feature: Global Toggle ---
  # If the first argument is directly 'on' or 'off', apply to all sections
  if [[ "$first_arg" == "on" || "$first_arg" == "off" ]]; then
      local action="$first_arg"
      # Process RTL, GATE, and POST sequentially
      for s in RTL GATE POST; do
          process_file "$TESTBED_FILE" "$s" "$action"
      done
      echo -e "${GREEN}All sections (RTL, GATE, POST) fsdbDumpvars set to ${action}.${NC}"
      show_state "$TESTBED_FILE"
      return 0
  fi
  # ----------------------------------

  # 2. Parse Section (Original single section logic)
  local section
  if ! section="$(to_section "$first_arg")"; then
    print_help
    return 1
  fi

  local onoff="$second_arg"

  case "$onoff" in
    on)
      process_file "$TESTBED_FILE" "$section" "on"
      echo -e "${GREEN}Uncomment ${section} fsdbDumpfile/fsdbDumpvars done.${NC}"
      ;;
    off)
      process_file "$TESTBED_FILE" "$section" "off"
      echo -e "${GREEN}Comment ${section} fsdbDumpfile/fsdbDumpvars done.${NC}"
      ;;
    *)
      print_help
      return 1
      ;;
  esac

  show_state "$TESTBED_FILE"
}
main "$@"