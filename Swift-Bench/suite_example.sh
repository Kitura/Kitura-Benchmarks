#!/bin/bash
#
# Example benchmark suite script. This shows how to use the functions in bench to define
# and execute a simple test suite.
#

# Location of this script
dir=$($(cd `dirname $0`) && pwd)

. $dir/bench/lib/bench.sh

# Define functions required to execute benchmarks
# (see: bench/lib/bench.sh)

function setParams {
    local TESTNAME="$1"
    case "$TESTNAME" in
    MyTest1)
      IMPLEMENTATION="MyTest"
      URL="http://localhost:8080/plaintext"
      DURATION=10
      ITERATIONS=2
      ;;
    MyTest2)
      IMPLEMENTATION="YourTest"
      URL="http://localhost:8080/json"
      DURATION=30
      ITERATIONS=2
      ;;
    *)
      echo "Unknown test $TESTNAME"
      ;;
    esac
}

function runBenchmark {
    local TESTNAME="$1"
    case "$TESTNAME" in
    MyTest1|MyTest2)
      # Execute a 2-way compare of our benchmark from two builds
      results=`$dir/bench/compare.sh $dir/baselineBuild/release/${IMPLEMENTATION},label=Baseline,pwd=$dir $dir/newBuild/release/${IMPLEMENTATION},label=New,pwd=$dir`
      ;;
    *)
      echo "Unknown test $TESTNAME"
      ;;
    esac
    # Update global return code with the result of this run
    rc=$(($rc+$?))
}

# Keep track of return code from successive benchmark runs
rc=0

# Execute benchmarks

executeTest "MyTest1"
executeTest "MyTest2"

# Exit with resulting return code
exit $rc
