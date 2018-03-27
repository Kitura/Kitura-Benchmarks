#!/bin/bash
#
# Copyright IBM Corporation 2016, 2017
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
#
# Convenience script to generate a comparison of multiple applications.
# Each application will be run in succession, repeated a total of N times,
# and the results averaged.
#

# Determine location of this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

. ${SCRIPT_DIR}/lib/json_output.sh

if [ -z "$1" ]; then
  echo "Usage: ./compare.sh <impl1> ... <implN>"
  echo "Please specify fully qualified path to the application."
  echo "Optionally, set following environment variables:"
  echo "  DRIVER: workload driver (default: wrk)"
  echo "  ITERATIONS: number of repetitions of each implementation (default: 5)"
  echo "  URL: url to drive load against (default: http://127.0.0.1:8080/plaintext)"
  echo "  CLIENT: server to use to execute load driver (default: localhost)"
  echo "  CPUS: list of CPUs to affinitize to (default: 0,1,2,3)"
  echo "  CLIENTS: # of concurrent clients (default: 128)"
  echo "  DURATION: time (sec) to apply load (default: 30)"
  echo "  SLEEP: time (sec) to wait between tests (default: 5)"
  echo "  RUNNAME: name of directory to store results (default: compares/DDDDMMYY-HHmmss)"
  echo "  PRE_RUN_SCRIPT: a script to run before each test (eg. cleanup / setup actions)"
  echo "Output control:"
  echo "  VERBOSE_TRACE: set to enable printing of RSS, CPU and throughtput trace values"
  echo "  JSONFILE: fully-qualified filename to write results to in JSON format"
  echo "Per-implementation Options may follow the executable, comma-separated:"
  echo "  instances=N: Run multiple instances of an application"
  echo "  label=SomeName: Used to name the application in the output"
  echo "  pwd=/some/directory: Specify the PWD for the application"
  echo "Example: /path/to/myExecutable,label=MyProg1,pwd=/tmp"
  exit 1
fi

# Check driver script is present
if [ ! -e "$SCRIPT_DIR/drive.sh" ]; then
  echo "Error: cannot find drive.sh in expected location: $SCRIPT_DIR"
  exit 1
fi
if [ ! -x "$SCRIPT_DIR/drive.sh" ]; then
  echo "Error: drive.sh script is not executable"
  exit 1
fi

# Produce JSON output if requested
if [ ! -z "$JSONFILE" ]; then
  json_set_file $JSONFILE
  json_start
fi

#
# Benchmark configuration: parse environment / use defaults
#
if [ -z "$ITERATIONS" ]; then
  ITERATIONS=5
  echo "Using default ITERATIONS: $ITERATIONS"
else
  echo "Using ITERATIONS: $ITERATIONS"
fi
json_number "Iterations" $ITERATIONS

if [ -z "$CPUS" ]; then
  CPUS="0,1,2,3"
  echo "Using default CPUS: $CPUS"
else
  echo "Using CPUS: $CPUS"
fi
json_string "CPU Affinity" "$CPUS"

if [ -z "$URL" ]; then
  URL="http://127.0.0.1:8080/plaintext"
  echo "Using default URL: $URL"
else
  echo "Using URL: $URL"
fi
json_string "URL" "$URL"

if [ -z "$CLIENT" ]; then
  CLIENT="localhost"
  echo "Using default CLIENT: $CLIENT"
else
  echo "Using CLIENT: $CLIENT"
fi
json_string "Client" "$CLIENT"

if [ -z "$CLIENTS" ]; then
  CLIENTS=128
  echo "Using default CLIENTS: $CLIENTS"
else
  echo "Using CLIENTS: $CLIENTS"
fi
json_number "Clients" $CLIENTS

if [ -z "$DURATION" ]; then
  DURATION=30
  echo "Using default DURATION: $DURATION"
else
  echo "Using DURATION: $DURATION"
fi
json_number "Duration" $DURATION

if [ -z "$SLEEP" ]; then
  SLEEP=5
fi

if [ -z "$DRIVER" ]; then
  DRIVER="wrk"
  echo "Using default DRIVER: $DRIVER"
else
  echo "Using DRIVER: $DRIVER"
fi
json_string "Driver" "$DRIVER"

# If the benchmark uses a driver script, log the script location
if [ ! -z "$WRK_SCRIPT" ]; then
  echo "Using wrk script: $WRK_SCRIPT"
  json_string "Driver Script" "$WRK_SCRIPT"
fi
if [ ! -z "$JMETER_SCRIPT" ]; then
  echo "Using jmeter script: $JMETER_SCRIPT"
  json_string "Driver Script" "$JMETER_SCRIPT"
fi

# By convention, benchmarks that connect to a DB will use DB_HOST and DB_PORT env vars
# - if these are set, log them here
if [ ! -z "$DB_HOST" ]; then
  json_string "Database Host" "$DB_HOST"
fi
if [ ! -z "$DB_PORT" ]; then
  json_string "Database Port" "$DB_PORT"
fi

# Define a location to store the output (default: compares/<date>-<time>)
if [ -z "$RUNNAME" ]; then
  RUNNAME="compares/`date +'%Y%m%d-%H%M%S'`"
fi
json_string "Run Name" "$RUNNAME"
WORKDIR="$RUNNAME"
mkdir -p $WORKDIR
if [ $? -ne 0 ]; then
  echo "Error: Unable to create $WORKDIR"
  exit 1
else
  echo "Results will be stored in $WORKDIR"
fi

# Create a summary output file
if [ -z "$RECOMPARE" ]; then
  SUMMARY="$WORKDIR/results.txt"
else
  SUMMARY="$WORKDIR/results.txt.new"
fi
date > $SUMMARY
echo "ITERATIONS: $ITERATIONS, DURATION: $DURATION, CLIENT: '$CLIENT', CLIENTS: $CLIENTS, URL: '$URL', CPUS: '$CPUS'" >> $SUMMARY
echo "PWD: $PWD" >> $SUMMARY
json_string "Results Directory" "$PWD/$WORKDIR"

# Log system configuration
json_object_start "Configuration"
HOSTNAME=`hostname | sed -e's#\..*##'`
json_string "Hostname" "$HOSTNAME"
# If we are running under Jenkins, log build information 
if [ ! -z "$JENKINS_URL" ]; then
  json_string "BUILD_ID" "$BUILD_ID"                 # Set by Jenkins
  json_string "BUILD_URL" "$BUILD_URL"               # Set by Jenkins
  json_string "AUTOMATION_COMMIT" "$GIT_COMMIT"      # Set by Jenkins
  json_string "REPO" "$REPO"                         # Job parameter
  json_string "REPO_COMMIT" "$REPO_COMMIT"           # Set by automation
  json_string "BASE_VERSION" "$BASE_VERSION"         # Set by automation
  json_string "VERSION_ID" "$VERSION_ID"             # Set by automation
fi
json_object_end   # end configuration

# Check requested applications all exist, parse options
json_object_start "Implementations"
let IMPLC=0
for implstr in $*; do
  let IMPLC=$IMPLC+1
  # Default options
  instances="1"
  label="Implementation $IMPLC"
  short_label="$IMPLC"
  app_pwd=""
  impl=`echo $implstr | cut -d',' -f1`
  #instances=`echo $implstr | cut -d',' -f2 -s`
  # Parse comma-separated list of options attached to impl
  IFS=',' read -ra OPTS <<< "$implstr"
  for OPTSTRING in "${OPTS[@]}"; do
    OPTNAME="`echo $OPTSTRING | cut -d'=' -f1`"
    OPTVAL="`echo $OPTSTRING | cut -d'=' -f2 -s`"
    case "$OPTNAME" in
    pwd)
      app_pwd="$OPTVAL"
      ;;
    label)
      label="$OPTVAL"
      short_label="$OPTVAL"
      ;;
    instances)
      instances="$OPTVAL"
      ;;
    *)
      #echo "Ignoring $OPTNAME = $OPTVAL"
      ;;
    esac
  done
  # Attempt to convert a relative executable path to absolute path
  if [ -x "$PWD/$impl" ]; then
    impl="$PWD/$impl"  # Path is relative to PWD
  fi
  if [ -d "$app_pwd" -a -x "$app_pwd/$impl" ]; then
    impl="$app_pwd/$impl"  # Path is relative to APP_PWD provided
  fi
  if [ ! -x "$impl" -a -z "$RECOMPARE" ]; then
    echo "Error: $impl is not executable"
    json_end
    exit 1
  fi

  IMPLS[$IMPLC]=$impl                 # Executables
  INSTANCES[$IMPLC]=$instances        # No. of instances for each executable
  LABELS[$IMPLC]=$label               # Label for each executable
  SHORT_LABELS[$IMPLC]=$short_label   # Short label for each executable
  APP_PWDS[$IMPLC]=$app_pwd           # PWD for each executable

  echo "${LABELS[$IMPLC]}: ${IMPLS[$IMPLC]}" | tee -a $SUMMARY
  json_string "${LABELS[$IMPLC]}" "${IMPLS[$IMPLC]}"
done
json_object_end

# Create a directory to store run logs
mkdir -p $WORKDIR/runs

# Execute tests
for i in `seq 1 $ITERATIONS`; do
  json_object_start "Iteration $i"
  for j in `seq 1 $IMPLC`; do
    json_object_start "${LABELS[$j]}"
    echo "Iteration $i: ${LABELS[$j]}"
    run="${i}_${j}"
    let runNo=($i-1)*$IMPLC+$j
    out="$WORKDIR/compare_$run.out"
    json_string "Output File" "$out"
    # set RECOMPARE to skip running + just re-parse output files from an earlier run
    if [ -z "$RECOMPARE" ]; then
      sleep $SLEEP  # Allow system time to settle
      if [ ! -z "$PRE_RUN_SCRIPT" ]; then
        $PRE_RUN_SCRIPT   # Execute pre-run cleanup / setup actions if requested
      fi
      export APP_PWD="${APP_PWDS[$j]}"
      # Usage: ./drive.sh <run name> <cpu list> <clients list> <duration> <app> <url> <instances>
      $SCRIPT_DIR/drive.sh compare_$run $CPUS $CLIENTS $DURATION ${IMPLS[$j]} $URL ${INSTANCES[$j]} > $out 2>&1
    else
      echo ./drive.sh compare_$run $CPUS $CLIENTS $DURATION ${IMPLS[$j]} $URL ${INSTANCES[$j]}
    fi
    json_string "Command" "./drive.sh compare_$run $CPUS $CLIENTS $DURATION ${IMPLS[$j]} $URL ${INSTANCES[$j]}"

    # Archive the results from this run
    if [ -z "$RECOMPARE" ]; then
      mv runs/compare_$run $WORKDIR/runs/
    fi

  # Don't parse output if iteration did not terminate successfully
    if grep -q 'Detected successful termination' $out; then
        json_string "Good iteration" "true"
    else
        echo "Ignoring iteration as did not terminate successfully"
        json_string "Good iteration" "false"
        json_object_end  # end implementation
        continue
    fi
    # Note, removal of carriage return chars (^M) required when client output comes from 'ssh -t'
    THROUGHPUT[$runNo]=`grep 'Requests/sec' $out | awk '{gsub("\\r", ""); print $2}'`
    CPU[$runNo]=`grep 'Average CPU util' $out | awk '{print $4}'`
    MEM[$runNo]=`grep 'RSS (kb)' $out | sed -e's#.*max=\([0-9][0-9]*\).*#\1#' | awk '{total += $1} END {print total}'`
    LATAVG[$runNo]=`grep 'Latency  ' $out | awk '{print $2}' | awk '/[0-9\.]+s/ { print $1 * 1000 } /[0-9\.]+ms/ { print $1 / 1 } /[0-9\.]+us/ { print $1/1000 }'`
    case "$DRIVER" in
      wrk2) LAT99PCT[$runNo]=`grep ' 99.000% ' $out | awk '{print $2}' | awk '/[0-9\.]+s/ { print $1 * 1000 } /[0-9\.]+ms/ { print $1 / 1 } /[0-9\.]+us/ { print $1/1000 }'`
        ;;
      jmeter|sleep) LAT99PCT[$runNo]=0
        ;;
      *) LAT99PCT[$runNo]=`grep '     99% ' $out | awk '{print $2}' | awk '/[0-9\.]+s/ { print $1 * 1000 } /[0-9\.]+ms/ { print $1 / 1 } /[0-9\.]+us/ { print $1/1000 }'`
    esac
    LATMAX[$runNo]=`grep 'Latency  ' $out | awk '{print $4}' | awk '/[0-9\.]+s/ { print $1 * 1000 } /[0-9\.]+ms/ { print $1 / 1 } /[0-9\.]+us/ { print $1/1000 }'`
    echo "Throughput = ${THROUGHPUT[$runNo]} CPU = ${CPU[$runNo]} MEM = ${MEM[$runNo]}  Latency: avg = ${LATAVG[$runNo]}ms  99% = ${LAT99PCT[$runNo]}ms  max = ${LATMAX[$runNo]}ms"
    json_number "Avg Throughput" ${THROUGHPUT[$runNo]}
    json_number "Avg CPU" ${CPU[$runNo]}
    json_number "Peak RSS" ${MEM[$runNo]}
    json_number "Avg Latency" ${LATAVG[$runNo]}
    json_number "99% Latency" ${LAT99PCT[$runNo]}
    json_number "Max Latency" ${LATMAX[$runNo]}
    # Surface CPU time stats (sum of instances) in json file, only print if requested
    # Record number of server processes that were summarized
    NUM_PROCESSES=`grep 'Total server processes' $out | sed -e's#Total server processes: ##'`
    json_number "Process Count" $NUM_PROCESSES
    CPU_USR=0
    CPU_SYS=0
    CPU_TOT=0
    for instNum in `seq 1 ${NUM_PROCESSES}`; do
      TRACE=`grep "${instNum}: CPU time delta" $out`
      val=`echo $TRACE | sed -e's#.*user=\([0-9\.\-]*\) .*#\1#'`
      CPU_USR=$(bc <<< "$val + $CPU_USR" | sed -e's/^\./0./' -e's/^-\./-0./')
      val=`echo $TRACE | sed -e's#.*sys=\([0-9\.\-]*\) .*#\1#'`
      CPU_SYS=$(bc <<< "$val + $CPU_SYS" | sed -e's/^\./0./' -e's/^-\./-0./')
      val=`echo $TRACE | sed -e's#.*total=\([0-9\.\-]*\).*#\1#'`
      CPU_TOT=$(bc <<< "$val + $CPU_TOT" | sed -e's/^\./0./' -e's/^-\./-0./')
    done
    if [ ! -z "$VERBOSE_TRACE" ]; then
      echo "Total CPU time consumed by $NUM_PROCESSES server processes: user=$CPU_USR sys=$CPU_SYS total=$CPU_TOT"
    fi
    json_number "Process CPUTime User" $CPU_USR
    json_number "Process CPUTime Sys" $CPU_SYS
    json_number "Process CPUTime Total" $CPU_TOT
    trace="$WORKDIR/runs/compare_$run/trace.csv"
    json_object_start "CSV"
    #Surface throughput trace data into json file, only print if specified
    case "$DRIVER" in
      wrk2|sleep)
        TRACE="Unavailable"
        ;;
      jmeter)
        TRACE=`grep 'THROUGHPUT_TRACE:' $trace | sed -e's#THROUGHPUT_TRACE:##'`
        ;;
      *)
        TRACE=`cat $out | awk 'BEGIN {r=""} /requests in last/ {r=r $8 ","} END {print r}'`
    esac
    printf "\nTHROUGHPUT_TRACE: $TRACE" >> $trace
    json_string "Throughput CSV" "$TRACE"
    if [ ! -z "$VERBOSE_TRACE" ]; then
    echo "THROUGHPUT_TRACE: $TRACE"
    fi
    # Surface CPU trace data into json file, only print if requested
    USR_TRACE=`grep 'CPU_USER_TRACE' $trace | sed -e's#CPU_USER_TRACE:##'`
    json_string "CPU User CSV" "$USR_TRACE"
    SYS_TRACE=`grep 'CPU_SYS_TRACE' $trace | sed -e's#CPU_SYS_TRACE:##'`
    json_string "CPU Sys CSV" "$SYS_TRACE"
    TOTAL_TRACE=`grep 'CPU_TOTAL_TRACE' $trace | sed -e's#CPU_TOTAL_TRACE:##'`
    json_string "CPU Total CSV" "$TOTAL_TRACE"
    if [ ! -z "$VERBOSE_TRACE" ]; then
      echo "CPU_USER_TRACE: $USR_TRACE"
      echo "CPU_SYS_TRACE: $SYS_TRACE"
      echo "CPU_TOTAL_TRACE: $TOTAL_TRACE"
    fi
    # Surface RSS trace data into json file, only print if requested
    TRACE=`grep 'RSS_TRACE_TOTAL' $trace | sed -e's#.*RSS_TRACE_TOTAL: ##'`
    if [ ! -z "$VERBOSE_TRACE" ]; then
    echo "RSS_TRACE: $TRACE"
    fi
    json_string "TOTAL RSS CSV" "$TRACE"

    json_object_end  # end CSV
    json_object_end  # end implementation
  done
  json_object_end    # end iteration
done

# Summarize
json_object_start "Summary"
let ERRORS=0
echo '               | Throughput (req/s)      | CPU (%) | Mem (kb)     | Latency (ms)                   | good  ' >> $SUMMARY
echo 'Implementation | Average    | Max        | Average | Avg peak RSS | Average  | 99%      | Max      | iters ' >> $SUMMARY
echo '---------------|------------|------------|---------|--------------|----------|----------|----------|-------' >> $SUMMARY
for j in `seq 1 $IMPLC`; do
  TOT_TP=0
  TOT_CPU=0
  TOT_MEM=0
  MAX_TP=0
  TOT_LAT=0
  MAX99_LAT=0
  MAX_LAT=0
  let goodIterations=0
  for i in `seq 1 $ITERATIONS`; do
    run="${i}_${j}"
    let runNo=($i-1)*$IMPLC+$j
    # Check that the current run was parsed successfully
    if [[ -z "${THROUGHPUT[$runNo]}" || -z "${CPU[$runNo]}" || -z "${MEM[$runNo]}" || -z "${LATAVG[$runNo]}" || -z "${LATMAX[$runNo]}" ]]; then
        echo "Error - unable to parse data for implementation $j iteration $i"
        let ERRORS=$ERRORS+1
        continue
    fi
    # Continue processing - calculate summary statistics
    let goodIterations=$goodIterations+1
    TOT_TP=$(bc <<< "${THROUGHPUT[$runNo]} + $TOT_TP")
    TOT_CPU=$(bc <<< "${CPU[$runNo]} + $TOT_CPU")
    TOT_MEM=$(bc <<< "${MEM[$runNo]} + $TOT_MEM")
    TOT_LAT=$(bc <<< "${LATAVG[$runNo]} + $TOT_LAT")
    if [ $(bc <<< "${THROUGHPUT[$runNo]} > $MAX_TP") = "1" ]; then
      MAX_TP=${THROUGHPUT[$runNo]}
    fi
    if [ $(bc <<< "${LAT99PCT[$runNo]} > $MAX99_LAT") = "1" ]; then
      MAX99_LAT=${LAT99PCT[$runNo]}
    fi
    if [ $(bc <<< "${LATMAX[$runNo]} > $MAX_LAT") = "1" ]; then
      MAX_LAT=${LATMAX[$runNo]}
    fi
  done
  AVG_TP=$(bc <<< "scale=1; $TOT_TP / $goodIterations" | sed -e's/^\./0./' -e's/^-\./-0./')
  MAX_TP=$(bc <<< "scale=1; $MAX_TP / 1" | sed -e's/^\./0./' -e's/^-\./-0./')
  AVG_CPU=$(bc <<< "scale=1; $TOT_CPU / $goodIterations" | sed -e's/^\./0./' -e's/^-\./-0./')
  AVG_MEM=$(bc <<< "scale=0; $TOT_MEM / $goodIterations" | sed -e's/^\./0./' -e's/^-\./-0./')
  AVG_LAT=$(bc <<< "scale=1; $TOT_LAT / $goodIterations" | sed -e's/^\./0./' -e's/^-\./-0./')
  MAX99_LAT=$(bc <<< "scale=1; $MAX99_LAT / 1" | sed -e's/^\./0./' -e's/^-\./-0./')
  MAX_LAT=$(bc <<< "scale=1; $MAX_LAT / 1" | sed -e's/^\./0./' -e's/^-\./-0./')
  awk -v a="${SHORT_LABELS[$j]}" -v b="$AVG_TP" -v c="$MAX_TP" -v d="$AVG_CPU" -v e="$AVG_MEM" -v f="$AVG_LAT" -v g="$MAX99_LAT" -v h="$MAX_LAT" -v i="$goodIterations" 'BEGIN {printf "%14s | %10s | %10s | %7s | %12s | %8s | %8s | %8s | %5s \n", a, b, c, d, e, f, g, h, i}' >> $SUMMARY
  json_object_start "${LABELS[$j]}"
  json_number "Avg Throughput" $AVG_TP
  json_number "Max Throughput" $MAX_TP
  json_number "Avg CPU" $AVG_CPU
  json_number "Avg Peak RSS" $AVG_MEM
  json_number "Avg Latency" $AVG_LAT
  json_number "99% Latency" $MAX99_LAT
  json_number "Max Latency" $MAX_LAT
  json_number "Good iterations" $goodIterations
  json_object_end  # End implementation
done
json_object_end    # End summary

json_end

echo "" >> $SUMMARY
if [[ $ERRORS > 0 ]]; then
  echo "*** Errors encountered during processing: $ERRORS" >> $SUMMARY
else
  echo "*** Completed successfully"
fi

# Output summary table
cat $SUMMARY

# Exit with non-zero RC if there were processing errors
exit $ERRORS
