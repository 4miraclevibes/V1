#!/bin/bash

echo "Testing 100 samples..."
echo -e "3\n4\n0" | ./test_btp_pattern | tail -10
