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
    Rymcol-Blog)
      IMPLEMENTATION="Blog"
      URL="http://localhost:8080/blog"
      CLIENTS=50
      DURATION=60
      ITERATIONS=2
      ;;
    Rymcol-JSON)
      IMPLEMENTATION="Blog"
      URL="http://localhost:8080/json"
      CLIENTS=50
      DURATION=30
      ITERATIONS=3
      ;;
    *)
      echo "Unknown test '$TESTNAME'"
      ;;
    esac
}

###########################
### Benchmark Execution ###
###########################

# Keep track of return code from successive benchmark runs
rc=0

# Create a derectory to hold the benchmark results, renaming an existing directory
# if one exists
preserveDir results

executeTest "Rymcol-Blog"
executeTest "Rymcol-JSON"

# Exit with resulting return code
exit $rc
