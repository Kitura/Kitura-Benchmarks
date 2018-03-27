#!/bin/sh
# Simple script to launch multiple instances of an application, and kill all instances
# when this script is killed.
NUMPROCS=$1
shift
APP=$1
shift
ARGS=$*

PIDS=""

if [ -z "$APP" ]; then
  echo "Usage: runmany <instances> <full path to binary> [<arg>...]"
  exit 1
fi

function shutdown() {
  kill $PIDS
  echo "Processes killed"
}

trap shutdown SIGINT SIGQUIT SIGTERM

echo "Starting $NUMPROCS instances of $APP"
for i in `seq 1 $NUMPROCS`; do
  $APP $ARGS &
  PIDS="$! $PIDS"
done

echo "Pids = $PIDS"
wait $PIDS
echo "Processes seem to have ended"
