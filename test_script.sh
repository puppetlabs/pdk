#!/bin/bash

# Intentional issues for testing Reviewdog

# Issue 1: Using eval with unquoted variable (SC2086)
UNSAFE_VAR="*"
eval "ls $UNSAFE_VAR"

# Issue 2: Using rm -rf without caution (SC2115)
rm -rf /tmp/testdir

# Issue 3: Not quoting variables (SC2086)
FILENAME=/tmp/testfile
touch $FILENAME
cat $FILENAME

# Issue 4: Useless use of cat (SC2002)
cat /tmp/testfile | grep "test"