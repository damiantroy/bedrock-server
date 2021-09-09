#!/usr/bin/env bash

function usage() {
    echo "Usage: $(basename $0) -t <timeout> -f <log_file> -s <success_string>"
}

while getopts "t:f:s:" OPT; do
    case "$OPT" in
        t) TIMEOUT=$OPTARG ;;
        f) LOG_FILE=$OPTARG ;;
        s) SUCCESS_STRING=$OPTARG ;;
        *) usage ;;
    esac
done

if [[ -z "$TIMEOUT" || -z "$LOG_FILE" || -z "$SUCCESS_STRING" ]]; then
    usage
fi

# wait functions from:
# https://superuser.com/questions/270529/monitoring-a-file-until-a-string-is-found

wait_str() {
  local file="$1"; shift
  local search_term="$1"; shift
  local wait_time="${1:-30s}"; shift # 30 seconds as default timeout

  (timeout $wait_time tail -F -n10 "$file" &) | grep -q "$search_term" && return 0

  echo "Timeout of $wait_time reached. Unable to find '$search_term' in '$file'"
  return 1
}

wait_file() {
  local file="$1"; shift
  local wait_seconds="${1:-10}"; shift # 10 seconds as default timeout

  until test $((wait_seconds--)) -eq 0 -o -f "$file" ; do sleep 1; done

  ((++wait_seconds))
}

wait_server() {
  echo "Waiting for server..."
  local server_log="$1"; shift
  local search_term="$1"; shift
  local wait_time="$1"; shift

  wait_file "$server_log" 10 || { echo "Server log file missing: '$server_log'"; return 1; }

  wait_str "$server_log" "$search_term" "$wait_time"
}

if wait_server "$LOG_FILE" "$SUCCESS_STRING" "$TIMEOUT"; then
    echo "*** Test successful"
fi

