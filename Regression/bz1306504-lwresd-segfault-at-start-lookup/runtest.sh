#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/bind/Regression/bz1306504-lwresd-segfault-at-start-lookup
#   Description: Test for BZ#1306504 (lwresd segfault at start_lookup)
#   Author: Petr Sklenar <psklenar@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2016 Red Hat, Inc.
#
#   This program is free software: you can redistribute it and/or
#   modify it under the terms of the GNU General Public License as
#   published by the Free Software Foundation, either version 2 of
#   the License, or (at your option) any later version.
#
#   This program is distributed in the hope that it will be
#   useful, but WITHOUT ANY WARRANTY; without even the implied
#   warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
#   PURPOSE.  See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program. If not, see http://www.gnu.org/licenses/.
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Include Beaker environment
. /usr/bin/rhts-environment.sh || exit 1
. /usr/share/beakerlib/beakerlib.sh || exit 1

PACKAGE="bind"

SERVERLOG=$(mktemp ServerLogXXXXXXXXXX)
DNS1=$(cat /etc/resolv.conf  | grep -v '^#' | grep nameserver | awk '{print $2}' | head -n1)

rlJournalStart
    rlPhaseStartSetup
        rlAssertRpm $PACKAGE
        #stop testing if DSN1 is wrong:
	rlRun "ping $DNS1 -w2" || rlDie
        #rhel6 uses liblwres.so.80 ; rhel7 liblwres.so.90; F24beta uses liblwres.so.141;
	LIBLWRES=$(rpm -ql bind-libs | grep liblwres.so|head -n1)
	LIBLWRESNEW=$(dirname $LIBLWRES)/liblwres.so
	ln -s $LIBLWRES $LIBLWRESNEW
	rlRun "ls -la $LIBLWRESNEW"
        #it shouldn't traceback
        if rlIsRHEL '<=7'; then
            rlRun "python client.py &>/dev/null" || rlDie
        else
            rlRun "python3 client3.py &>/dev/null" || rlDie
        fi
    rlPhaseEnd

    rlPhaseStartSetup "start server"
	bash server.sh $DNS1 &> $SERVERLOG &
	PIDSERVER=$!
	sleep 5
	rlRun "grep -i 'starting BIND' $SERVERLOG"
    rlPhaseEnd

    rlPhaseStartTest "client part"
        #only run, if there is segfault client.py hangs and test fails
	if rlIsRHEL '<=7'; then
            rlRun "timeout 1m python client.py"
        else
            rlRun "timeout 1m python3 client3.py"
        fi
	sleep 5
    rlPhaseEnd

    rlPhaseStartTest "check the server, PID = $PIDSERVER"
        #if there is bug, pid is not here
	rlRun "ps -p $PIDSERVER"
    rlPhaseEnd

    rlPhaseStartCleanup
	kill -9 $PIDSERVER
	sleep 5
	rlFileSubmit $SERVERLOG
	rm -rf $LIBLWRESNEW
        rlRun "rm -r $SERVERLOG" 0 "Removing tmp directory"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
