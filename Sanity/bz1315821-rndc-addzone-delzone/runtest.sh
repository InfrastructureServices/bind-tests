#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/bind/Sanity/bz1315821-rndc-addzone-delzone
#   Description: Test for BZ#1315821 (rndc addzone/delzone unusable due to RPM packaging)
#   Author: Petr Sklenar <psklenar@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2018 Red Hat, Inc.
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

distribution_mcase__setup() {
    local zonefile
    zonefile=$(rpm -ql bind | grep empty | tail -n1)
    rm -rf /var/named/*nzf
    rlFileBackup /etc/named.conf
    rlRun "cat named.conf > /etc/named.conf"
    rlRun "cp -a $zonefile /var/named/delme.db"
    rlServiceStart named
    sleep 1
}

distribution_mcase__test() {
    local string=petr$RANDOM
    local db
    rndc addzone $string '{ type master; file "delme.db"; };'
    rlAssert0 "rndc addzone" $?
    db=$(ls /var/named/*nzf ||echo not_found)
    rlRun "grep $string $db"
    rndc delzone $string
    rlAssert0 "rndc delzone" $?
    rlRun "grep $string $db" 1
}

distribution_mcase__cleanup() {
    rm -rf /var/named/delme.db
    rlFileRestore
    rlServiceRestore named
}

rlJournalStart
    rlPhaseStartSetup init
        rlAssertRpm $PACKAGE
        rlImport "distribution/mcase"
    rlPhaseEnd
    distribution_mcase__run
rlJournalPrintText
rlJournalEnd
