#!/bin/bash

# =====================================================
# Project Bootstrap Script
# =====================================================

# -------------------- Colors -------------------------
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# -------------------- Paths --------------------------
ROOT_PATH="$(pwd)"
SCRIPT_PATH="$HOME/asic-script/Scripts"
SYN_FILE="$ROOT_PATH/02_SYN/syn.tcl"
DESIGN_MAKE=$(grep -E '^top_design=' "$ROOT_PATH/00_TESTBED/makefile" | cut -d'=' -f2 | tr -d ' ')
DESIGN_SYN=$(grep -E '^set DESIGN ' "$SYN_FILE" | awk '{print $3}' | tr -d '"')
SDC_FILE="$ROOT_PATH/02_SYN/$DESIGN_SYN.sdc"
TESTBED_FILE="$ROOT_PATH/00_TESTBED/TESTBED.v"
PATTERN_FILE="$ROOT_PATH/00_TESTBED/PATTERN.v"

export ROOT_PATH

# -------------------- Info Panel ---------------------
    echo -e "${GREEN}+---------------+----------------------------------------------------------------+${NC}"
    echo -e "${GREEN}| COMMAND       | DESCRIPTION                                                    |${NC}"
    echo -e "${GREEN}+---------------+----------------------------------------------------------------+${NC}"
    echo -e "${BLUE}| ROOT_PATH      | ${NC}$ROOT_PATH"
    echo -e "${BLUE}| DESIGN         | ${NC}makefile: ${YELLOW}$DESIGN_MAKE${NC}, Syn File: ${YELLOW}$DESIGN_SYN${NC}"
    echo -e "${BLUE}| cd.bash        | ${NC}0~9, m to switch folders; 2r -> syn report; 2n -> syn netlist"
    echo -e "${BLUE}| rtl            | ${NC}run RTL simulation"
    echo -e "${BLUE}| syn            | ${NC}run synthesis"
    echo -e "${BLUE}| c              | ${NC}change synthesis cycle time, e.g. cycle_syn 10.0"
    echo -e "${BLUE}| f              | ${NC}toggle fsdbDumpfile/fsdbDumpvars in TESTBED.v"
    echo -e "${BLUE}| gate           | ${NC}run gate simulation"
    echo -e "${BLUE}| post           | ${NC}run post simulation"
    echo -e "${BLUE}| check_syn      | ${NC}summarize synthesis results"
    echo -e "${BLUE}| rpt            | ${NC}cat all files in \$ROOT_PATH/02_SYN/Report/*.ext"
    echo -e "${BLUE}| clean          | ${NC}clean current directory"
    echo -e "${BLUE}| clean0123      | ${NC}clean 00_TESTBED, 01_RTL, 02_SYN, 03_GATE"
    echo -e "${BLUE}| link_mk        | ${NC}link makefile to current directory"
    echo -e "${GREEN}+---------------+----------------------------------------------------------------+${NC}"

# -------------------- Script Source ------------------
source $SCRIPT_PATH/cd.bash

# =====================================================
# Aliases
# =====================================================

# -- Directory Switching (0~9)
for i in {0..9}; do
    alias $i="source $SCRIPT_PATH/cd.bash $i"
done

alias m="source $SCRIPT_PATH/cd.bash m"

# -- Synthesis Directories
alias 2r="cd $ROOT_PATH/02_SYN/Report/"
alias 2n="cd $ROOT_PATH/02_SYN/Netlist/"

# -- Python Tools
alias python="~/miniconda3/bin/python3" # replace python2 with python3 in conda

# -- Document
alias doc_dw="/usr/Synopsys/syn/T-2022.03-SP2/dw/doc/manuals/"
alias doc_verdi="/usr/Synopsys/verdi/T-2022.06/doc/"

# =====================================================
# Functions
# =====================================================

check_syn() {
    source "$SCRIPT_PATH/cd.bash" 2
    bash "$SCRIPT_PATH/check_syn.bash" "$DESIGN_MAKE"
}

rtl() {
    source "$SCRIPT_PATH/cd.bash" 1
    # make vcs_rtl 2>&1 | grc -c ~/.grc/vcs.conf cat
    make vcs_rtl 2>&1
}

syn() {
    source "$SCRIPT_PATH/cd.bash" 2
    # make syn 2>&1 | grc -c ~/.grc/dcshell.conf cat
    make syn 2>&1
}

gate() {
    source "$SCRIPT_PATH/cd.bash" 3
    # make vcs_gate 2>&1 | grc -c ~/.grc/vcs.conf cat
    make vcs_gate 2>&1
}

post() {
    source "$SCRIPT_PATH/cd.bash" 6
    # make vcs_post 2>&1 | grc -c ~/.grc/vcs.conf cat
    make vcs_post 2>&1
}

clean () {
    echo -e "${BLUE}?完 Cleaning current directory...${NC}"
    make -f "$ROOT_PATH/00_TESTBED/makefile" clean > /dev/null 2>&1
}

clean0123() {
    echo -e "${BLUE}?完 Cleaning 00_TESTBED...${NC}"
    source "$SCRIPT_PATH/cd.bash" 0
    make -f "$ROOT_PATH/00_TESTBED/makefile" clean >/dev/null 2>&1
    echo -e "${GREEN}??00_TESTBED cleaned${NC}"

    echo -e "${BLUE}?完 Cleaning 01_RTL...${NC}"
    source "$SCRIPT_PATH/cd.bash" 1
    make -f "$ROOT_PATH/01_RTL/makefile" clean >/dev/null 2>&1
    echo -e "${GREEN}??01_RTL cleaned${NC}"

    echo -e "${BLUE}?完 Cleaning 02_SYN...${NC}"
    source "$SCRIPT_PATH/cd.bash" 2
    make -f "$ROOT_PATH/02_SYN/makefile" clean >/dev/null 2>&1
    echo -e "${GREEN}??02_SYN cleaned${NC}"

    echo -e "${BLUE}?完 Cleaning 03_GATE...${NC}"
    source "$SCRIPT_PATH/cd.bash" 3
    make -f "$ROOT_PATH/03_GATE/makefile" clean >/dev/null 2>&1
    echo -e "${GREEN}??03_GATE cleaned${NC}"

    echo -e "${GREEN}?? All directories cleaned successfully!${NC}"
}

link_mk() {
    local current_dir="${PWD##*/}"

    if [[ "$current_dir" == 0?* ]]; then
        echo "?? Linking Makefile from 00_TESTBED..."

        if [[ -f "$ROOT_PATH/00_TESTBED/makefile" ]]; then
            ln -sf "$ROOT_PATH/00_TESTBED/makefile" .
            echo "??Linked makefile"
        else
            echo "??No Makefile or makefile found in 00_TESTBED/"
            return 1
        fi
    else
        echo "??This function only works in 0x_ folders like 01_RTL, 02_SYN."
        return 1
    fi
}

rpt() {
    local dir="$ROOT_PATH/02_SYN/Report"

    if [[ ! -d $dir ]]; then
        echo "??Report directory not found: $dir"
        return 1
    fi

    if [[ -z $1 ]]; then
        echo "Available extensions under $dir:"
        local exts=(${(u)${(f)"$(printf '%s\n' "$dir"/*.* | sed -E 's@.*\.@@')"}})
        for e in $exts; do echo "  .$e"; done
        return
    fi

    local ext=$1
    local files=("$dir"/*."$ext")

    if (( ${#files[@]} == 0 )); then
        echo "??No *.$ext files found in $dir"
        return 1
    fi

    if (( $+commands[rcat] )); then
        rcat "${files[@]}"
    else
        cat "${files[@]}"
    fi
}

c() {
    TESTBED_FILE="$TESTBED_FILE" \
    PATTERN_FILE="$PATTERN_FILE" \
    SYN_FILE="$SYN_FILE" \
    bash "$SCRIPT_PATH/cycle.bash" "$@"
}

f() {
    TESTBED_FILE="$TESTBED_FILE" \
    bash "$SCRIPT_PATH/fsdb.bash" "$@"
}

check_warn() {
    bash "$SCRIPT_PATH/check_warn.bash"
}

quota() {
    bash "$SCRIPT_PATH/quota.bash"
}

prj_help() {
    echo -e "${GREEN}+---------------+----------------------------------------------------------------+${NC}"
    echo -e "${GREEN}| COMMAND       | DESCRIPTION                                                    |${NC}"
    echo -e "${GREEN}+---------------+----------------------------------------------------------------+${NC}"
    echo -e "${BLUE}| ROOT_PATH      | ${NC}$ROOT_PATH"
    echo -e "${BLUE}| DESIGN         | ${NC}makefile: ${YELLOW}$DESIGN_MAKE${NC}, Syn File: ${YELLOW}$DESIGN_SYN${NC}"
    echo -e "${BLUE}| cd.bash        | ${NC}0~9, m to switch folders; 2r -> syn report; 2n -> syn netlist"
    echo -e "${BLUE}| rtl            | ${NC}run RTL simulation"
    echo -e "${BLUE}| syn            | ${NC}run synthesis"
    echo -e "${BLUE}| c              | ${NC}change synthesis cycle time, e.g. cycle_syn 10.0"
    echo -e "${BLUE}| f              | ${NC}toggle fsdbDumpfile/fsdbDumpvars in TESTBED.v"
    echo -e "${BLUE}| gate           | ${NC}run gate simulation"
    echo -e "${BLUE}| post           | ${NC}run post simulation"
    echo -e "${BLUE}| check_syn      | ${NC}summarize synthesis results"
    echo -e "${BLUE}| rpt            | ${NC}cat all files in \$ROOT_PATH/02_SYN/Report/*.ext"
    echo -e "${BLUE}| clean          | ${NC}clean current directory"
    echo -e "${BLUE}| clean0123      | ${NC}clean 00_TESTBED, 01_RTL, 02_SYN, 03_GATE"
    echo -e "${BLUE}| link_mk        | ${NC}link makefile to current directory"
    echo -e "${GREEN}+---------------+----------------------------------------------------------------+${NC}"
}
