#!/bin/bash

declare -A PROCESSES=(
    [MySQL]="mysqld"
    [HypnoToad]="hypnotoad -f /cbqz/app.pl"
    [Nginx]="nginx"
)

POLLING_FREQUENCY=1

declare -A PIDS

trap shutdown INT

function shutdown {
    if [ ${#1} -gt 0 ]
    then
        echo "Problem with process $1 (${PROCESSES[$1]}): $2"
    else
        echo "Interupt caught; shutting down"
    fi

    for PROCESS in "${!PIDS[@]}"
    do
        echo "Shutting down: $PROCESS (${PROCESSES[$PROCESS]})"
        kill ${PIDS[$PROCESS]} 2>/dev/null
    done

    echo "Shutdown complete"
    exit $2
}

function startup {
    echo "Starting $1"

    $2 &
    PIDS[$1]=$!
    STATUS=$?

    if [ $STATUS -ne 0 ]
    then
        shutdown $1 $STATUS
    fi
}

for PROCESS in "${!PROCESSES[@]}"
do
    startup $PROCESS ${PROCESSES[$PROCESS]}
done

while [ 1 ]
do
    for PROCESS in "${!PROCESSES[@]}"
    do
        if [ $( ps -p ${PIDS[$PROCESS]} | wc -l ) -ne 2 ]
        then
            shutdown $PROCESS -1
        fi
    done

    sleep $POLLING_FREQUENCY
done
