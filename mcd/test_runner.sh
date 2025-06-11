#!/bin/bash
set -e

echo "Running unit tests..."
cargo test --test completion_tests

echo "Running integration tests..."
cargo test --test tab_completion_tests
cargo test --test edge_case_tests

echo "All tests completed successfully."