#!/bin/bash
mkdir -p foo/foo1/foo2/foo3a
mkdir -p foo/foo1/foo2/foo3b
touch foo/foo1/foo2/foo3a/foo4
touch foo/foo1/foo2/foo3b/foo4
export TEST_DIR=$(pwd)/foo
cd $TEST_DIR