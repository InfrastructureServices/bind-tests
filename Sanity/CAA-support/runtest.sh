#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/bind/Sanity/CAA-support
#   Description: sanity testing of CAA support
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
#. /usr/bin/rhts-environment.sh || exit 1
. /usr/share/beakerlib/beakerlib.sh || exit 1

PACKAGE="bind"

distribution_mcase__setup() {
    rlPhaseStartSetup
    rlAssertRpm $PACKAGE
    rlFileBackup --clean /var/named/zone.petr.god
    rlFileBackup --clean /var/named/zone.hi.ho
    rlFileBackup /etc/named.conf
    cp zone.petr.god /var/named/zone.petr.god
    cp zone.hi.ho /var/named/zone.hi.ho

    cat <<EOT >> /etc/named.conf
zone "petr.god." IN {
        type master;
        file "/var/named/zone.petr.god";
};

zone "hi.ho." IN {
        type master;
        file "/var/named/zone.hi.ho";
};
EOT
    rlRun "rlServiceStart named"
    rlPhaseEnd
}

distribution_mcase__test() {
    rlPhaseStartTest 'petr.god'
	rlRun "dig +short @127.0.0.1 caa01.petr.god CAA|grep 'policy'"
	rlRun "dig +short @127.0.0.1 caa02.petr.god CAA|grep 'Unknown'"
	rlRun "dig +short @127.0.0.1 caa03.petr.god CAA|grep 'tbs'"
	rlRun "dig +short @127.0.0.1 caa6.petr.god CAA | wc -l | grep 6"
    rlPhaseEnd

   rlPhaseStartTest 'hi.ho'
	rlRun "dig +short @127.0.0.1 caa.hi.ho CAA | grep issue"
	rlRun "dig +short @127.0.0.1 caa1.hi.ho CAA | grep 'mailto:security at example.com'"
	rlRun "dig +short @127.0.0.1 caa2.hi.ho CAA| grep 'http://iodef.example.com/'"
	
   rlPhaseEnd
}

distribution_mcase__cleanup() {
    rlPhaseStartCleanup
	rlFileRestore
	rlServiceRestore named
    rlPhaseEnd
}

rlJournalStart
    rlPhaseStartSetup init
        rlImport "distribution/mcase"
    rlPhaseEnd

    distribution_mcase__run -P

rlJournalPrintText
rlJournalEnd
