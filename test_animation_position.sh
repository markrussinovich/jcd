#!/bin/bash

# Test script to demonstrate the corrected animation positioning
source /datadrive/mcd/mcd_function.sh

echo "Testing animation positioning..."
echo -n "mcd test"  # Simulate a command prompt

# Start the animation
_mcd_show_tab_busy_indicator &
animation_pid=$!

# Let it run for 3 seconds to see the full cycle
sleep 3

# Stop the animation
kill $animation_pid 2>/dev/null
wait $animation_pid 2>/dev/null

# Clean up any remaining dots
printf "\b\b\b   \b\b\b" >&2

echo  # New line after the test
echo "Animation test completed. The dots should have appeared after 'mcd test' without overwriting it."
