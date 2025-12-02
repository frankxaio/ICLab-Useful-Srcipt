# This script should be sourced
# Usage: source cd.csh <argument>

if ( ! $?ROOT_PATH ) then
    echo "Error: ROOT_PATH is not defined."
else if ( $#argv > 0 ) then
    set input = "$1"
    set target_pattern = ""

    switch ( "$input" )
        case [0-9]:
            # Single digit -> 0X_*
            set target_pattern = "0${input}_*"
            breaksw
        case [1-9][0-9]:
            # Double digit -> XX_*
            set target_pattern = "${input}_*"
            breaksw
        case m:
            set target_dir_direct = "$ROOT_PATH/Memory"
            if ( -d "$target_dir_direct" ) then
                cd "$target_dir_direct"
                echo "${GREEN}Current directory: `pwd`${NC}"
            else
                echo "${RED}Directory 'Memory' not found in $ROOT_PATH${NC}"
            endif
            breaksw
        default:
            breaksw
    endsw

    if ( "$target_pattern" != "" ) then
        # Find directory using find
        set found_dir = `find "$ROOT_PATH" -maxdepth 1 -type d -name "$target_pattern" -print -quit`

        if ( "$found_dir" != "" ) then
            cd "$found_dir"
            echo "${GREEN}Current directory: `pwd`${NC}"
        else
            echo "${RED}Directory matching '$target_pattern' not found in $ROOT_PATH${NC}"
        endif
    endif
endif

exit_script: