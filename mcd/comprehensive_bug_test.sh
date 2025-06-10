#!/bin/bash

# Test for mcd command functionality

# Test case for directory expansion
echo "Testing directory expansion for 'mcd 4'..."
output=$(./mcd 4)
expected_output="foo/foo1/foo2/foo3a/foo4"
if [ "$output" == "$expected_output" ]; then
    echo "Pass: 'mcd 4' correctly expands to $expected_output"
else
    echo "Fail: 'mcd 4' expected $expected_output but got $output"
fi

# Test case for tab completion
echo "Testing tab completion after 'mcd foo/foo1/foo2/foo3a/'..."
tab_completion_output=$(./mcd foo/foo1/foo2/foo3a/ | grep foo/foo1/foo2/foo3b/foo4)
if [ -n "$tab_completion_output" ]; then
    echo "Pass: Tab completion offers foo/foo1/foo2/foo3b/foo4"
else
    echo "Fail: Tab completion did not offer expected directory"
fi

# Edge case: Typing 'mcd /tmp/' should offer subdirectories
echo "Testing edge case for 'mcd /tmp/'..."
edge_case_output=$(./mcd /tmp/)
expected_edge_case_output="datadrive"
if [[ "$edge_case_output" == *"$expected_edge_case_output"* ]]; then
    echo "Pass: 'mcd /tmp/' offers subdirectories of datadrive"
else
    echo "Fail: 'mcd /tmp/' did not offer expected subdirectories"
fi

# Additional edge cases can be added here

echo "Comprehensive bug test completed."