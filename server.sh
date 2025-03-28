#!/bin/bash

function handle_http_request(){

	REGEX='(.*?)\s(.*?)\sHTTP.*?'

	while read LINE; 
	do
	    [[ "$LINE" =~ $REGEX ]] && REQUEST=$(echo $LINE | sed -E "s/$REGEX/\1 \2/") && break
	done

	RESPONSE="HTTP/1.1 200\r\nContent-Type: application/json\r\nConnection: close\r\n\r\n"
	DEFAULT='{"error":404}'

	readarray -t FILES <<< $(ls *json)

	for FILENAME in ${FILES[*]}
	do
		NAME=${FILENAME%.*}

		case "$REQUEST" in
			"GET /"$NAME) { RESPONSE=$RESPONSE$(cat $FILENAME); DEFAULT=""; break; } ;;
			"GET /"$FILENAME) { RESPONSE=$RESPONSE$(cat $FILENAME); DEFAULT=""; break; } ;;
		esac
	done

	echo -e $RESPONSE$DEFAULT > $RESPONSE_PIPE
}

RESPONSE_PIPE=/tmp/response_pipe

if [ ! -p "$RESPONSE_PIPE" ]; then
	echo "create response pipe..."
	mkfifo $RESPONSE_PIPE 
fi

PORT=1234

while true; 
do 
	cat $RESPONSE_PIPE | nc -lN 127.0.0.1 $PORT -q 1 | handle_http_request
done
