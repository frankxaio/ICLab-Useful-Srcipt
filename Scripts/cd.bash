#!/bin/bash

# Define colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color / Reset

# Handle the input argument
case "$1" in
  [0-9])
    # Case for single digit (0-9): Add leading zero pattern (e.g., 1 -> 01_*)
    target_pattern="0$1_*"
    ;;
  [1-9][0-9])
    # Case for double digits (10-99): Use pattern directly (e.g., 10 -> 10_*)
    target_pattern="$1_*"
    ;;
  m)
    # Special case for Memory directory
    target_dir="$ROOT_PATH/Memory"
    if [ -d "$target_dir" ]; then
        builtin cd "$target_dir" || { echo -e "${RED}Change directory failed${NC}"; return 1; }
        echo -e "${GREEN}Current directory: $(pwd)${NC}"
        return 0
    else
        echo -e "${RED}Directory 'Memory' not found in $ROOT_PATH${NC}"
        return 1
    fi
    ;;
  *)
    # Invalid input
    return 1
    ;;
esac

# Use 'find' to locate the directory safely
# This avoids issues where shell wildcard expansion fails on the first try due to caching/latency
# -maxdepth 1: Search only in the root path
# -type d: Look for directories only
# -name: Match the pattern
# -print -quit: Stop after finding the first match
found_dir=$(find "$ROOT_PATH" -maxdepth 1 -type d -name "$target_pattern" -print -quit)

if [ -n "$found_dir" ]; then
    # Directory found, switch to it
    builtin cd "$found_dir" || { echo -e "${RED}Change directory failed${NC}"; return 1; }
    echo -e "${GREEN}Current directory: $(pwd)${NC}"
else
    # Directory not found
    echo -e "${RED}Directory matching '$target_pattern' not found in $ROOT_PATH${NC}"
    return 1
fi