#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/bind/Sanity/max-recursion-queries
#   Description: max-recursion-queries
#   Author: Petr Sklenar <psklenar@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2014 Red Hat, Inc.
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
        rlRun 'rpm -q bind || rpm -q bind97' 0 "Checking for presence of bind or bind97 RPM"
        rlFileBackup /etc/named.conf
    rlPhaseEnd

    rlPhaseStartTest "this should be OK"
        rlRun "cp named1.conf /etc/named.conf"
        rlServiceStart named
        rlRun "dig @localhost www.ibm.com|grep akamaiedge"
    rlPhaseEnd

    rlPhaseStartTest "there should be no ANSWER"
        rlRun "cp named2.conf /etc/named.conf"
        rlServiceStart named
        rlRun "dig @localhost www.ibm.com" >0
        rlRun "dig @localhost www.ibm.com|grep akamaiedge" 1
    rlPhaseEnd

    rlPhaseStartCleanup
        rlFileRestore
        rlServiceRestore named
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd

