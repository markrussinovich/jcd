#!/bin/bash

# Test the tab completion animation by logging to a file
LOG_FILE="/tmp/mcd_animation_test.log"
echo "Starting MCD animation test at $(date)" > "$LOG_FILE"

# Source the functions
source /datadrive/mcd/mcd_function.sh >> "$LOG_FILE" 2>&1

echo "Testing _mcd_execute_with_animation function..." >> "$LOG_FILE"

# Test the execute with animation function
cd /datadrive/mcd
echo "Current directory: $(pwd)" >> "$LOG_FILE"
echo "Testing binary path: /datadrive/mcd/target/release/mcd" >> "$LOG_FILE"

# Test if binary exists
if [ -x "/datadrive/mcd/target/release/mcd" ]; then
    echo "Binary exists and is executable" >> "$LOG_FILE"
else
    echo "Binary not found or not executable" >> "$LOG_FILE"
fi

# Test the animation wrapper function
echo "Calling _mcd_execute_with_animation..." >> "$LOG_FILE"
result=$(_mcd_execute_with_animation "/datadrive/mcd/target/release/mcd" "src" "0" 2>>"$LOG_FILE")
echo "Result from animation function: '$result'" >> "$LOG_FILE"

# Test the relative matches function that uses animation
echo "Testing _mcd_get_relative_matches..." >> "$LOG_FILE"
matches=$(_mcd_get_relative_matches "src" 2>>"$LOG_FILE")
echo "Matches from relative search: '$matches'" >> "$LOG_FILE"

echo "Test completed at $(date)" >> "$LOG_FILE"

# Show the log file
echo "Test log contents:" && cat "$LOG_FILE"
