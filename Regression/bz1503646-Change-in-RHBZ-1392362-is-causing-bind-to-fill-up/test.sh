#!/bin/sh
#
# Reproduce bug #1503646
# Note: this analyses mounts in all system processes
# It might report false positives

count_total_mounts()
{
	wc -l /proc/[0-9]*/mounts | sort -nr | head -n 1 | cut -d' ' -f1
}

count_top_mounts()
{

	wc -l /proc/[0-9]*/mounts | sort -nr | head -n 5 | while read COUNT MOUNT; do
		local PID=`echo $MOUNT | cut -s -d/ -f3`
		if [ -n "$PID" ]; then
			echo "Mounts: $COUNT"
			ps hu $PID
		fi
	done
}

if [ `whoami` != "root" ]
then
	echo "Run me as root"
	exit 1
fi

MOUNTS_BEFORE=`count_total_mounts`

echo "Top mounts processes before"
count_top_mounts

for I in `seq 16`; do
	echo "Restarting named-chroot ($I)..."
	systemctl restart named-chroot
	MOUNTS=`count_total_mounts`
	if [ "$MOUNTS" -gt "$((2*MOUNTS_BEFORE))" ]
	then
		echo "ERROR: Total process mounts doubled from $MOUNTS_BEFORE to $MOUNTS"
		count_top_mounts
		exit 1
	fi
	sleep 5
done

echo "Top mounts processes after"
count_top_mounts

MOUNTS=`count_total_mounts`
echo "Total process mounts before $MOUNTS_BEFORE ~= $MOUNTS after "
