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
    HelloWorld)
      ;;
    HelloLogging)
      URL="http://localhost:8080/log"
      ;;
    HelloSSL)
      URL="https://localhost:8443/plaintext"
      PRE_RUN_SCRIPT="$dir/scripts/ssl_setup.sh"
      ;;
    HelloSSLHandshake)
      IMPLEMENTATION="HelloSSL"
      URL="https://localhost:8443/plaintext"
      PRE_RUN_SCRIPT="$dir/scripts/ssl_setup.sh"
      DRIVER="wrk-nokeepalive"
      ;;
    JSONEncoderDouble)
      ITERATIONS=2
      IMPLEMENTATION="Codable"
      URL="http://localhost:8080/json/Double"
      ;;
    JSONDecoderDouble)
      ITERATIONS=2
      IMPLEMENTATION="Codable"
      URL="http://localhost:8080/post/Double"
      WRK_SCRIPT="$dir/payloads/dblPayload.lua"
      ;;
    JSONEncoderSmallStruct)
      ITERATIONS=2
      IMPLEMENTATION="CodableSmall"
      URL="http://localhost:8080/json/Small"
      ;;
    JSONDecoderSmallStruct)
      ITERATIONS=2
      IMPLEMENTATION="CodableSmall"
      URL="http://localhost:8080/post/smallJson"
      WRK_SCRIPT="$dir/payloads/jsonRawSmall.lua"
      ;;
    JSONDouble)
      IMPLEMENTATION="JSON"
      URL="http://localhost:8080/json/Double"
      ;;
    SwiftyJSONDouble)
      IMPLEMENTATION="JSONSwifty"
      URL="http://localhost:8080/json/Double"
      ;;
    JSONParsing)
      IMPLEMENTATION="JSON"
      URL="http://localhost:8080/post/Double"
      WRK_SCRIPT="$dir/payloads/jsonRawPayload.lua"
      ;;
    SwiftyJSONParsing)
      IMPLEMENTATION="JSON"
      URL="http://localhost:8080/post/Double"
      WRK_SCRIPT="$dir/payloads/jsonPayload.lua"
      ;;
    StaticFile-trivial)
      IMPLEMENTATION="StaticFile"
      URL="http://localhost:8080/file/hello.txt"
      DURATION=60
      ITERATIONS=2
      ;;
    StaticFile-16M)
      IMPLEMENTATION="StaticFile"
      URL="http://localhost:8080/file/test16M"
      DURATION=60
      ITERATIONS=2
      ;;
    BrowserSimulation)
      IMPLEMENTATION="HelloMiddleware"
      URL="http://localhost:8080/"
      CLIENTS=10
      DURATION=300
      ITERATIONS=1
      DRIVER="jmeter"
      JMETER_SCRIPT="$dir/jmeter/Browser.jmx"
      ;;
    ThinkTimeSync)
      IMPLEMENTATION="ThinkTime"
      URL="http://localhost:8080/think/sync"
      CLIENTS=1000
      # Simulate a 50ms synchronous 'think time' (eg. blocking IO)
      export THINKTIME=50
      ;;
    ThinkTimeAsync)
      IMPLEMENTATION="ThinkTime"
      URL="http://localhost:8080/think/async"
      CLIENTS=1000
      # Simulate a 50ms asynchronous 'think time' (eg. async IO)
      export THINKTIME=50
      ;;
    CodableRoutingGet)
      IMPLEMENTATION="CodableRouting"
      URL="http://localhost:8080/getHelloId/123"
      ;;
    CodableRoutingPost)
      IMPLEMENTATION="CodableRouting"
      URL="http://localhost:8080/postHello"
      WRK_SCRIPT="$dir/payloads/simpleStructPayload.lua"
      ;;
    CodableRoutingGetAccept)
      IMPLEMENTATION="CodableRouting"
      URL="http://localhost:8080/getHelloId/123"
      # Add an Accept header to trigger Media Type processing
      WRK_SCRIPT="$dir/payloads/get_accept.lua"
      ;;
    CodableRoutingPostAccept)
      IMPLEMENTATION="CodableRouting"
      URL="http://localhost:8080/postHello"
      # Add an Accept header to trigger Media Type processing
      WRK_SCRIPT="$dir/payloads/simpleStructPayload_accept.lua"
      ;;
    *)
      echo "Unknown test '$TESTNAME'"
      ;;
    esac
}

function setupBenchmark {
    local TESTNAME="$1"
    case "$TESTNAME" in
    StaticFile-16M)
      # Generate payload
      dd if=/dev/zero of=$dir/public/test16M bs=1024 count=16384
      ;;
    *)
      ;;
    esac
}

function postBenchmark {
    local TESTNAME="$1"
    case "$TESTNAME" in
    HelloLogging)
      # Truncate application log for HelloLogging, as we will have generated a large number
      # of repeated (uninteresting) log statements
      for FILE in `find $RUNNAME/runs/ -name 'app1.log'`; do
        head $FILE > tmp && echo "..." >> tmp && tail $FILE >> tmp && mv tmp $FILE
      done
      ;;
    *)
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

# Create a derectory to hold the benchmark results, renaming an existing directory
# if one exists
preserveDir results

# Simple tests
executeTest "HelloWorld"
executeTest "HelloLogging"

# JSON serialization and parsing
executeTest "JSONDouble"
executeTest "JSONParsing"

# Codable tests (requires a Swift 4 baseline)
#executeTest "JSONEncoderDouble"
#executeTest "JSONDecoderDouble"
#executeTest "JSONEncoderSmallStruct"
#executeTest "JSONDecoderSmallStruct"
#executeTest "CodableRoutingGet"
#executeTest "CodableRoutingPost"

# Static file serving
executeTest "StaticFile-trivial"
executeTest "StaticFile-16M"

# Browser simulation (static file serving, Session + Compression middleware)
# Note that JMeter will use 4 additional connections per client to retrieve the embedded page resources.
executeTest "BrowserSimulation"

# Simple tests, with SSL enabled (with and without keepalive)
executeTest "HelloSSL"
executeTest "HelloSSLHandshake"

# Think time tests, simulating blocking or non-blocking IO waits in the route handler
executeTest "ThinkTimeSync"
executeTest "ThinkTimeAsync"

# Exit with resulting return code
exit $rc
