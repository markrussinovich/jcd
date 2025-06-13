#!/bin/bash

echo "=== Quick Regression Test for MCD Changes ==="
echo "Testing that existing functionality still works after absolute path consistency fix"
echo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASSED=0
FAILED=0

test_result() {
    local description="$1"
    local command="$2" 
    local expected_pattern="$3"
    
    echo -e "\n${YELLOW}Testing:${NC} $description"
    echo "Command: $command"
    
    result=$(eval "$command" 2>/dev/null)
    exit_code=$?
    
    if [[ $exit_code -eq 0 ]] && [[ "$result" =~ $expected_pattern ]]; then
        echo -e "${GREEN}✓ PASSED${NC} - Result: $result"
        ((PASSED++))
    else
        echo -e "${RED}✗ FAILED${NC} - Result: $result (exit code: $exit_code)"
        echo "Expected pattern: $expected_pattern"
        ((FAILED++))
    fi
}

# Setup test structure
echo "Setting up test structure..."
rm -rf /tmp/mcd_regression_test
mkdir -p /tmp/mcd_regression_test/{parent/{child1,child2},sibling/{sub1,sub2},foo/{bar,baz}}

cd /tmp/mcd_regression_test/parent/child1
echo "Test directory: $(pwd)"
echo "Structure created:"
find /tmp/mcd_regression_test -type d | sort

# Test core relative path functionality
echo -e "\n=== Testing Core Relative Path Functionality ==="

test_result "Parent navigation with '..'" \
           "/datadrive/mcd/target/release/mcd '..'" \
           ".*/parent$"

test_result "Grandparent navigation with '../..'" \
           "/datadrive/mcd/target/release/mcd '../..'" \
           ".*/mcd_regression_test$"

test_result "Relative pattern '../child2'" \
           "/datadrive/mcd/target/release/mcd '../child2'" \
           ".*/child2$"

test_result "Deep relative pattern '../../foo'" \
           "/datadrive/mcd/target/release/mcd '../../foo'" \
           ".*/foo$"

test_result "Pattern matching '../ch' (first match)" \
           "/datadrive/mcd/target/release/mcd '../ch' 0" \
           ".*/child[12]$"

# Test absolute path functionality (new feature)
echo -e "\n=== Testing Absolute Path Functionality (New) ==="

# Create a unique test directory that won't exist in root
mkdir -p /tmp/mcd_regression_test/unique_test_dir_xyz123

test_result "Relative pattern 'unique_test'" \
           "/datadrive/mcd/target/release/mcd 'unique_test'" \
           ".*/unique_test_dir_xyz123$"

test_result "Absolute pattern '/unique_test' (should match relative behavior)" \
           "/datadrive/mcd/target/release/mcd '/unique_test'" \
           ".*/unique_test_dir_xyz123$"

# Test immediate match prioritization (recent fix)
echo -e "\n=== Testing Immediate Match Prioritization ==="

cd /tmp/mcd_regression_test
mkdir -p immediate_test/{un,unmemorize,unmemorize-demo}
cd immediate_test

test_result "Multiple immediate matches for 'un' (should return quickly)" \
           "timeout 2s /datadrive/mcd/target/release/mcd 'un' 0" \
           ".*/un$"

test_result "Second match for 'un' pattern" \
           "/datadrive/mcd/target/release/mcd 'un' 1" \
           ".*/unmemorize"

# Test shell function basic functionality
echo -e "\n=== Testing Shell Function ==="

cd /tmp/mcd_regression_test/parent/child1
export MCD_BINARY="/datadrive/mcd/target/release/mcd"
source /datadrive/mcd/mcd_function.sh 2>/dev/null

# Test if shell function is loaded
if declare -f mcd > /dev/null; then
    echo -e "${GREEN}✓ PASSED${NC} - Shell function loaded"
    ((PASSED++))
else
    echo -e "${RED}✗ FAILED${NC} - Shell function not loaded"
    ((FAILED++))
fi

# Test shell function navigation
original_dir=$(pwd)
echo "Testing shell function navigation from: $original_dir"

mcd ".." 2>/dev/null
current_dir=$(pwd)
if [[ "$current_dir" == "/tmp/mcd_regression_test/parent" ]]; then
    echo -e "${GREEN}✓ PASSED${NC} - Shell function navigation works"
    ((PASSED++))
else
    echo -e "${RED}✗ FAILED${NC} - Expected /tmp/mcd_regression_test/parent, got $current_dir"
    ((FAILED++))
fi

# Cleanup
echo -e "\n=== Cleanup ==="
rm -rf /tmp/mcd_regression_test
echo "Test structure cleaned up"

# Summary
echo -e "\n=== Test Summary ==="
total=$((PASSED + FAILED))
echo "Total tests: $total"
echo -e "${GREEN}Passed: $PASSED${NC}"
if [[ $FAILED -gt 0 ]]; then
    echo -e "${RED}Failed: $FAILED${NC}"
fi

if [[ $FAILED -eq 0 ]]; then
    echo -e "\n${GREEN}🎉 All regression tests passed!${NC}"
    echo "The absolute path consistency fix did not break existing functionality."
    exit 0
else
    echo -e "\n${RED}❌ Some tests failed - potential regression detected!${NC}"
    exit 1
fi