# MCD Test Suite

This directory contains test scripts for the MCD (Enhanced Directory Navigation) tool.

## Test Scripts

### `test_relative_comprehensive.sh`
**Primary regression test suite**
- Comprehensive testing of all relative path functionality
- 10 test cases covering navigation patterns, search contexts, and edge cases
- Performance timing and pass/fail reporting
- Should be run before any release

Usage:
```bash
./tests/test_relative_comprehensive.sh
```

### `validate_mcd.sh` 
**Quick validation script**
- Lightweight smoke test for CI/CD pipelines
- Verifies binary exists and basic functionality works
- Fast execution suitable for automated workflows

Usage:
```bash
./tests/validate_mcd.sh
```

### `verify_basic_functionality.py`
**Python-based comprehensive test**
- Tests core MCD functionality including relative path navigation
- Tests case sensitivity functionality with `-i` flag
- Cross-platform Python script for reliable testing
- No external dependencies beyond standard library

Usage:
```bash
python3 tests/verify_basic_functionality.py
```

### `test_case_sensitivity.sh`
**Standalone case sensitivity test**
- Dedicated test for the new `-i` flag functionality
- Tests both case insensitive (default) and case sensitive modes
- Bash-based test with comprehensive scenarios

Usage:
```bash
./tests/test_case_sensitivity.sh
```

### `simple_test.sh`
**Manual testing and documentation**
- Good for manual verification during development
- Clear test structure documentation
- Intermediate complexity testing

Usage:
```bash
./tests/simple_test.sh
```

## Running Tests

### All Tests
```bash
# Run comprehensive test suite
./tests/test_relative_comprehensive.sh

# Quick validation
./tests/validate_mcd.sh
```

### CI/CD Integration
For automated testing, use the validate script:
```bash
./tests/validate_mcd.sh && echo "Tests passed"
```

## Test Requirements

- Tests require the compiled binary at `target/release/mcd`
- Tests create temporary directories under `/tmp/mcd_test/`
- All tests clean up after themselves
- Tests should be run from the project root directory
