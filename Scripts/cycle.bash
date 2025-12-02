#!/usr/bin/bash


# check parameter
if [[ $# -eq 0 ]]; then
  # testbed file
  echo ${BLUE}File: "$TESTBED_FILE"${NC}
  GREP_COLOR='01;32' cat --number "$TESTBED_FILE" | grep --color 'define\s\+CYCLE_TIME\s\+[0-9]\+\.\?[0-9]\?'
  # pattern file
  echo ${BLUE}File: "$PATTERN_FILE"${NC}
  GREP_COLOR='01;32' cat --number "$PATTERN_FILE" | grep --color 'define\s\+CYCLE_TIME\s\+[0-9]\+\.\?[0-9]\?'
  # syn file
  echo ${BLUE}File: "$SYN_FILE"${NC}
  GREP_COLOR='01;32' cat --number "$SYN_FILE" | grep --color 'set CYCLE [0-9]\+\.\?[0-9]\?'
  exit 1
else
  # testbed file
  echo ${BLUE}File: "$TESTBED_FILE"${NC}
  GREP_COLOR='01;31' cat --number "$TESTBED_FILE" | grep --color 'define\s\+CYCLE_TIME\s\+[0-9]\+\.\?[0-9]\?'
  sed -i "s/define\s\+CYCLE_TIME\s\+[0-9]\+\.\?[0-9]\?/define CYCLE_TIME $1/" "$TESTBED_FILE"
  GREP_COLOR='01;32' cat --number "$TESTBED_FILE" | grep --color 'define\s\+CYCLE_TIME\s\+[0-9]\+\.\?[0-9]\?'

  # pattern file
  echo ${BLUE}File: "$PATTERN_FILE"${NC}
  GREP_COLOR='01;31' cat --number "$PATTERN_FILE" | grep --color 'define\s\+CYCLE_TIME\s\+[0-9]\+\.\?[0-9]\?'
  sed -i "s/define\s\+CYCLE_TIME\s\+[0-9]\+\.\?[0-9]\?/define CYCLE_TIME $1/" "$PATTERN_FILE"
  GREP_COLOR='01;32' cat --number "$PATTERN_FILE" | grep --color 'define\s\+CYCLE_TIME\s\+[0-9]\+\.\?[0-9]\?'

  # syn file
  echo ${BLUE}File: "$SYN_FILE"${NC}
  GREP_COLOR='01;31' cat --number "$SYN_FILE" | grep --color 'set CYCLE [0-9]\+\.\?[0-9]\?'
  sed -i "s/set CYCLE [0-9]\+\.\?[0-9]\?/set CYCLE $1/" "$SYN_FILE"
  GREP_COLOR='01;32' cat --number "$SYN_FILE" | grep --color 'set CYCLE [0-9]\+\.\?[0-9]\?'

  # Report
  if [[ $? -eq 0 ]]; then
    echo "${GREEN}Change cycle time to $1 done. ${NC}"
  fi
fi
