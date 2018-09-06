#!/bin/bash
#
# Example benchmark suite script. This shows how to use the functions in bench to define
# and execute a simple test suite.
#

# Location of this script
dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Import functions from common benchmarking scripts
ln -sf $dir/../Bench-Swift $dir/bench
. $dir/bench/lib/bench.sh
. $dir/bench/lib/build.sh

# Define functions required to execute benchmarks
# (see: Bench-Swift/lib/bench.sh)

function setParams {
    local TESTNAME="$1"
    case "$TESTNAME" in
    TFB-DB-Kuery)
      IMPLEMENTATION="TechEmpowerKuery"
      URL="http://localhost:8080/db"
      DURATION=60
      ITERATIONS=3
      CLIENTS=128
      # TODO: pre-run script needed?
      # At the moment this depends on the database server being left in a clean state between executions.
      #PRE_RUN_SCRIPT="$dir/scripts/postgres_setup.sh"
      ;;
    TFB-DB-Mongo)
      IMPLEMENTATION="TechEmpowerMongoKitten"
      URL="http://localhost:8080/db"
      DURATION=60
      ITERATIONS=3
      CLIENTS=128
      ;;
    TFB-Updates-Kuery)
      IMPLEMENTATION="TechEmpowerKuery"
      URL="http://localhost:8080/updates?queries=1"
      DURATION=60
      ITERATIONS=3
      CLIENTS=128
      ;;
    TFB-Updates-Mongo)
      IMPLEMENTATION="TechEmpowerMongoKitten"
      URL="http://localhost:8080/updates?queries=1"
      DURATION=60
      ITERATIONS=3
      CLIENTS=128
      ;;
    TFB-Fortunes-Kuery)
      IMPLEMENTATION="TechEmpowerKuery"
      URL="http://localhost:8080/fortunes"
      DURATION=60
      ITERATIONS=3
      CLIENTS=128
      ;;
    TFB-Fortunes-Mongo)
      IMPLEMENTATION="TechEmpowerMongoKitten"
      URL="http://localhost:8080/fortunes"
      DURATION=60
      ITERATIONS=3
      CLIENTS=128
      ;;
    *)
      echo "Unknown test '$TESTNAME'"
      ;;
    esac
}

function setupBenchmark {
    local TESTNAME="$1"
    case "$TESTNAME" in
    *)
      # TODO: set up database?
      # At the moment this relies on the database being started in advance.
      ;;
    esac
}

function postBenchmark {
    local TESTNAME="$1"
    case "$TESTNAME" in
    *)
      # TODO: stop database?
      # At the moment the database will be left running after the run completes.
      ;;
    esac
}

###########################
### Benchmark Execution ###
###########################

# Keep track of return code from successive benchmark runs
rc=0

# Allow 'verify' flag to be passed in
BENCHMARK_MODE="$1"

# Ensure results are created in the project directory
cd $dir

# Create a derectory to hold the benchmark results, renaming an existing directory
# if one exists
preserveDir results

# Kuery tests
executeTest "TFB-DB-Kuery"
executeTest "TFB-Updates-Kuery"
executeTest "TFB-Fortunes-Kuery"

# Exit with resulting return code
exit $rc
