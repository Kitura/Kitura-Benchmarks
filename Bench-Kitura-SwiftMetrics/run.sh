#!/bin/bash
#
# Example benchmark suite script. This shows how to use the functions in bench to define
# and execute a simple test suite.
#

# Location of this script
dir=$($(cd `dirname $0`) && pwd)

. $dir/../Bench-Swift/lib/bench.sh
. $dir/../Bench-Swift/lib/build.sh

# Define functions required to execute benchmarks
# (see: Bench-Swift/lib/bench.sh)

function setParams {
    local TESTNAME="$1"
    case "$TESTNAME" in
    SwiftMetrics)
      IMPL1="newBuild/release/HelloWorld"
      IMPL2="newBuild/release/HelloWorldSwiftMetrics"
      IMPL3="newBuild/release/HelloWorldSwiftMetricsHTTP"
      ;;
    SwiftMetricsLight)
      IMPL1="newBuild/release/HelloWorld"
      IMPL2="newBuild/release/HelloWorldSwiftMetrics"
      IMPL3="newBuild/release/HelloWorldSwiftMetricsHTTP"
      CLIENTS=100
      DRIVER="wrk2"
      WORK_RATE=1000
      ;;
    SwiftMetricsIdle)
      IMPL1="newBuild/release/HelloWorld"
      IMPL2="newBuild/release/HelloWorldSwiftMetrics"
      IMPL3="newBuild/release/HelloWorldSwiftMetricsHTTP"
      DURATION=180
      ITERATIONS=1
      DRIVER="sleep"
      ;;
    *)
      echo "Unknown test '$TESTNAME'"
      ;;
    esac
}

#
# Execute a 3-way compare for SwiftMetrics: Off, On and On with HTTP request tracking.
# The baseline in this context is 'Off' - a baseline build is not used.
#
# Adds return code of benchmark process to: $rc
#
function runBenchmark {
    local TESTNAME="$1"

    case "$TESTNAME" in
    SwiftMetrics|SwiftMetricsLight|SwiftMetricsIdle)
      # Execute a 3-way compare of specified implementations
      ./bench/compare.sh $dir/${IMPL1},label=Baseline $dir/${IMPL2},label=SwiftMetrics $dir/${IMPL3},label=SwiftMetricsHTTP
      ;;
    *)
      echo "Unknown test '$TESTNAME'"
      ;;
    esac

    # Update global return code with the result of this run
    rc=$(($rc+$?))
}

###########################
### Benchmark Execution ###
###########################

# Keep track of return code from successive benchmark runs
rc=0

# Allow 'verify' flag to be passed in
BENCHMARK_MODE="$1"

# Create a derectory to hold the benchmark results, renaming an existing directory
# if one exists
preserveDir results

# Test 1: Heavy load
executeTest "SwiftMetrics"
# Test 2: Light load (1000 req/sec)
executeTest "SwiftMetricsLight"
# Test 3: Idle (no requests)
executeTest "SwiftMetricsIdle"

# Exit with resulting return code
exit $rc
