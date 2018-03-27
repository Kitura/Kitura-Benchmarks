#!/bin/bash

# Executes a test (named by first argument)
# eg: executeTest HelloWorld
#
# '$dir' will be set to the project directory.
# 
# Adds the return code of the test run to variable: $rc
#
function executeTest {
    local TESTNAME="$1"
    JSONFILE="$dir/results/$TESTNAME.json"   # Results written to a JSON file
    RUNNAME="results/$TESTNAME"              # Archive test logs within results dir

    # Defaults for tests
    IMPLEMENTATION="$TESTNAME"               # Executable filename
    URL="http://localhost:8080/plaintext"    # URL is used to drive load / detect process start
    CLIENTS=128                              # Number of concurrent connections
    DURATION=30                              # Duration of each load period (sec)
    ITERATIONS=3                             # Number of times to test each implementation
    INTERVAL=5                               # Frequency of trace data (sec)
    DRIVER="wrk"                             # Workload driver
    WRK_SCRIPT=""                            # Optional script for wrk
    JMETER_SCRIPT=""                         # Script (if using JMeter)
    WORK_RATE=""                             # Workload injection rate (if using wrk2)
    VERBOSE_TRACE=1                          # Print traces to console
    PRE_RUN_SCRIPT=""                        # Optional setup/cleanup actions before each measurement
    # Support for distributed tests
    CLIENT="localhost"                       # Host that will run workload driver
   
    # Override with benchmark-specific values 
    setParams $TESTNAME
    
    # Set up environment for driver scripts
    export URL CLIENTS DURATION ITERATIONS DRIVER INTERVAL VERBOSE_TRACE JSONFILE WRK_SCRIPT JMETER_SCRIPT WORK_RATE RUNNAME PRE_RUN_SCRIPT CLIENT

    echo "### Benchmark: $TESTNAME"
    setupBenchmark $TESTNAME
    # Cannot use pipe here, as bash executes the LHS in a subshell (losing variables)
    runBenchmark $TESTNAME > $dir/results/$TESTNAME.txt
    cat $dir/results/$TESTNAME.txt
    postBenchmark $TESTNAME
}

#
# Set any benchmark-specific parameters, overriding the defaults.
#
# Each benchmark suite should implement (override) this function to define the properties
# appropriate to the benchmarks in that suite.
#
# See the executeTest function (above) for values that can be overridden here.
#
function setParams {
    local TESTNAME="$1"

    # Override defaults
    case "$TESTNAME" in
    Example1)
      IMPLEMENTATION="StaticFiles"
      URL="http://localhost:8080/file/hello.txt"
      DURATION=60
      ITERATIONS=2
      ;;
    Example2)
      IMPLEMENTATION="BrowserBench"
      URL="http://localhost:8080/"
      CLIENTS=10
      DURATION=300
      ITERATIONS=1
      DRIVER="jmeter"
      JMETER_SCRIPT="$dir/jmeter/Browser.jmx"
      ;;
    *)
      echo "Make sure you have implemented the required functions for your benchmark suite,"
      echo "setParams, runBenchmark and (optionally) setupBenchmark and postBenchmark."
      echo "See lib/bench.sh for examples."
      return
      ;;
    esac
}

#
# Perform any setup / configuration steps required for a benchmark.
# This function is called once before benchmarking begins. For benchamrks that require
# setup per-iteration, use the PRE_RUN_SCRIPT parameter in setParams to point to a script.
#
# Each benchmark suite may implement (override) this function if any benchmark requires
# a setup step.
#
function setupBenchmark {
    local TESTNAME="$1"

    case "$TESTNAME" in
    Example1)
      # Generate payload
      dd if=/dev/zero of=$dir/public/test16M bs=1024 count=16384
      ;;
    *)
      ;;
    esac
}

#
# Execute a benchmark. This may be a simple 2-way compare, or a more complicated
# comparison of different implementations.
#
# Each benchmark suite may implement (override) this function, otherwise, the default
# behaviour is to compare two implementations: one named baselineBuild/release/<implementation>
# and one named newBuild/release/<implementation>.
#
# Adds return code of benchmark process to: $rc
#
function runBenchmark {
    local TESTNAME="$1"

    case "$TESTNAME" in
    Example1)
      # Execute a 3-way compare of specified implementations
      $dir/bench/compare.sh $dir/${IMPL1} $dir/${IMPL2} $dir/${IMPL3}
      ;;
    *)
      # Execute a 2-way compare of baseline and new build for the same implementation
      $dir/bench/compare.sh $dir/baselineBuild/release/${IMPLEMENTATION},label=Baseline,pwd=$dir $dir/newBuild/release/${IMPLEMENTATION},label=New,pwd=$dir
      ;;
    esac

    # Update global return code with the result of this run
    rc=$(($rc+$?))
}

#
# Perform any post-benchmark processing or cleanup activities.
# This function is called once after all benchmarking is complete.
#
# Each benchmark suite may implement (override) this function, if any benchmark requires
# post-benchmark steps to be taken.
#
function postBenchmark {
    local TESTNAME="$1"

    case "$TESTNAME" in
    Example1)
      # Truncate uninteresting application logs to save on disk space
      for FILE in `find $RUNNAME/runs/ -name 'app1.log'`; do
        head $FILE > tmp && echo "..." >> tmp && tail $FILE >> tmp && mv tmp $FILE
      done
      ;;
    *)
      ;;
    esac
}
