#!/bin/bash

# Simple test script for the animation function
source /datadrive/mcd/mcd_function.sh

echo "Testing animation function..."

# Test the animation function directly
echo "Starting animation test..."
_mcd_show_tab_busy_indicator &
animation_pid=$!

# Let it run for 2 seconds
sleep 2

# Stop the animation
kill $animation_pid 2>/dev/null
wait $animation_pid 2>/dev/null

# Clear the line
printf "\r\x1b[K"

echo "Animation test completed!"

# Test the execute with animation function
echo "Testing execute with animation..."
cd /datadrive/mcd
result=$(_mcd_execute_with_animation "/datadrive/mcd/target/release/mcd" "src" "0")
echo "Result: '$result'"

echo "All tests completed!"
