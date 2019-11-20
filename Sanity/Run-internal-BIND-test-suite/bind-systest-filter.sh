#!/bin/bash
#
# This script will filter out output from BINDs tests
# It supports form from BIND 9.9 and BIND 9.11
# Its purpose is to display only failed tests from list of all tests

CURRENT_TEST=
CURRENT_OUTPUT=
STATUS_ONLY=

for P; do
	case "$P" in
		-s|--status)	STATUS_ONLY=yes; shift ;;
	esac
done

cat $@ | while read LINE; do
	if [ "${LINE#S:}" != "$LINE" ]; then
		CURRENT_TEST=`echo $LINE | cut -d: -f2`
		CURRENT_OUTPUT="$LINE"$'\n'
	elif [ "${LINE#R:}" != "$LINE" ]; then
		# echo "$CURRENT_TEST $LINE"
		if [ "${LINE/#R:*:*}" != "$LINE" ]; then
			# more recent results contain test name
			# R:dlz:FAIL
			CURRENT_TEST="${LINE#R:}"
			CURRENT_TEST="${CURRENT_TEST/%:*}"
			RESULT="${LINE/#*:}"
		else
			# S:dlz:time
			# R:FAIL
			RESULT="${LINE/#R*:/}"
		fi
		if [ "$RESULT" != "PASS" ]; then
			if [ -n "$STATUS_ONLY" ]; then
				echo "$RESULT $CURRENT_TEST"
			else
				CURRENT_OUTPUT+="$LINE"
				echo "$CURRENT_OUTPUT"
				echo
			fi
		fi
		CURRENT_OUTPUT=
	else
		CURRENT_OUTPUT+="$LINE"$'\n'
	fi
done
