#!/bin/bash
#
# Copyright IBM Corporation 2017
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

# Determine location of this script
JSON_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

. ${JSON_SCRIPT_DIR}/sanitize.sh

JSON_ENABLED=0
JSON_INDENT=0
JSON_COMMA=0
JSON_OUTPUT=""

#
# Sets the output filename to write, and enables JSON output
# Param 1: name of file
#
function json_set_file {
  JSON_OUTPUT="$1"
  JSON_ENABLED=1
  JSON_INDENT=0
  JSON_COMMA=0
}

#
# Disables JSON output
#
function json_stop {
  JSON_OUTPUT=""
  JSON_ENABLED=0
}

#
# Output {
# - and increase indent level
#
function json_start {
  if [ $JSON_ENABLED -eq 0 ]; then return; fi
  json_indent
  printf "{\n" > $JSON_OUTPUT
  JSON_INDENT=$((JSON_INDENT+1))
}

#
# Output }
# - and decrease indent level
#
function json_end {
  if [ $JSON_ENABLED -eq 0 ]; then return; fi
  while [ $JSON_INDENT -gt 0 ]; do
    JSON_INDENT=$((JSON_INDENT-1))
    printf "\n" >> $JSON_OUTPUT
    json_indent
    printf "}" >> $JSON_OUTPUT
  done
  printf "\n"
}

#
# Output "string: "string"
# - appending a comma to the previous value, if one is present
# Param 1: name
# Param 2: string
#
function json_string {
  if [ $JSON_ENABLED -eq 0 ]; then return; fi
  JSON_KEY=`sanitize_string "$1"`
  JSON_VAL=`sanitize_string "$2"`
  json_comma
  json_indent
  printf "\"%s\": \"%s\"" "$JSON_KEY" "$JSON_VAL" >> $JSON_OUTPUT
}

#
# Output "string": number
# - appending a comma to the previous value, if one is present
# Param 1: name
# Param 2: number
#
function json_number {
  if [ $JSON_ENABLED -eq 0 ]; then return; fi
  JSON_KEY=`sanitize_string "$1"`
  JSON_VAL=`sanitize_string "$2"`
  json_comma
  json_indent
  printf "\"%s\": %s" "$JSON_KEY" "$JSON_VAL" >> $JSON_OUTPUT
}

#
# Output "name": {
# - and increase indent level
# Param 1: name
#
function json_object_start {
  if [ $JSON_ENABLED -eq 0 ]; then return; fi
  JSON_KEY=`sanitize_string "$1"`
  json_comma
  json_indent
  printf "\"%s\": {\n" "$JSON_KEY" >> $JSON_OUTPUT
  JSON_COMMA=0
  JSON_INDENT=$((JSON_INDENT+1))
}

#
# Output }
# - and decrease indent level
#
function json_object_end {
  if [ $JSON_ENABLED -eq 0 ]; then return; fi
  JSON_INDENT=$((JSON_INDENT-1))
  printf "\n" >> $JSON_OUTPUT
  json_indent
  printf "}" >> $JSON_OUTPUT
  JSON_COMMA=1
}

#
# Indents the current line
#
function json_indent {
  if [ $JSON_ENABLED -eq 0 ]; then return; fi
  COUNTER=0
  while [ $COUNTER -lt $JSON_INDENT ]; do
    COUNTER=$((COUNTER+1))
    printf "    " >> $JSON_OUTPUT
  done
}

#
# Appends a command and newline if appropriate
#
function json_comma {
  if [ $JSON_ENABLED -eq 0 ]; then return; fi
  if [ $JSON_COMMA -gt 0 ]; then
    printf ",\n" >> $JSON_OUTPUT
  fi
  JSON_COMMA=1
}

#
# Writes an object containing the current environment
#
function json_env {
  if [ $JSON_ENABLED -eq 0 ]; then return; fi
  json_object_start "Env"
  TMPIFS="$IFS"
  IFS="
"
  for ENVVAR in `env`; do
    ENVKEY="`echo $ENVVAR | sed -e's#=.*##'`"
    ENVVAL="`echo $ENVVAR | sed -e's#[^=]*=##'`"
    json_string "$ENVKEY" "$ENVVAL"
  done
  IFS="$TMPIFS"
  json_object_end
}
