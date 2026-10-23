#!/bin/bash
# =============================================================
# Connectivity.sh - BETA VM, Task 1: Continuous Connectivity Testing
# Pings ALPHA once and appends the result, with a timestamp, to
# /tmp/SecondVM.txt. The repetition (every 5 minutes) is NOT done by a
# loop inside this script; cron runs the script every 5 minutes:
#     */5 * * * * /full/path/to/Connectivity.sh
#     |   | | | |
#     |   | | | +-- day of week (any)
#     |   | | +---- month (any)
#     |   | +------ day of month (any)
#     |   +-------- hour (any)
#     +------------ minute: every 5th minute (*/5)
# Usage: ./Connectivity.sh [target]     (default target: alpha)
# =============================================================

TARGET="${1:-alpha}"                  # host to test; name resolves through /etc/hosts
OUT="/tmp/SecondVM.txt"               # results file required by the task

timestamp=$(date '+%Y-%m-%d %H:%M:%S')   # time of this test

# Send exactly 1 ping (-c 1) and wait at most 2 seconds for the answer (-W 2).
# Save both the text it prints and its exit code (0 = reply received).
output=$(ping -c 1 -W 2 "$TARGET" 2>&1)
status=$?

# Choose a clear result word for the log line
if [ "$status" -eq 0 ]; then
    result="REACHABLE"
else
    result="UNREACHABLE"
fi

# Append (>>) so earlier results are kept: timestamp, result, full ping output
{
    echo "[$timestamp] $TARGET is $result"
    echo "$output"
    echo "------------------------------------------"
} >> "$OUT"
