#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/bind/Regression/bz1112356-RRL-slip-behavior-is-incorrect-when-set-to-1
#   Description: Test for BZ#1112356 (RRL slip behavior is incorrect when set to 1)
#   Author: Tereza Cerna <tcerna@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2015 Red Hat, Inc.
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

    rlPhaseStartSetup
        rlAssertRpm $PACKAGE
        rlFileBackup /etc/named.conf
        rlFileBackup /etc/sysconfig/named
        rlFileBackup /var/named/data/named.run
        rlRun "cat named.conf > /etc/named.conf" 0 "Set /etc/named.conf"
        rlRun "echo \" \" > /etc/sysconfig/named" 0 "Stop writing in chroot"
        rlRun "echo \" \" > /var/named/data/named.run" 0 "Clear log file /var/named/data/named.run"
        rlRun "chown named:named /var/named/data/named.run" 0 "Setting the rights to named service"
        rlServiceStart named
    rlPhaseEnd

    rlPhaseStartTest
        for i in `seq 1 100`; do (dig @127.0.0.1 seznam.cz +ignore +retry=0 +time=5&); done
	sleep 15
        for i in `seq 1 100`; do (dig @127.0.0.1 seznam.cz +ignore +retry=0 +time=5&); done
	sleep 15
        rlAssertNotEquals "Slip response exists" `grep slip /var/named/data/named.run | wc -l` 0
        rlAssertEquals    "Drop response exists" `grep drop /var/named/data/named.run | wc -l` 0
        cat /var/named/data/named.run
    rlPhaseEnd

    rlPhaseStartCleanup
        sleep 5m
        rlFileRestore
        rlServiceRestore named
    rlPhaseEnd

rlJournalPrintText
rlJournalEnd
