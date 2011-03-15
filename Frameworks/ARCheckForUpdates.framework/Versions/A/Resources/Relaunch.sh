#!/bin/sh

echo "PID: $1"
echo "relauncher: $2"
echo "path: $3"

echo "Waiting..."
while [ 1 ] ; do
        pidno=$( ps -p $1 | grep $1 )
        if [ -z "$pidno" ]; then
                break
        fi
		sleep 1
done
echo "Launching $2 with $3..."
"$2" "$3" &
echo "Done!"
