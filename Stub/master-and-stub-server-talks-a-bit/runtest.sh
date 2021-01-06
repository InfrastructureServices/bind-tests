#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of example.com.zone  Makefile  named.conf.MASTER  named.conf.STUB  PURPOSE  runtest.sh
#   Description: sanity testing of stub server
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

rlJournalStart
    rlPhaseStartSetup "base setup"
        rlAssertRpm $PACKAGE
	dir='/tmp/bind-for-petr'
	rm -rf $dir
	mkdir -p $dir
	cp petr.god.zone $dir
	cp named.conf.MASTER $dir/named.conf.MASTER
	cp named.conf.STUB $dir/named.conf.STUB
	chmod a+rw -R $dir
	rlRun "named -u named -fg -d10 -c $dir/named.conf.MASTER &>/$dir/named.conf.MASTER.log &" 0 "named on port 53"
	rlRun "named -u named -fg -d10 -c $dir/named.conf.STUB &>/$dir/named.conf.STUB.log &" 0 "named on port 51"
    rlPhaseEnd



    rlPhaseStartTest 'petr.god'
	rlRun "dig +short @127.0.0.1 -p 51  petr.god ds"
	rlRun "dig @127.0.0.1 -p 51 test1.petr.god +short | grep '192.168.122'"
	rlRun "dig @127.0.0.1 -p 51 dns.petr.god +short | grep '127'"
    rlPhaseEnd
sleep 1
    rlPhaseStartTest "debug logs"
	lines=`cat /$dir/named.conf.MASTER.log | wc -l`
	rlAssertGreater "log should be short" 1000 $lines 
	lines=`cat /$dir/named.conf.MASTER.log|wc -l`
	rlAssertGreater "log shold be short" 1000 $lines
	rlRun "grep -v 'Werror=' /$dir/named.conf.MASTER.log | grep -i error" 1 
	rlAssertGreater 'no more then one known' 3 `grep error //tmp/bind-for-petr/named.conf.STUB.log | wc -l`
	rlAssertGreater "only few known err" 7 `grep -i fail //tmp/bind-for-petr/named.conf.*.log | wc -l`
    rlPhaseEnd

    rlPhaseStartCleanup
	rlFileSubmit /$dir/named.conf.MASTER.log
	rlFileSubmit /$dir/named.conf.STUB.log	
	rm -rf $dir
	killall named
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
