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
verifyTest "HelloWorld"

# Codable tests (requires a Swift 4 baseline)
verifyTest "CodableRoutingGet"
verifyTest "CodableRoutingPost"

# Static file serving
verifyTest "StaticFile-trivial"

# SSL (with keepalive)
verifyTest "HelloSSL"

# Exit with resulting return code
exit $rc
