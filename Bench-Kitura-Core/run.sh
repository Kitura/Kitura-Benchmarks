#!/bin/bash
#
# Example benchmark suite script. This shows how to use the functions in bench to define
# and execute a simple test suite.
#

# Location of this script
dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Import functions from common benchmarking scripts
ln -sfn $dir/../Bench-Swift $dir/bench
. $dir/bench/lib/bench.sh
. $dir/bench/lib/build.sh

# Import functions required to execute benchmarks
# (see: Bench-Swift/lib/bench.sh)
. $dir/benchmarks.sh

###########################
### Benchmark Execution ###
###########################

# Keep track of return code from successive benchmark runs
rc=0

# Ensure results are created in the project directory
cd $dir

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
executeTest "CodableRoutingGet"
executeTest "CodableRoutingPost"

# Static file serving
executeTest "StaticFile-trivial"
executeTest "StaticFile-16M"

# Browser simulation (static file serving, Session + Compression middleware)
# Note that JMeter will use 4 additional connections per client to retrieve the embedded page resources.
executeTest "BrowserSimulation"

# Simple tests, with SSL enabled (with and without keepalive)
executeTest "HelloSSL"
# Disable SSL handshake benchmark while crash investigated
#executeTest "HelloSSLHandshake"

# Think time tests, simulating blocking or non-blocking IO waits in the route handler
executeTest "ThinkTimeSync"
executeTest "ThinkTimeAsync"

# Exit with resulting return code
exit $rc
