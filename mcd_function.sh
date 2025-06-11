#!/bin/bash

# MCD Shell Function - Enhanced Directory Navigation with Inline Tab Completion
# Usage: Add "source /path/to/mcd_function.sh" to your ~/.bashrc

mcd() {
    if [ $# -ne 1 ]; then
        echo "Usage: mcd <directory_pattern>"
        return 1
    fi
    local search_term="$1"
    local mcd_binary="${MCD_BINARY:-/datadrive/mcd/target/release/mcd}"
    
    # Ensure binary exists
    if [ ! -x "$mcd_binary" ]; then
        echo "Error: MCD binary not found at $mcd_binary"
        return 1
    fi
    
    # Handle simple directory navigation cases directly in shell for better performance
    case "$search_term" in
        "..")
            cd .. 2>/dev/null || echo "Cannot navigate to parent directory"
            return $?
            ;;
        "../..")
            cd ../.. 2>/dev/null || echo "Cannot navigate to ../../"
            return $?
            ;;
        "../../..")
            cd ../../.. 2>/dev/null || echo "Cannot navigate to ../../../"
            return $?
            ;;
        "../../../..")
            cd ../../../.. 2>/dev/null || echo "Cannot navigate to ../../../../"
            return $?
            ;;
        ".")
            # Stay in current directory
            return 0
            ;;
    esac
    
    # Get the best match (index 0)
    local dest
    dest=$("$mcd_binary" "$search_term" 0)
    if [ $? -ne 0 ] || [ -z "$dest" ]; then
        echo "No directories found matching '$search_term'"
        return 1
    fi
    cd "$dest"
}

# Global variables to store completion state
_MCD_ORIGINAL_PATTERN=""
_MCD_CURRENT_MATCHES=()
_MCD_CURRENT_INDEX=0
_MCD_IS_RELATIVE_PATTERN=false
_MCD_COMPLETION_MODE=""  # "initial", "cycling", "leaf"
_MCD_LAST_COMPLETION=""
_MCD_IS_LEAF_DIR=false
_MCD_LEAF_COMPLETION_COUNT=0

# Debug flag - set to 1 to enable debug output
_MCD_DEBUG="${MCD_DEBUG:-0}"
_mcd_debug() { [[ "$_MCD_DEBUG" == "1" ]] && echo "DEBUG: $*" >&2; }

_mcd_reset_state() {
    _mcd_debug "=== RESETTING STATE ==="
    _MCD_ORIGINAL_PATTERN=""
    _MCD_CURRENT_MATCHES=()
    _MCD_CURRENT_INDEX=0
    _MCD_IS_RELATIVE_PATTERN=false
    _MCD_COMPLETION_MODE=""
    _MCD_LAST_COMPLETION=""
    _MCD_IS_LEAF_DIR=false
    _MCD_LEAF_COMPLETION_COUNT=0
}

# (… all of your unchanged state-reset & state-detect functions here …)

# Show busy indicator with dots animation for tab completion
_mcd_show_tab_busy_indicator() {
    sleep 0.5
    local dot_count=0
    while true; do
        # restore to saved spot, clear line
        printf "\033[u\033[K" >&2
        case $dot_count in
            0) printf "" >&2 ;;
            1) printf "." >&2 ;;
            2) printf ".." >&2 ;;
            3) printf "..." >&2 ;;            
        esac
        dot_count=$(( (dot_count + 1) % 4 ))
        sleep 0.3
    done
}

# -----------------------------------------------------------------------------
# Wrapper to run any single function under one continuous animation
# -----------------------------------------------------------------------------
_mcd_run_with_animation() {
    # **BUG FIX:** save cursor **once** before the animation begins
    printf "\033[s" >&2

    # start the spinner in the background
    _mcd_show_tab_busy_indicator &
    local animation_pid=$!

    # run the real work
    local output
    output=$("$@")
    local exit_code=$?

    # stop the spinner
    kill $animation_pid 2>/dev/null
    wait $animation_pid 2>/dev/null

    # **BUG FIX:** restore cursor and clear the line after animation
    printf "\033[u\033[K" >&2

    # emit the actual output to the caller
    echo "$output"
    return $exit_code
}

# Get all matches for a relative pattern
_mcd_get_relative_matches() {
    local pattern="$1"
    local mcd_binary="${MCD_BINARY:-/datadrive/mcd/target/release/mcd}"
    local matches=()
    local idx=0
    local match

    _mcd_debug "getting relative matches for pattern '$pattern'"

    # Handle special cases for directory navigation patterns
    case "$pattern" in
        "..")
            # For "..", complete to parent directory if it exists
            local parent_dir="$(dirname "$PWD")"
            if [[ -d "$parent_dir" ]] && [[ "$parent_dir" != "$PWD" ]]; then
                matches+=("$parent_dir")
                _mcd_debug "  parent directory match: '$parent_dir'"
            fi
            ;;
        "../.." | "../../.." | "../../../..")
            # For multiple parent levels, complete to the resolved directory
            local resolved_dir="$PWD"
            local path_components="${pattern//[^\/]}"
            local level_count=$((${#path_components} / 3)) # Each "../" has 3 chars including /
            
            for ((i=0; i<level_count; i++)); do
                resolved_dir="$(dirname "$resolved_dir")"
                if [[ "$resolved_dir" == "/" ]]; then
                    break
                fi
            done
            
            if [[ -d "$resolved_dir" ]]; then
                matches+=("$resolved_dir")
                _mcd_debug "  multi-level parent match: '$resolved_dir'"
            fi
            ;;
        ".")
            # For ".", complete to current directory
            matches+=("$PWD")
            _mcd_debug "  current directory match: '$PWD'"
            ;;
        *)
            # Handle relative patterns that contain navigation and search terms
            if [[ "$pattern" == ../* ]] && [[ "$pattern" != "../.." ]] && [[ "$pattern" != "../../.." ]]; then
                # Pattern like "../foo" - resolve the relative part and search
                local resolved_dir="$PWD"
                local nav_part="${pattern%%[^./]*}"  # Gets "../" or "../../" etc.
                local search_part="${pattern#$nav_part}"  # Gets the search term after navigation
                
                _mcd_debug "  split pattern: nav='$nav_part' search='$search_part'"
                
                # Navigate to the relative directory
                local nav_count=$(echo "$nav_part" | grep -o "\\.\\." | wc -l)
                for ((i=0; i<nav_count; i++)); do
                    resolved_dir="$(dirname "$resolved_dir")"
                    if [[ "$resolved_dir" == "/" ]]; then
                        break
                    fi
                done
                
                _mcd_debug "  resolved base directory: '$resolved_dir'"
                
                if [[ -d "$resolved_dir" ]] && [[ -n "$search_part" ]]; then
                    # Search for directories matching the pattern in the resolved directory
                    while IFS= read -r -d $'\0' dir; do
                        if [[ -d "$dir" ]]; then
                            local dir_name="$(basename "$dir")"
                            if [[ "$dir_name" == *"$search_part"* ]]; then
                                matches+=("$dir")
                                _mcd_debug "    found relative pattern match: '$dir'"
                            fi
                        fi
                    done < <(find "$resolved_dir" -maxdepth 1 -type d -not -path "$resolved_dir" -print0 2>/dev/null | sort -z)
                fi
            else
                # Use the mcd binary directly, no per-call animation
                while true; do
                    match=$("$mcd_binary" "$pattern" "$idx" --quiet 2>/dev/null)
                    if [ $? -ne 0 ] || [ -z "$match" ]; then
                        break
                    fi
                    _mcd_debug "  relative match #$idx: '$match'"
                    matches+=("$match")
                    idx=$((idx + 1))
                    # Safety limit to prevent infinite loops
                    if [ $idx -gt 100 ]; then
                        break
                    fi
                done
            fi
            ;;
    esac
    
    _mcd_debug "found ${#matches[@]} relative matches"
    if [ ${#matches[@]} -eq 0 ]; then
        _mcd_debug "returning empty result (no printf output)"
        return 0
    fi
    printf '%s\n' "${matches[@]}"
}

# Get all matches for an absolute pattern
_mcd_get_absolute_matches() {
    local pattern="$1"
    local matches=()
    
    _mcd_debug "getting absolute matches for pattern '$pattern'"
    
    # Handle relative path patterns that start with ../
    if [[ "$pattern" == ../* ]]; then
        _mcd_debug "  pattern starts with ../, using relative match logic"
        local match_output
        match_output=$(_mcd_get_relative_matches "$pattern")
        if [[ -n "$match_output" ]]; then
            readarray -t matches <<<"$match_output"
        fi
        _mcd_debug "found ${#matches[@]} matches via relative logic"
        if [ ${#matches[@]} -eq 0 ]; then
            _mcd_debug "returning empty result (no printf output)"
            return 0
        fi
        printf '%s\n' "${matches[@]}"
        return 0
    fi
    
    # If the path ends with '/', look for subdirectories
    if [[ "$pattern" == */ ]]; then
        local dir_path="${pattern%/}"
        _mcd_debug "  looking for subdirectories under '$dir_path'"
        if [[ -d "$dir_path" ]]; then
            # Get immediate subdirectories only (breadth-first)
            while IFS= read -r -d $'\0' dir; do
                if [[ -d "$dir" ]] && [[ "$dir" != "$dir_path" ]]; then
                    # Add WITHOUT trailing slash so user can add / to explore deeper
                    matches+=("$dir")
                    _mcd_debug "    found subdir: '$dir' (NO SLASH)"
                fi
            done < <(find "$dir_path" -maxdepth 1 -type d -not -path "$dir_path" -print0 2>/dev/null | sort -z)
        else
            _mcd_debug "    directory '$dir_path' does not exist"
        fi
    else
        # Look for directories that match the pattern
        local parent_dir="$(dirname "$pattern")"
        local name_pattern="$(basename "$pattern")"
        
        _mcd_debug "  looking for dirs matching '$name_pattern' in '$parent_dir'"
        
        if [[ -d "$parent_dir" ]]; then
            # Handle root directory case to avoid double slash
            local search_pattern
            if [[ "$parent_dir" == "/" ]]; then
                search_pattern="/$name_pattern"*
            else
                search_pattern="$parent_dir/$name_pattern"*
            fi
            
            _mcd_debug "    using glob pattern: '$search_pattern'"
            
            # Use bash glob expansion with proper escaping
            shopt -s nullglob
            for dir in $search_pattern; do
                if [[ -d "$dir" ]]; then
                    matches+=("$dir")
                    _mcd_debug "    found match: '$dir'"
                fi
            done
            shopt -u nullglob
            
            # Sort the matches
            if [ ${#matches[@]} -gt 1 ]; then
                IFS=$'\n' matches=($(sort <<<"${matches[*]}"))
                _mcd_debug "    sorted ${#matches[@]} matches"
            fi
        else
            _mcd_debug "    parent directory '$parent_dir' does not exist"
        fi
    fi
    
    _mcd_debug "found ${#matches[@]} absolute matches"
    if [ ${#matches[@]} -eq 0 ]; then
        _mcd_debug "returning empty result (no printf output)"
        return 0
    fi
    printf '%s\n' "${matches[@]}"
}

# Find current position in match array (handle trailing slash variations)
_mcd_find_current_index() {
    local cur="$1"
    local idx=0
    
    _mcd_debug "finding current index for '$cur' in ${#_MCD_CURRENT_MATCHES[@]} matches"
    
    for match in "${_MCD_CURRENT_MATCHES[@]}"; do
        _mcd_debug "  checking match #$idx: '$match'"
        # Check exact match and also handle trailing slash differences
        if [[ "$match" == "$cur" ]] || [[ "${match%/}" == "${cur%/}" ]]; then
            _mcd_debug "  -> found at index $idx"
            echo "$idx"
            return 0
        fi
        idx=$((idx + 1))
    done
    
    _mcd_debug "  -> not found (-1)"
    echo "-1"
}

# Inline tab completion cycling for mcd
_mcd_tab_complete() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local prev="${COMP_WORDS[COMP_CWORD-1]}"

    _mcd_debug ""
    _mcd_debug "=== TAB COMPLETION CALLED ==="
    _mcd_debug "cur='$cur' prev='$prev' COMP_CWORD=$COMP_CWORD"

    # Only complete the first argument
    if [ $COMP_CWORD -ne 1 ]; then
        _mcd_debug "not completing first argument, returning"
        return 0
    fi

    # Check if we should reset state
    if _mcd_should_reset_state "$cur"; then
        _mcd_debug "RESET TRIGGERED - clearing all state"
        _mcd_reset_state
    else
        _mcd_debug "CONTINUING with existing state"
    fi
    
    # Special handling for leaf mode with trailing slash
    if [[ "$_MCD_COMPLETION_MODE" == "leaf" ]] && [[ "$cur" == "$_MCD_ORIGINAL_PATTERN/" ]]; then
        _mcd_debug "leaf mode: user added slash to leaf directory, completing back to directory without slash"
        COMPREPLY=("$_MCD_ORIGINAL_PATTERN")
        return 0
    fi
    
    # Special handling for leaf mode - don't get new matches, just complete the leaf directory
    if [[ "$_MCD_COMPLETION_MODE" == "leaf" ]] && [[ "$cur" == "$_MCD_ORIGINAL_PATTERN" ]]; then
        _MCD_LEAF_COMPLETION_COUNT=$((_MCD_LEAF_COMPLETION_COUNT + 1))
        _mcd_debug "leaf mode: completing leaf directory without slash (attempt #$_MCD_LEAF_COMPLETION_COUNT)"
        
        # After 2 attempts in leaf mode, reset back to parent directory exploration
        if [[ $_MCD_LEAF_COMPLETION_COUNT -ge 2 ]]; then
            _mcd_debug "leaf mode: user has seen leaf directory multiple times, resetting to parent directory"
            local parent_dir="$(dirname "$_MCD_ORIGINAL_PATTERN")"
            if [[ "$parent_dir" != "$_MCD_ORIGINAL_PATTERN" ]] && [[ -d "$parent_dir" ]]; then
                _mcd_reset_state
                # Set up for parent directory exploration
                _MCD_ORIGINAL_PATTERN="$parent_dir/"
                _MCD_IS_RELATIVE_PATTERN=false
                local match_output
                match_output=$(_mcd_get_absolute_matches "$parent_dir/")
                if [[ -n "$match_output" ]]; then
                    readarray -t _MCD_CURRENT_MATCHES <<<"$match_output"
                    _MCD_COMPLETION_MODE="cycling"
                    _MCD_CURRENT_INDEX=0
                    _mcd_debug "reset to parent directory cycling with ${#_MCD_CURRENT_MATCHES[@]} matches"
                    # Find the original leaf directory in the matches and start from there
                    local leaf_dir_name="$(basename "$cur")"
                    for i in "${!_MCD_CURRENT_MATCHES[@]}"; do
                        if [[ "$(basename "${_MCD_CURRENT_MATCHES[i]}")" == "$leaf_dir_name" ]]; then
                            _MCD_CURRENT_INDEX=$i
                            _mcd_debug "found leaf dir at index $i, cycling to next"
                            break
                        fi
                    done
                    # Advance to next match
                    _MCD_CURRENT_INDEX=$(( (_MCD_CURRENT_INDEX + 1) % ${#_MCD_CURRENT_MATCHES[@]} ))
                    COMPREPLY=("${_MCD_CURRENT_MATCHES[$_MCD_CURRENT_INDEX]}")
                    return 0
                fi
            fi
            # Fallback: just reset completely
            _mcd_reset_state
            COMPREPLY=()
            return 0
        fi
        
        # First attempt: just complete the leaf directory
        COMPREPLY=("$_MCD_ORIGINAL_PATTERN")
        return 0
    fi
    
    # If we don't have matches cached, get them (wrapped in one animation)
    if [[ ${#_MCD_CURRENT_MATCHES[@]} -eq 0 ]]; then
        _mcd_debug "no cached matches, getting new ones"
        
        if [[ "$cur" == /* ]]; then
            # Absolute pattern
            _mcd_debug "treating '$cur' as absolute pattern"
            _MCD_ORIGINAL_PATTERN="$cur"
            _MCD_IS_RELATIVE_PATTERN=false
            local match_output
            match_output=$(_mcd_run_with_animation _mcd_get_absolute_matches "$cur")
            _mcd_debug "raw match output: '$match_output'"
            if [[ -n "$match_output" ]]; then
                readarray -t _MCD_CURRENT_MATCHES <<<"$match_output"
            else
                _MCD_CURRENT_MATCHES=()
                _mcd_debug "explicitly set empty array for empty match output"
            fi
        elif [[ "$cur" == ../* ]] || [[ "$cur" == ./* ]] || [[ "$cur" == "." ]] || [[ "$cur" == ".." ]]; then
            # Relative pattern (including ../, ./, ., ..)
            _mcd_debug "treating '$cur' as relative pattern"
            _MCD_ORIGINAL_PATTERN="$cur"
            _MCD_IS_RELATIVE_PATTERN=true
            local match_output
            match_output=$(_mcd_run_with_animation _mcd_get_relative_matches "$cur")
            _mcd_debug "raw match output: '$match_output'"
            if [[ -n "$match_output" ]]; then
                readarray -t _MCD_CURRENT_MATCHES <<<"$match_output"
            else
                _MCD_CURRENT_MATCHES=()
                _mcd_debug "explicitly set empty array for empty match output"
            fi
        else
            # Regular relative pattern (no explicit path prefix)
            _mcd_debug "treating '$cur' as regular relative pattern"
            _MCD_ORIGINAL_PATTERN="$cur"
            _MCD_IS_RELATIVE_PATTERN=true
            local match_output
            match_output=$(_mcd_run_with_animation _mcd_get_relative_matches "$cur")
            _mcd_debug "raw match output: '$match_output'"
            if [[ -n "$match_output" ]]; then
                readarray -t _MCD_CURRENT_MATCHES <<<"$match_output"
            else
                _MCD_CURRENT_MATCHES=()
                _mcd_debug "explicitly set empty array for empty match output"
            fi
        fi
        
        # Don't override completion mode if we're already in leaf mode
        if [[ "$_MCD_COMPLETION_MODE" != "leaf" ]]; then
            _MCD_COMPLETION_MODE="initial"
        fi
        _MCD_CURRENT_INDEX=0
        _mcd_debug "cached ${#_MCD_CURRENT_MATCHES[@]} matches, set mode to $_MCD_COMPLETION_MODE"
        _mcd_debug "actual matches array: [${_MCD_CURRENT_MATCHES[*]}]"
    else
        _mcd_debug "using ${#_MCD_CURRENT_MATCHES[@]} cached matches"
    fi
    
    # If no matches found, check if we were trying to explore subdirectories
    if [ ${#_MCD_CURRENT_MATCHES[@]} -eq 0 ]; then
        # If original pattern ended with '/' (subdirectory exploration) but no subdirs found,
        # this is a leaf directory - tab should have no effect
        if [[ "$_MCD_ORIGINAL_PATTERN" == */ ]]; then
            local dir_without_slash="${_MCD_ORIGINAL_PATTERN%/}"
            if [[ -d "$dir_without_slash" ]]; then
                _mcd_debug "no subdirectories found in leaf directory, tab has no effect: '$dir_without_slash'"
                # Set leaf state but don't change the user's input
                _MCD_IS_LEAF_DIR=true
                _MCD_COMPLETION_MODE="leaf"
                _MCD_CURRENT_MATCHES=()  # Keep empty to indicate no completions available
                COMPREPLY=()  # No completion - tab has no effect
                return 0
            fi
        fi
        
        _mcd_debug "no matches found, clearing state"
        _mcd_reset_state
        COMPREPLY=()
        return 0
    fi
    
    # If only one match, complete it and reset state
    if [ ${#_MCD_CURRENT_MATCHES[@]} -eq 1 ]; then
        local completion="${_MCD_CURRENT_MATCHES[0]}"
        
        # Check if we're already at a leaf directory to prevent infinite loop
        if [[ "$_MCD_IS_LEAF_DIR" == true ]] && [[ "$completion" == "$_MCD_ORIGINAL_PATTERN" ]] && [[ "$_MCD_COMPLETION_MODE" == "leaf" ]]; then
            _mcd_debug "already at leaf directory, not adding slash to prevent loop: '$completion'"
            COMPREPLY=("$completion")
            return 0
        fi
        
        # If the single match is a directory, add trailing slash for easy Enter/Tab choice
        if [[ -d "$completion" ]] && [[ "$_MCD_COMPLETION_MODE" != "leaf" ]]; then
            completion="$completion/"
            _mcd_debug "only one match is a directory, adding trailing slash for easy navigation: '$completion'"
        else
            if [[ "$_MCD_COMPLETION_MODE" == "leaf" ]]; then
                _mcd_debug "leaf mode: not adding trailing slash to prevent loop: '$completion'"
            else
                _mcd_debug "only one match, completing and resetting: '$completion'"
            fi
        fi
        
        _mcd_debug "match array length: ${#_MCD_CURRENT_MATCHES[@]}, contents: [${_MCD_CURRENT_MATCHES[*]}]"
        COMPREPLY=("$completion")
        
        # Don't reset state if we're in leaf mode - maintain the leaf state
        if [[ "$_MCD_COMPLETION_MODE" != "leaf" ]]; then
            _mcd_reset_state
        else
            _mcd_debug "maintaining leaf mode state, not resetting"
        fi
        return 0
    fi
    
    _mcd_debug "multiple matches (${#_MCD_CURRENT_MATCHES[@]}), handling cycling"
    _mcd_debug "current mode: '$_MCD_COMPLETION_MODE', current index: $_MCD_CURRENT_INDEX"
    
    # Handle cycling through multiple matches
    if [[ "$_MCD_COMPLETION_MODE" == "cycling" ]]; then
        # Already cycling - advance to next match
        _MCD_CURRENT_INDEX=$(( (_MCD_CURRENT_INDEX + 1) % ${#_MCD_CURRENT_MATCHES[@]} ))
        _mcd_debug "already cycling, advanced to index $_MCD_CURRENT_INDEX"
    else
        # Check if current input matches one of our results
        local current_idx
        current_idx=$(_mcd_find_current_index "$cur")
        
        if [[ $current_idx -ge 0 ]]; then
            # Current input matches a result - start cycling from next
            _MCD_CURRENT_INDEX=$(( (current_idx + 1) % ${#_MCD_CURRENT_MATCHES[@]} ))
            _MCD_COMPLETION_MODE="cycling"
            _mcd_debug "current input matches result #$current_idx, cycling to index $_MCD_CURRENT_INDEX"
        else
            # Special case: if we're in subdirectory expansion mode (original pattern ended with /)
            # and current input is the original pattern, start with first match
            if [[ "$_MCD_ORIGINAL_PATTERN" == */ ]] && [[ "${cur%/}" == "${_MCD_ORIGINAL_PATTERN%/}" ]]; then
                _MCD_CURRENT_INDEX=0
                _MCD_COMPLETION_MODE="cycling"
                _mcd_debug "subdirectory expansion mode detected, starting at index 0"
            else
                # Start with first match
                _MCD_CURRENT_INDEX=0
                _MCD_COMPLETION_MODE="initial"
                _mcd_debug "no current match found, starting with first match (index 0)"
            fi
        fi
    fi
    
    # Set completion mode to cycling for subsequent tabs
    _MCD_COMPLETION_MODE="cycling"
    
    # Store what we're about to complete
    _MCD_LAST_COMPLETION="${_MCD_CURRENT_MATCHES[$_MCD_CURRENT_INDEX]}"
    
    _mcd_debug "completing with: '$_MCD_LAST_COMPLETION' (index $_MCD_CURRENT_INDEX)"
    _mcd_debug "state after completion: mode='$_MCD_COMPLETION_MODE' pattern='$_MCD_ORIGINAL_PATTERN'"
    
    COMPREPLY=("$_MCD_LAST_COMPLETION")
}

# Clear mcd completion state when command is executed or changed
_mcd_clear_on_execute() {
    # Only clear if we're not in the middle of completing an mcd command
    if [[ "${BASH_COMMAND}" != *"mcd "* ]] && [[ "${BASH_COMMAND}" != *"_mcd_"* ]]; then
        _mcd_debug "clearing state on command execute: '${BASH_COMMAND}'"
        _mcd_reset_state
    fi
}

# Register the completion function
complete -o nospace -F _mcd_tab_complete mcd

# Hook to clear state when command is executed (but not during completion)
trap '_mcd_clear_on_execute' DEBUG

# Export the function
export -f mcd

# Clear any existing state when script is loaded to ensure clean start
_mcd_reset_state

echo "MCD completion loaded. Set MCD_DEBUG=1 to enable debug output." >&2
