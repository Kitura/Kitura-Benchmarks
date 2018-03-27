#!/bin/bash

#
# Sanitize a string, replacing special characters (newline, CR, double quotes)
# with escaped versions, suitable for output in a JSON document.
#
# Param 1: the string to sanitize
# Result: written to the SANITIZED_STRING variable
#
function sanitize_string {
    local SANITIZED_STRING=$1
    # escape backslashes
    SANITIZED_STRING=${SANITIZED_STRING//$'\\'/\\\\}
    # escape newlines
    SANITIZED_STRING=${SANITIZED_STRING//$'\n'/\\n}
    # escape carriage returns
    SANITIZED_STRING=${SANITIZED_STRING//$'\r'/\\r}
    # escape double quotes
    SANITIZED_STRING=${SANITIZED_STRING//$'\"'/\\\"}

    echo $SANITIZED_STRING

    #if [ ! "$1" == "$SANITIZED_STRING" ]; then
    #  echo "$1 was converted to $SANITIZED_STRING"
    #fi
}
