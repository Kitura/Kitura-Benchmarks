#!/bin/sh
# Simple script to capture resident set and virtual size of a process (as reported by 'ps')
# periodically, to monitor process footprint over time.

# Kitura zombie process causes problems here... an alternative (get the RSS from one of the threads)
# would be:
# ps -p <pid> -L -o pid,ppid,tid,time,rss,cmd
# or:
# ps -p <pid> -L -o rss,vsz

PID=$1
INTERVAL=$2

if [ -z "$INTERVAL" ]; then
  echo "Usage: monitorRSS <pid> <interval>"
  exit 1
fi

# Need to use different options to extract the RSS from Kitura on Linux, as (currently)
# the process gets marked as 'defunct' and the information is only reported against the
# other application threads.
case `uname` in
Linux)
  #fix for Kitura:
  PS_OPTS="-L -o rss,vsz"
  ;;
Darwin)
  PS_OPTS="-o rss,vsz"
  ;;
*)
  echo "Unknown OS '`uname`'"
  exit 1
esac

while true; do
  ps -p $PID $PS_OPTS | tail -n 1
  sleep $INTERVAL
done
