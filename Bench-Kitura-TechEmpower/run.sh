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

# Kuery tests
executeTest "TFB-DB-Kuery"
executeTest "TFB-Updates-Kuery"
executeTest "TFB-Fortunes-Kuery"

# Kuery ORM tests (requires Kitura 2.5 baseline)
#executeTest "TFB-DB-Kuery-ORM"
#executeTest "TFB-DB-Kuery-ORM-Codable"
#executeTest "TFB-Updates-Kuery-ORM"
#executeTest "TFB-Updates-Kuery-ORM-Codable"
#executeTest "TFB-Fortunes-Kuery-ORM"

# Exit with resulting return code
exit $rc
