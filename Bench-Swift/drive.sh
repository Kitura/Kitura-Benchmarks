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
# author: David Jones (djones6)
#
# Driver script to measure web server throughput and response time using Wrk (or similar).
# To use this, you need:
# 1) A suitable load driver installed, and present on your path
# 2) A Kitura (or similar) application built and ready to run
# Linux only:
# 3) The 'mpstat' utility installed (if you want per-core CPU utilisation)
# 4) The 'numactl' utility installed (to control process affinity)
#
# Customize this script for your machine. I'm running on a 2-socket machine,
# with the server running on the first socket and wrk running on the second.
# Change the args to numactl below so they make sense for your system.
#
### Load drivers:
#
# This script supports:
# - wrk (https://github.com/wg/wrk) - highly efficient, variable-rate load generator
# - wrk2 (https://github.com/giltene/wrk2) - fixed-rate wrk variant with accurate latency stats
# - jmeter (http://jmeter.apache.org/) - highly customizable Java-based load generator
#
# 'wrk' and 'wrk2' drive a specific URL. 'jmeter' instead works from a script (.jmx).
# 'wrk' and 'jmeter' drive variable amounts of load, as fast as the server can respond to it, and
# are useful for measuring maximum attainable throughput.
# 'wrk2' drives fixed levels of load, and is useful for measuring latency and CPU consumption
# under different levels of demand.
# 
### Profilers:  (Linux only)
#
# For convenience, a number of profilers can be run in parallel via this script:
# valgrind (massif tool) - useful in identifying memory leaks
# oprofile / perf - system profilers, useful in identifying where CPU is consumed
#
# Profiler prerequisites:
# sudo apt-get install linux-tools-`uname -r` linux-image-`uname -r`-dbgsym
#
RUN_NAME=$1
CPULIST=$2
SAMPLES=$3
DURATION=$4
APP_CMD=$5
URL=$6
INSTANCES=$7

# Select workload driver (client simulator) with DRIVER env variable
# (default: wrk)
DRIVER_CHOICES="wrk wrk-pipeline wrk-nokeepalive wrk2 jmeter sleep"
#DRIVER="wrk"

# Select profiler with PROFILER env variable
# (default: none)
PROFILER_CHOICES="valgrind oprofile oprofile-sys perf perf-cg perf-idle"
#PROFILER=""

# Flags to enable certain behaviours from this script
SUDO_PERMISSIONS=yes       # Attempt temporary system config actions that require sudo?
OSX_DISABLE_FIREWALL=yes   # Disable OSX firewall during test? (requires sudo)

SUPPORTED_OSES="Linux Darwin"

# Customize this section appropriately for your hardware
case `uname` in
Linux)
  DRIVER_AFFINITY="numactl --cpunodebind=1 --membind=1"
  APP_AFFINITY="numactl --physcpubind=$CPULIST --membind=0"
  WORK_THREADS=16
  ;;
Darwin)
  # Don't know if this is possible on OS X...
  DRIVER_AFFINITY=""
  APP_AFFINITY=""
  WORK_THREADS=4
  ;;
esac

# Check this OS is supported
if [[ ! $SUPPORTED_OSES =~ `uname` ]]; then
  echo "Unsupported operating system: `uname`"
  exit 1
fi

# Consume environment settings
if [ -z "$PROFILER" ]; then
  PROFILER=""
else
  if [[ ! $PROFILER_CHOICES =~ $PROFILER ]]; then
    echo "Unrecognized profiler option '$PROFILER'"
    echo "Supported choices: $PROFILER_CHOICES"
    exit 1
  fi
fi
if [ -z "$DRIVER" ]; then
  DRIVER="wrk"
  echo "Using default driver: $DRIVER"
else
  if [[ ! $DRIVER_CHOICES =~ $DRIVER ]]; then
    echo "Unrecognized driver option '$DRIVER'"
    echo "Supported choices: $DRIVER_CHOICES"
    exit 1
  fi
fi

# Determine location of this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Consume cmdline args (simplest possible implementation for now)
if [ -z "$1" -o "$1" == "--help" ]; then
  echo "Usage: $0 <run name> <cpu list> <clients list> <duration> <app> <url> <instances>"
  echo " - eg: $0 my_run_4way 0,1,2,3 1,5,10,100,200 30 ~/kitura http://127.0.0.1:8080/hello 1"
  echo "  cpu list = comma-separated list of CPUs to affinitize to"
  echo "  client list = comma-separated list of # clients to drive load"
  echo "  duration = length of each load period (seconds)"
  echo "  app = app command to execute"
  echo "  url = URL to drive load against (also used to detect when server has started)"
  echo "  instances = number of copies of <app> to start"
  echo "Optionally, set:"
  echo "  DRIVER to one of: $DRIVER_CHOICES"
  echo "  PROFILER to one of: $PROFILER_CHOICES"
  echo "  CLIENT to a hostname used to execute the load driver (must have $DRIVER installed)"
  echo "   - default is to execute on localhost"
  echo "  APP_PWD to set the PWD when launching the app (default: results directory)"
  echo "For wrk:"
  echo "  WRK_SCRIPT - a .lua file to use (append any script args with -- <args>)"
  echo "For JMeter:"
  echo "  JMETER_SCRIPT - the .jmx file to use (required)"
  echo "  USER_PROPS - the user.properties file (default: jmeter/user.properties.sample)"
  echo "  SYSTEM_PROPS - the system.properties file (default: jmeter/system.properties.sample)"
  echo "For wrk2:"
  echo "  WORK_RATE = comma-separated list of constant load levels (rps) to drive"
  echo "Output format options:"
  echo "  INTERVAL - frequency of RSS measurements (seconds), and throughput (if supported)"
  echo ""
  exit 1
fi
# CPU list
if [ -z "$2" ]; then
  CPULIST="0,1,2,3"
  echo "CPU list not specified; using default of '$CPULIST'"
fi
# Clients list
if [ -z "$3" ]; then
  SAMPLES="128"
  echo "Clients list not specified; using default of '$SAMPLES'"
fi
# Duration
if [ -z "$4" ]; then
  DURATION=10
  echo "Duration not specified; using default of '$DURATION'"
fi
# App
if [ -z "$5" ]; then
  APP_CMD="$SCRIPT_DIR/kitura"
  echo "App not specified, using default of '$APP_CMD'"
fi
# URL
if [ -z "$6" ]; then
  URL="http://127.0.0.1:8080/plaintext"
  echo "URL not specified, using default of '$URL'"
fi
# Instances
if [ -z "$7" ]; then
  INSTANCES=1
  echo "INSTANCES not specified, using default of '$INSTANCES'"
fi

# Remote server for driving load (default: start locally)
if [ -z "$CLIENT" ]; then
  CLIENT="localhost"
fi

# Interval (sec) for periodic measurements
if [ -z "$INTERVAL" ]; then
  INTERVAL=5
fi
if [ $DURATION -lt $INTERVAL ]; then
  # Ensure at least one sample generated for short runs
  INTERVAL=$DURATION
fi

#
# Consume driver-specific options
#
case $DRIVER in
wrk2)
  # Work rate (only used for wrk2 fixed-load generator)
  if [ -z "$WORK_RATE" ]; then
    WORK_RATE="1000,5000,10000"
    echo "WORK_RATE not specified, using default of '$WORK_RATE'"
  fi
  ;;
jmeter)
  if [ -z "$JMETER_SCRIPT" ]; then
    echo "Error: must specify jmeter driver script (.jmx) with JMETER_SCRIPT"
    exit 1
  fi
  if [ -z "$USER_PROPS" ]; then
    USER_PROPS=${SCRIPT_DIR}/jmeter/user.properties.sample
  fi
  if [ -z "$SYSTEM_PROPS" ]; then
    SYSTEM_PROPS=${SCRIPT_DIR}/jmeter/system.properties.sample
  fi
  if [ $INTERVAL -lt 6 ]; then
    echo "Warning: Increasing measurement interval to minimum supported by JMeter (6 seconds)"
    INTERVAL=6
  fi
  # Skip the first few samples from JMeter. The first sample is generally much shorter than expected,
  # and the first 10 seconds or so will be tainted by the driver itself warming up.
  JMETER_SKIP_SAMPLES=3
  let MINIMUM_USEFUL_DURATION=($JMETER_SKIP_SAMPLES+1)*$INTERVAL
  if [ $MINIMUM_USEFUL_DURATION -gt $DURATION ]; then
    echo "Warning: Increasing duration to minimum useful duration ($MINIMUM_USEFUL_DURATION) as we will skip $JMETER_SKIP_SAMPLES jmeter samples"
    DURATION=$MINIMUM_USEFUL_DURATION
  fi
  ;;
esac

#
# Gets fractional CPU time from the /proc filesystem (Linux only)
# Thanks to https://straypixels.net/getting-the-cpu-time-of-a-process-in-bash-is-difficult/
#
function getcputime {
    local pid=$1
    local clk_tck=$(getconf CLK_TCK)
    local cputime=0
    local stats=$(cat "/proc/$pid/stat")
    local statarr=($stats)
    local utime=${statarr[13]}
    local stime=${statarr[14]}
    local numthreads=${statarr[20]}
    local usec=$(bc <<< "scale=3; $utime / $clk_tck")
    local ssec=$(bc <<< "scale=3; $stime / $clk_tck")
    local totalsec=$(bc <<< "scale=3; $usec + $ssec")
    #echo "clk_tck usec ssec totalsec numthreads"
    echo "$clk_tck $usec $ssec $totalsec $numthreads"
}

#
# Starts CPU monitoring.
# Expects $APP_PIDS to be set.
# Sets $MPSTAT_PID or $TOP_PID.
#
function monitor_cpu {
  SUFFIX=$1
  CPULIST=$2
  DURATION=$3
 
  case `uname` in
  Linux)
    # Start mpstat to monitor per-CPU utilization
    #
    env LC_ALL='en_GB.UTF-8' mpstat -P $CPULIST $INTERVAL > mpstat.$SUFFIX &
    MPSTAT_PID=$!
    # Capture CPU cycles consumed by server before we apply load
    # (this avoids counting any CPU costs incurred during startup)
    #
    for APP_PID in $APP_PIDS $CHILD_PIDS; do
      PRE_CPU=(`getcputime $APP_PID`)
      PRE_CPUS="$PRE_CPU,$PRE_CPUS"
    done
    $SCRIPT_DIR/showpidv $APP_PID > thread_stats.$SUFFIX &
    THREADS_PID=$!
    ;;
  Darwin)
    # Monitor overall CPU utilization using top
    # Sleep briefly to make the first sample more representative.
    #
    (sleep 1 ; exec top -F -R -o cpu -n 5 -ncols 10 -s $INTERVAL > top.$SUFFIX) &
    TOP_PID=$!
    # Capture CPU cycles consumed by server before we apply load
    for APP_PID in $APP_PIDS $CHILD_PIDS; do
      # Output 2 values: user, total
      PRE_CPU=`ps -p $APP_PID -o utime=,cputime= | awk '{print $1 " " $2}'`
      PRE_CPUS="$PRE_CPU,$PRE_CPUS"
    done
    ;;
  esac
}

#
# Ends CPU monitoring and generates summary text.
# Expects $APP_PIDS and either $MPSTAT_PID or $TOP_PID to be set.
#
function end_monitor_cpu {
  SUFFIX=$1
  CPULIST=$2

  case `uname` in
  Linux)
    # Diff CPU cycles after load applied
    let i=0
    echo "CPU consumed per instance:" | tee cpu.$SUFFIX
    for APP_PID in $APP_PIDS $CHILD_PIDS; do
      let i=$i+1
      PRE_CPU=`echo $PRE_CPUS | cut -d',' -f${i}`
      POST_CPU=(`getcputime $APP_PID`)
      usec=$(bc <<< "${POST_CPU[1]} - ${PRE_CPU[1]}")
      ssec=$(bc <<< "${POST_CPU[2]} - ${PRE_CPU[2]}")
      totalsec=$(bc <<< "${POST_CPU[3]} - ${PRE_CPU[3]}")
      echo "$i: CPU time delta: user=$usec sys=$ssec total=$totalsec" | tee -a cpu.$SUFFIX
    done
    # Stop mpstat
    kill $MPSTAT_PID
    wait $MPSTAT_PID 2>/dev/null
    # Post-process output
    #
    # mpstat produces output in the following format:
    # 14:06:05     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
    # 14:06:05     <n>    0.04    0.00    0.01    0.00    0.00    0.00    0.00    0.00    0.00   99.95
    #
    # Sum 100 - %idle (12) for each sample
    # Then divide by the number of samples collection ran for
    echo "CPU utilization by processor number:" | tee -a cpu.$SUFFIX
    let NUM_CPUS=0
    TOTAL_CPU=0
    for CPU in `echo $CPULIST | tr ',' ' '`; do
      NUM_CYCLES=`cat mpstat.$SUFFIX | grep -e"..:..:.. \+${CPU}" | wc -l`
      AVG_CPU=`cat mpstat.$SUFFIX | grep -e"..:..:.. \+${CPU}" | awk -v SAMPLES=${NUM_CYCLES} '{TOTAL = TOTAL + (100 - $12) } END {printf "%.1f",TOTAL/SAMPLES}'`
      TOTAL_CPU=`echo $AVG_CPU | awk -v RTOT=$TOTAL_CPU '{print RTOT+$1}'`
      echo "CPU $CPU: $AVG_CPU %" | tee -a cpu.$SUFFIX
      let NUM_CPUS=$NUM_CPUS+1
    done
    echo "Average CPU util: `echo $LIST_CPUS | awk -v n=$NUM_CPUS -v t=$TOTAL_CPU '{printf "%.1f",t/n}'` %"
    CPU_USER_CSV=`grep -e"..:..:.." mpstat.$SUFFIX  | awk -v NUM_CPUS=$NUM_CPUS 'NR > 1 {subtotal_usr+=$3}  NR > 1 && NR % NUM_CPUS == 1 { printf "%.1f%", subtotal_usr/NUM_CPUS; subtotal_usr=0}' | sed -e's/%/,/g' -e's/,$//'`
    CPU_SYS_CSV=`grep -e"..:..:.." mpstat.$SUFFIX  | awk -v NUM_CPUS=$NUM_CPUS 'NR > 1 {subtotal_sys+=$5}  NR > 1 && NR % NUM_CPUS == 1 { printf "%.1f%", subtotal_sys/NUM_CPUS; subtotal_sys=0}' | sed -e's/%/,/g' -e's/,$//'`
    CPU_TOTAL_CSV=`grep -e"..:..:.." mpstat.$SUFFIX  | awk -v NUM_CPUS=$NUM_CPUS 'NR > 1 {subtotal_t+=(100-$12)}  NR > 1 && NR % NUM_CPUS == 1 { printf "%.1f%", subtotal_t/NUM_CPUS; subtotal_t=0}' | sed -e's/%/,/g' -e's/,$//'`
    echo "CPU_USER_TRACE: $CPU_USER_CSV" | tee -a trace.csv
    echo "CPU_SYS_TRACE: $CPU_SYS_CSV" | tee -a trace.csv
    echo "CPU_TOTAL_TRACE: $CPU_TOTAL_CSV" | tee -a trace.csv
    kill $THREADS_PID
    wait $THREADS_PID 2>/dev/null
    ;;
  Darwin)
    # Diff CPU cycles after load applied
    let i=0
    echo "CPU consumed per instance:" | tee cpu.$SUFFIX
    for APP_PID in $APP_PIDS $CHILD_PIDS; do
      let i=$i+1
      PRE_CPU=`echo $PRE_CPUS | cut -d',' -f${i}`
      POST_CPU=`ps -p $APP_PID -o utime=,cputime= | awk '{print $1 " " $2}'`
      # Convert H:M:S.ss format to S.ss (regex from http://stackoverflow.com/questions/2181712)
      PRE_U_SEC=`echo $PRE_CPU | cut -d' ' -f1 | sed -E 's/(.*):(.+):(.+)/\1*3600+\2*60+\3/;s/(.+):(.+)/\1*60+\2/' | bc`
      PRE_T_SEC=`echo $PRE_CPU | cut -d' ' -f2 | sed -E 's/(.*):(.+):(.+)/\1*3600+\2*60+\3/;s/(.+):(.+)/\1*60+\2/' | bc`
      POST_U_SEC=`echo $POST_CPU | cut -d' ' -f1 | sed -E 's/(.*):(.+):(.+)/\1*3600+\2*60+\3/;s/(.+):(.+)/\1*60+\2/' | bc`
      POST_T_SEC=`echo $POST_CPU | cut -d' ' -f2 | sed -E 's/(.*):(.+):(.+)/\1*3600+\2*60+\3/;s/(.+):(.+)/\1*60+\2/' | bc`
      usec=$(bc <<< "${POST_U_SEC} - ${PRE_U_SEC}")
      totalsec=$(bc <<< "${POST_T_SEC} - ${PRE_T_SEC}")
      ssec=$(bc <<< "${totalsec} - ${usec}")
      echo "$i: CPU time delta: user=$usec sys=$ssec total=$totalsec" | tee -a cpu.$SUFFIX
    done
    # Collect post-load process CPU usage
    # Stop top
    kill $TOP_PID
    wait $TOP_PID 2>/dev/null
    # Post-process output of: top -F -R -o cpu -n 5 -ncols 10 -s 5
    # This invocation of top produces output in the following format:
    #
    # Processes: 259 total, 5 running, 7 stuck, 247 sleeping, 1068 threads
    # 2016/07/15 11:09:33
    # Load Avg: 4.96, 4.41, 4.01
    # CPU usage: 43.27% user, 49.57% sys, 7.14% idle
    # MemRegions: 33096 total, 1179M resident, 0B private, 222M shared.
    # PhysMem: 4298M used (1844M wired), 12G unused.
    # VM: 706G vsize, 0B framework vsize, 9117231(0) swapins, 9665493(0) swapouts.
    # Networks: packets: 276435264/34G in, 271810311/23G out.
    # Disks: 2876920/86G read, 2889399/107G written.
    # 
    # PID    COMMAND     %CPU  TIME     #TH   #WQ   #PORTS MEM    PURG CMPRS
    # 86137  TechEmpower 578.6 02:09.58 27/8  25/10 46     515M+  0B   0B
    NUM_SAMPLES=`grep 'CPU usage:' top.$SUFFIX | wc -l | sed -e's# *##g'`
    # Grab list of values for each field
    CPU_USER_SAMPLES=`grep 'CPU usage:' top.$SUFFIX | awk '{printf "%s ",$3}'`
    CPU_SYS_SAMPLES=`grep 'CPU usage:' top.$SUFFIX | awk '{printf "%s ",$5}'`
    CPU_IDLE_SAMPLES=`grep 'CPU usage:' top.$SUFFIX | awk '{printf "%s ",$7}'`
    # Sum each list of samples, then divide by no. of samples
    CPU_USER_AVG=`echo $CPU_USER_SAMPLES | sed -e's/% /+/g' -e's/%//' | bc | awk -v SAMPLES=$NUM_SAMPLES '{printf "%.1f",$1/SAMPLES}'`
    CPU_SYS_AVG=`echo $CPU_SYS_SAMPLES | sed -e's/% /+/g' -e's/%//' | bc | awk -v SAMPLES=$NUM_SAMPLES '{printf "%.1f",$1/SAMPLES}'`
    CPU_IDLE_AVG=`echo $CPU_IDLE_SAMPLES | sed -e's/% /+/g' -e's/%//' | bc | awk -v SAMPLES=$NUM_SAMPLES '{printf "%.1f",$1/SAMPLES}'`
    CPU_TOTAL_AVG=`echo "100 - $CPU_IDLE_AVG" | bc`
    echo "Average CPU util: $CPU_TOTAL_AVG % (${CPU_USER_AVG} % user, ${CPU_SYS_AVG} % sys, ${CPU_IDLE_AVG} % idle)"
    # Display periodic CPU utilization (csv format) in trace.csv
    CPU_USER_CSV=`echo $CPU_USER_SAMPLES | sed -e's/% /,/g' -e's/%//'`
    CPU_SYS_CSV=`echo $CPU_SYS_SAMPLES | sed -e's/% /,/g' -e's/%//'`
    CPU_TOTAL_CSV=`grep 'CPU usage:' top.$SUFFIX | awk '{print $7}' | sed -e's/%//g' | awk '{printf("%s,", 100-$1)}'`
    echo "CPU_USER_TRACE: $CPU_USER_CSV" | tee -a trace.csv
    echo "CPU_SYS_TRACE: $CPU_SYS_CSV" | tee -a trace.csv
    echo "CPU_TOTAL_TRACE: $CPU_TOTAL_CSV" | tee -a trace.csv

    ;;
  esac
}

#
# Summarizes the output from the workload driver.
# At the moment, only JMeter is summarized (since the output is rather verbose), wrk output
# is output straight to the console.
#
function summarize_driver_output {
  SUFFIX=$1
  DRIVER=$2

  # Post-process driver output
  case $DRIVER in
  jmeter)
    # Cherry-pick useful information from JMeter summary. Expected format:
    #
    # summary +    997 in     6s =  165.6/s Avg:    59 Min:     2 Max:   215 Err:     0 (0.00%) Active: 10 Started: 10 Finished: 0
    #
    grep 'summary +' results.$SUFFIX | awk -v SKIP=${JMETER_SKIP_SAMPLES} '
      function sort(ARRAY, COUNT) {
        for (i = 2; i <= COUNT; ++i) {
          for (j = i; ARRAY[j-1] > ARRAY[j]; --j) {
            temp = ARRAY[j];
            ARRAY[j] = ARRAY[j-1];
            ARRAY[j-1] = temp;
          }
        }
        return 
      }
      BEGIN {
        min = 0; max = 0; count = 0; csv = "";
      }
      /summary \+ / {
        count ++;
        if (count > SKIP) {
          min = (min < $11 ? min : $11);
          max = (max > $13 ? max : $13);
          avgs[count-SKIP] = $9;
          sub("/s", "", $7);
          values[count-SKIP] = 0 + $7;
        }
      }
      END { 
        count -= SKIP;      # we skipped first N samples (warmup)
        count -= 1;         # skip the final sample (short sample, threads completing)
        for (i=1; i<=count; i++) { 
          tot_avg += avgs[i];               # Calculate average response time
          tot_thruput += values[i];         # Calculate average throughput
          csv = csv values[i] ",";
        }
        avg_rt = tot_avg/count;
        avg_tp = tot_thruput/count;
        sort(values, count);
        median_tp = values[int(count/2)];
        max_tp = values[count];
        print "Summary of last " count " samples (first " SKIP " and last 1 skipped):"
        print "Latency       " avg_rt "ms (avg)   " max "ms (max)";
        print "     99%      0ms  (data not available)"
        print "Requests/sec: " median_tp " (median), " avg_tp " (avg), " max_tp " (max)";
        print "THROUGHPUT_TRACE: " csv
      }' | tee -a jmeterSummary.$SUFFIX
    grep "THROUGHPUT_TRACE:" jmeterSummary.$SUFFIX | tee -a trace.csv
    ;;
  wrk | wrk-pipeline | wrk-nokeepalive | wrk2)
    # Nothing to do
    ;;
  sleep)
    # Generate some placeholder statistics for 'compare.sh' to consume
    echo "No requests were driven against the server."
    echo "Latency       0ms (avg)    0ms (max)"
    echo "     99%      0ms"
    echo "Requests/sec: 0"
    ;;
  *)
    ;;
  esac
}

# Summarize some Swift stats from a flat perf profile:
# - overhead of ARC (all symbols containing 'swift_release' or 'swift_retain')
# - overhead of malloc/free (all symbols in libc containing 'malloc' or 'free')
# - time spent in libswiftCore.so (excluding release/retain)
# - time spent in libFoundation.so (excluding release/retain)
function summarize_perf {
  REPORT=$1
  ARC_OVERHEAD=`cat $REPORT | grep -e 'swift_release' -e 'swift_retain' | awk '{x += $1} END {print x}'`
  echo "Overhead from ARC (release/retain): $ARC_OVERHEAD %"
  MALLOC_OVERHEAD=`cat $REPORT | grep 'libc-[0-9\.]*\.so' | grep -e 'malloc' -e 'free' | awk '{x += $1} END {print x}'`
  echo "Overhead of malloc/free: $MALLOC_OVERHEAD %"
  LIBSWIFT_TIME=`cat $REPORT | grep -e 'libswiftCore.so' | grep -v -e 'swift_release' -e 'swift_retain' | awk '{x += $1} END {print x}'`
  echo "Time spent in libswiftCore.so: $LIBSWIFT_TIME %"
  LIBFOUND_TIME=`cat $REPORT | grep -e 'libFoundation.so' | grep -v -e 'swift_release' -e 'swift_retain' | awk '{x += $1} END {print x}'`
  echo "Time spent in libFoundation.so: $LIBFOUND_TIME %"
}

#
# Measures the server using a specified number of clients + duration.
#
function do_sample {
  NUMCLIENTS=$1        # Number of concurrent clients (connections)
  DURATION=$2          # Time (in seconds) to drive load
  RATE=$3              # Constant request rate (only used by 'wrk2')
  if [ -z "$RATE" ]; then
    echo "Running load with $NUMCLIENTS clients"
  else
    echo "Running load with $NUMCLIENTS clients and $RATE rps load level"
  fi
 
  # Start recording CPU utilization 
  monitor_cpu $NUMCLIENTS $CPULIST $DURATION

  case $CLIENT in
  localhost)
    DRIVER_PREAMBLE=""
    ;;
  *)
    DRIVER_PREAMBLE="ssh -t $CLIENT "   # Execute driver remotely
    DRIVER_AFFINITY=""                  # Affinity may not be appropriate for remote machine
    ;;
  esac

  # Execute driver
  case $DRIVER in
  jmeter)
    echo ${DRIVER_PREAMBLE}${DRIVER_AFFINITY} jmeter -n -t ${JMETER_SCRIPT} -S ${SYSTEM_PROPS} -q ${USER_PROPS} -JTHREADS=$NUMCLIENTS -JDURATION=$DURATION -Jsummariser.interval=${INTERVAL} | tee results.$NUMCLIENTS
    ${DRIVER_PREAMBLE}${DRIVER_AFFINITY} jmeter -n -t ${JMETER_SCRIPT} -S ${SYSTEM_PROPS} -q ${USER_PROPS} -JTHREADS=$NUMCLIENTS -JDURATION=$DURATION -Jsummariser.interval=${INTERVAL} >> results.$NUMCLIENTS
    ;;
  wrk | wrk-pipeline | wrk-nokeepalive)
    # If pipelining requested, use pipeline.lua
    # (see: https://github.com/TechEmpower/FrameworkBenchmarks)
    if [ $DRIVER = "wrk-pipeline" ]; then
      WRK_SCRIPT="$SCRIPT_DIR/pipeline.lua -- 16"
    fi
    # If a script has been specified, add --script arg
    if [ ! -z "$WRK_SCRIPT" ]; then
      WRK_SCRIPT="--script $WRK_SCRIPT"
    fi
    WRK_OPTS=()
    if [ $DRIVER = "wrk-nokeepalive" ]; then
      WRK_OPTS+=("-H" "Connection: close")
    fi
    # Use non-standard -i option if available, adds periodic throughput reporting
    wrk | grep -q '\--interval'
    if [ $? -eq 0 ]; then
      WRK_OPTS+=("-i${INTERVAL}s")
    fi
    # Number of connections must be >= threads
    [[ ${WORK_THREADS} -gt ${NUMCLIENTS} ]] && WORK_THREADS=${NUMCLIENTS}
    echo ${DRIVER_PREAMBLE}${DRIVER_AFFINITY} wrk --timeout 30 --latency -t${WORK_THREADS} -c${NUMCLIENTS} -d${DURATION}s "${WRK_OPTS[@]}" ${URL} $WRK_SCRIPT | tee results.$NUMCLIENTS
    ${DRIVER_PREAMBLE}${DRIVER_AFFINITY} wrk --timeout 30 --latency -t${WORK_THREADS} -c${NUMCLIENTS} -d${DURATION}s "${WRK_OPTS[@]}" ${URL} $WRK_SCRIPT 2>&1 | tee -a results.$NUMCLIENTS
    ;;
  wrk2)
    # Number of connections must be >= threads
    [[ ${WORK_THREADS} -gt ${NUMCLIENTS} ]] && WORK_THREADS=${NUMCLIENTS}
    # Because wrk2 uses a 10 second calibration period, add 10 seconds to the duration
    let WRK2_DURATION=$DURATION+10
    echo ${DRIVER_PREAMBLE}${DRIVER_AFFINITY} wrk2 --timeout 30 --latency -R ${RATE} -t${WORK_THREADS} -c${NUMCLIENTS} -d${WRK2_DURATION}s ${URL} | tee results.$NUMCLIENTS
    ${DRIVER_PREAMBLE}${DRIVER_AFFINITY} wrk2 --timeout 30 --latency -R ${RATE} -t${WORK_THREADS} -c${NUMCLIENTS} -d${WRK2_DURATION}s ${URL} 2>&1 | tee -a results.$NUMCLIENTS
    # For no keepalive you can do: -H "Connection: close"
    ;;
  sleep)
    # Drive no requests
    echo "Driving no requests (sleep $DURATION)"
    sleep $DURATION
    ;;
  *)
    echo "Unknown driver '$DRIVER'"
    ;;
  esac

  summarize_driver_output $NUMCLIENTS $DRIVER

  # Stop monitoring and summarize CPU utilization
  end_monitor_cpu $NUMCLIENTS $CPULIST
}

#
# Apply temporary system configuration changes beneficial for benchmarking
# Note: these require sudo permission (preferably passwordless)
# If you do not have sudo, set SUDO_PERMISSIONS=no above.
#
function sudosetup() {
  case `uname` in
  Linux)
    # For Perfect, I needed to enable tcp_tw_reuse and tcp_tw_recycle
    # (this should be safe given that we are only talking over localhost)
    TCP_TW_REUSE=`cat /proc/sys/net/ipv4/tcp_tw_reuse`
    TCP_TW_RECYCLE=`cat /proc/sys/net/ipv4/tcp_tw_recycle`
    sudo su -c "echo 1 > /proc/sys/net/ipv4/tcp_tw_reuse"
    sudo su -c "echo 1 > /proc/sys/net/ipv4/tcp_tw_recycle"
    ;;
  Darwin)
    # On Mac, we have to monkey with the TCP defaults to drive load
    # (see: http://stackoverflow.com/questions/1216267)
    # Defaults are:
    # net.inet.ip.portrange.first: 49152
    # net.inet.ip.portrange.last: 65535
    # net.inet.tcp.msl: 15000
    FIRST_EPHEM_PORT=`sysctl -n net.inet.ip.portrange.first`
    LAST_EPHEM_PORT=`sysctl -n net.inet.ip.portrange.last`
    TCP_MSL=`sysctl -n net.inet.tcp.msl`
    NEW_FIRST_PORT=$FIRST_EPHEM_PORT
    NEW_TCP_MSL=$TCP_MSL
    if [ $TCP_MSL -gt 1000 ]; then
      echo "Reducing the TCP maximum segment lifetime (otherwise, we will rapidly run out of ports):"
      echo "sudo sysctl -w net.inet.tcp.msl=1000"
      sudo sysctl -w net.inet.tcp.msl=1000
      NEW_TCP_MSL=`sysctl -n net.inet.tcp.msl`
    fi
    if [ $FIRST_EPHEM_PORT -gt 16384 ]; then
      echo "Increasing number of ephemeral ports available"
      echo "sudo sysctl -w net.inet.ip.portrange.first=16384"
      sudo sysctl -w net.inet.ip.portrange.first=16384
      NEW_FIRST_PORT=`sysctl -n net.inet.ip.portrange.first`
    fi
    # Disable firewall during the test
    FIREWALL_STATE=`sudo defaults read /Library/Preferences/com.apple.alf globalstate`
    if [ $FIREWALL_STATE -ne 0 ]; then
      echo "Disabling firewall during test"
      sudo defaults write /Library/Preferences/com.apple.alf globalstate -int 0
      sudo launchctl unload /System/Library/LaunchDaemons/com.apple.alf.agent.plist
      sudo launchctl load /System/Library/LaunchDaemons/com.apple.alf.agent.plist
    fi
    ;;
  esac
}

#
# Perform temporary environment changes required for testing
# Note, perf-idle and oprofile-sys require sudo permission.
#
function setup() {
  # Enable corefile generation (for debugging failed runs)
  ulimit -c unlimited
  # Profiling with 'oprofile', 'valgrind' and 'perf' will only work properly for 1 instance
  # of the app. 'oprofile-sys' should work with any number.
  case $PROFILER in
  perf)
    # Enable perf to access kernel address maps
    echo 0 | sudo tee /proc/sys/kernel/kptr_restrict
    PROFILER_CMD="perf record"
    ;;
  perf-cg)
    # Enable perf to access kernel address maps
    echo 0 | sudo tee /proc/sys/kernel/kptr_restrict
    PROFILER_CMD="perf record -g"
    ;;
  perf-idle)
    # Need root permissions to get scheduler stats
    PROFILER_CMD="sudo perf record -e sched:sched_stat_sleep -e sched:sched_switch -e sched:sched_process_exit -g -o perf.data.raw"
    ;;
  oprofile)
    PROFILER_CMD="operf --events CPU_CLK_UNHALTED:500000 --callgraph --vmlinux /usr/lib/debug/boot/vmlinux-`uname -r`"
    ;;
  oprofile-sys)
    PROFILER_CMD=""
    # To get kernel symbols, requires the linux-image-xyz-dbgsym package, see
    # http://superuser.com/questions/62575/where-is-vmlinux-on-my-ubuntu-installation/309589#309589
    sudo operf --events CPU_CLK_UNHALTED:500000 --callgraph --system-wide --vmlinux /usr/lib/debug/boot/vmlinux-`uname -r` &
    PROFILER_PID=$!
    ;;
  valgrind)
    let DETAILEDFREQ=$DURATION/2
    # Threshold determines level of detail in the report. A smaller threshold (eg. 0.1) is useful
    # if allocations are spread evenly across a number of similar paths, and each path falls under
    # the default 1% threshold.
    VALGRIND_THRESHOLD="1"
    PROFILER_CMD="valgrind --tool=massif --threshold=$VALGRIND_THRESHOLD --time-unit=ms --max-snapshots=100 --detailed-freq=$DETAILEDFREQ"
    ;;
  *)
    PROFILER_CMD=""
    ;;
  esac
}

#
# Start server instance(s) and associated monitoring
# Expects $INSTANCES, $APP_AFFINITY, $APP_CMD and PROFILER_CMD to be set.
# If $APP_PWD is set, changes to that directory before executing $APP_CMD.
# Sets $APP_PIDS.
#
function startup() {
  echo "Starting App ($INSTANCES instances)"
  local logPath=$PWD
  if [ ! -z "$APP_PWD" ]; then
    echo "App PWD: $APP_PWD"
    pushd $APP_PWD > /dev/null
  fi
  for i in `seq 1 $INSTANCES`; do
    echo $APP_AFFINITY $APP_CMD | tee ${logPath}/app${i}.log
    $APP_AFFINITY $PROFILER_CMD $APP_CMD >> ${logPath}/app${i}.log 2>&1 &
    APP_PIDS="$! $APP_PIDS"
  done
  if [ ! -z "$APP_PWD" ]; then
    popd > /dev/null
  fi

  # Wait for servers to be ready (up to 30 seconds)
  # This allows server start scripts to perform pre-start actions (such as cleanup or database reset)
  # - use curl to detect when server is ready to respond
  # - max wait time of 1 second in case server accepts connections but is unresponsive
  let MAX_WAIT_TIME=30
  let WAIT_SO_FAR=0
  let CHECK_INTERVAL=2
  while [ ! $WAIT_SO_FAR -gt $MAX_WAIT_TIME ]; do
    sleep $CHECK_INTERVAL
    let WAIT_SO_FAR=WAIT_SO_FAR+CHECK_INTERVAL
    ${DRIVER_PREAMBLE} curl -k -m 1 --head $URL >/dev/null 2>&1 && break || echo "Waiting for server - $WAIT_SO_FAR seconds"
  done
  if [ $WAIT_SO_FAR -gt $MAX_WAIT_TIME ]; then
    echo "App failed to start after $MAX_WAIT_TIME seconds"
  fi
  echo "App pids=$APP_PIDS"

  # Identify any child processes (eg. when using Node.js cluster)
  CHILD_PIDS=""
  for APP_PID in $APP_PIDS; do
    MORE_CHILD_PIDS=`ps -o ppid,pid | grep -e"^ *$APP_PID " | cut -d' ' -f2 | xargs echo`
    if [ ! -z "$MORE_CHILD_PIDS" ]; then
      CHILD_PIDS="$MORE_CHILD_PIDS $CHILD_PIDS"
    fi
  done
  if [ ! -z "$CHILD_PIDS" ]; then
    echo "Child pids=$CHILD_PIDS"
  fi

  # monitor RSS
  let i=0
  for APP_PID in $APP_PIDS $CHILD_PIDS; do
    let i=$i+1
    $SCRIPT_DIR/monitorRSS.sh $APP_PID $INTERVAL > rssout${i}.txt &
    RSSMON_PIDS="$! $RSSMON_PIDS"
  done
  RSSMON_COUNT=$i
  # Report how many processes are executing as a result of starting the server
  echo "Total server processes: $i"
}

#
# Shutdown server instance(s) and associated monitoring
#
function shutdown() {
  # Shut down RSS monitoring
  kill $RSSMON_PIDS
  wait $RSSMON_PIDS
  # Shut down application
  case $PROFILER in
  perf-idle)
    # Perf was run with sudo, must kill with sudo
    sudo kill $APP_PIDS
    ;;
  oprofile)
    # Must kill operf with SIGINT, otherwise child processes are left running
    kill -SIGINT $APP_PIDS
    ;;
  oprofile-sys)
    kill $APP_PIDS
    sudo kill -SIGINT $PROFILER_PID
    wait $PROFILER_PID
    ;;
  *)
    # Standard kill (SIGTERM)
    kill $APP_PIDS
    ;;
  esac
  # Wait for process(es) to end
  for APP_PID in $APP_PIDS; do
    wait $APP_PID
    APP_RC=$?
  # Expect RC=143 (128 + 15 = SIGTERM)
    if [ $APP_RC -ne 143 -a $APP_RC -ne 15 ]; then
      echo "Detected unexpected termination: RC of $APP_PID = $APP_RC"
    else 
      echo "Detected successful termination of $APP_PID"
    fi
  done
}

#
# Revert any temporary configuration changes performed by sudosetup()
#
function sudoteardown() {
  case `uname` in
  Linux)
    sudo su -c "echo $TCP_TW_REUSE > /proc/sys/net/ipv4/tcp_tw_reuse"
    sudo su -c "echo $TCP_TW_RECYCLE > /proc/sys/net/ipv4/tcp_tw_recycle"
    ;;
  Darwin)
    if [ $TCP_MSL -ne $NEW_TCP_MSL ]; then
      echo "Restoring TCP maximum segment lifetime"
      sudo sysctl -w net.inet.tcp.msl=$TCP_MSL
    fi
    if [ $FIRST_EPHEM_PORT -ne $NEW_FIRST_PORT ]; then
      echo "Restoring ephemeral port range"
      sudo sysctl -w net.inet.ip.portrange.first=$FIRST_EPHEM_PORT
    fi
    if [ $FIREWALL_STATE -ne 0 ]; then
      echo "Restoring firewall state to $FIREWALL_STATE"
      sudo defaults write /Library/Preferences/com.apple.alf globalstate -int $FIREWALL_STATE
      sudo launchctl unload /System/Library/LaunchDaemons/com.apple.alf.agent.plist
      sudo launchctl load /System/Library/LaunchDaemons/com.apple.alf.agent.plist
    fi
  esac
}

#
# Restore any temporary environment changes
#
function teardown() {
  # Profiling output will be named with the pid of the first app instance
  FIRST_APP_PID=`echo $APP_PIDS | cut -d' ' -f1`
  case $PROFILER in
  perf)
    perf report -k /usr/lib/debug/boot/vmlinux-`uname -r` > perf-report.${FIRST_APP_PID}.txt
    cat perf-report.${FIRST_APP_PID}.txt | swift-demangle | sed -e's#  *$##' > perf-report.${FIRST_APP_PID}.demangled.txt
    summarize_perf "perf-report.${FIRST_APP_PID}.demangled.txt"
    ;;
  perf-cg)
    # Generate a profile with --no-children so it is sorted by self (equivalent to a flat profile,
    # but with callgraph information)
    perf report --no-children -k /usr/lib/debug/boot/vmlinux-`uname -r` > perf-cg-report.${FIRST_APP_PID}.txt
    cat perf-cg-report.${FIRST_APP_PID}.txt | swift-demangle | sed -e's#  *$##' > perf-cg-report.${FIRST_APP_PID}.demangled.txt
    # Generate a second flat profile from the same sampling data, for convenience
    perf report --max-stack=1 --no-children -k /usr/lib/debug/boot/vmlinux-`uname -r` > perf-report.${FIRST_APP_PID}.txt
    cat perf-report.${FIRST_APP_PID}.txt | swift-demangle | sed -e's#  *$##' > perf-report.${FIRST_APP_PID}.demangled.txt
    summarize_perf "perf-report.${FIRST_APP_PID}.demangled.txt"
    ;;
  perf-idle)
    sudo perf inject -v -s -i perf.data.raw -o perf.data
    sudo chown $USER: perf.data.raw perf.data
    perf report -k /usr/lib/debug/boot/vmlinux-`uname -r` > perf-idle-report.${FIRST_APP_PID}.txt
    cat perf-idle-report.${FIRST_APP_PID}.txt | swift-demangle | sed -e's#  *$##' > perf-idle-report.${FIRST_APP_PID}.demangled.txt
    ;;
  oprofile | oprofile-sys)
    # Plaintext report (overall by image, then callgraph for symbols worth 1% or more)
    opreport --demangle=none --threshold 0.1 > oprofile.${FIRST_APP_PID}.txt
    opreport --demangle=none --callgraph --threshold 1 >> oprofile.${FIRST_APP_PID}.txt 2>/dev/null
    cat oprofile.${FIRST_APP_PID}.txt | swift-demangle > oprofile.${FIRST_APP_PID}.demangled.txt
    # XML report (for use in VPA)
    opreport --xml > oprofile.${FIRST_APP_PID}.opm
    cat oprofile.${FIRST_APP_PID}.opm | swift-demangle > oprofile.${FIRST_APP_PID}.demangled.opm
    ;;
  valgrind)
    ms_print --threshold=$VALGRIND_THRESHOLD massif.out.${FIRST_APP_PID} > msprint.${FIRST_APP_PID}.txt
    cat msprint.${FIRST_APP_PID}.txt | swift-demangle > msprint.${FIRST_APP_PID}.demangled.txt
    ;;
  *)
    ;;
  esac
}

#
# Kills any processes started by this script and then exits
#
function terminate() {
  echo "Killing app: $APP_PIDS"
  # Kill each app instance 
  for APP_PID in $APP_PIDS $CHILD_PIDS; do
    kill $APP_PID 2>/dev/null
  done
  echo "Killing monitors: $RSSMON_PIDS $MPSTAT_PID"
  kill $RSSMON_PIDS 2>/dev/null
  kill $MPSTAT_PID 2>/dev/null
  echo "Processes killed"
  teardown
  # Kill anything with the same PGID as our PID (syntax: -PID)
  trap - SIGTERM
  echo "Killing anything with our pgid"
  kill -- -$$ 2>/dev/null
  exit 1
}

trap terminate SIGINT SIGQUIT SIGTERM

# Begin run
mkdir -p runs/$RUN_NAME
cd runs/$RUN_NAME

echo "Run name = '$RUN_NAME'"
echo "CPU list = '$CPULIST'"
echo "Clients sequence = '$SAMPLES'"
if [ -n "$WORK_RATE" ]; then
  echo "Load level sequence = '$WORK_RATE'"
fi
echo "Application: $APP_CMD"
echo "URL: $URL"
echo "Client machine: $CLIENT"

setup
if [ "$SUDO_PERMISSIONS" = "yes" ]; then
  sudosetup
fi
startup

# Execute driver and associated monitoring for each number of clients
for SAMPLE in `echo $SAMPLES | tr ',' ' '`; do
  case $DRIVER in
  wrk2)
    # Constant-rate: Execute driver for each load level
    for RATE in `echo $WORK_RATE | tr ',' ' '`; do
      do_sample $SAMPLE $DURATION $RATE
    done
    ;;
  *)
    # Variable-rate: Drive at maximum speed (given no. of clients)
    do_sample $SAMPLE $DURATION
    ;;
  esac
done

shutdown
if [ "$SUDO_PERMISSIONS" = "yes" ]; then
  sudoteardown
fi
teardown

# Summarize RSS growth
# Print a line of CSV for each process' RSS history in trace.csv
echo "Resident set size (RSS) summary:" | tee mem.log
for i in `seq 1 $RSSMON_COUNT`; do
  RSS_START=`head -n 1 rssout${i}.txt | awk '{print $1}'`
  RSS_END=`tail -n 1 rssout${i}.txt | awk '{print $1}'`
  printf "RSS_TRACE_${i}: " | tee -a trace.csv
  file=rssout${i}.txt
  awk '{printf $1","}END{printf "\n"}' $file | tee -a trace.csv
  RSS_HIGH_WATER_MARK=`awk -v max=0 '{if($1>max){max=$1}}END{print max}' rssout${i}.txt`
  let RSS_DIFF=$RSS_END-$RSS_START
  echo "$i: RSS (kb): start=$RSS_START end=$RSS_END delta=$RSS_DIFF max=$RSS_HIGH_WATER_MARK" | tee -a mem.log
done
printf "RSS_TRACE_TOTAL: " | tee -a trace.csv
awk -v RSS_TRACE=$RSS_TRACE '{a[FNR]+=$1}END{for(i=1;i<=FNR;i++) printf a[i]","}' rssout* | tee -a trace.csv
