#!/bin/bash

# If the first argument is a number, treat it as a PID
if [[ "$1" =~ ^[0-9]+$ ]]; then
	PID=$1
	shift
else
	PID=$$
fi

PROCESS_NAME=${1:-"Process"}
WEBHOOK=${2:-${SLACK_WEBHOOK:-}}

(
while kill -0 "$PID" 2>/dev/null;
do
	sleep 5
done
curl -s -X POST -H 'Content-type: application/json' \
	--data "{\"text\":\"✅ $PROCESS_NAME (PID: $PID) Completed!\"}" \
	"$WEBHOOK" >/dev/null
) &



