#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/bind/Sanity/geoip-support
#   Description: it tries more ip address from more locations
#   Author: Petr Sklenar <psklenar@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2019 Red Hat, Inc.
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
	rlFileBackup /etc/named.conf /var/named/a  /var/named/b
    rlPhaseEnd

    rlPhaseStartSetup 'files'
	rlRun "cp named.conf /etc/named.conf"

	rlRun "cp a /var/named/a"
	rlRun "cp b /var/named/b"
	rlRun "cp c /var/named/c"
	chown root.named /var/named/a
	chown root.named /var/named/b
	chown root.named /var/named/c
	rlRun "rlServiceStart named"

    rlPhaseEnd

    rlPhaseStartSetup 'net'
	ip netns add blue
	ip link add cosi0 type veth peer name cosi1
	ip link set cosi0 netns blue
	ip addr add 4.3.2.1 dev cosi1
	ip addr add 222.19.68.0 dev cosi1

	rlRun 'ip a|grep 222.19.68.0'
	rlRun 'ip a|grep 4.3.2.1'

    rlPhaseEnd

    rlPhaseStartTest 'dig'
	rlRun "dig -b 4.3.2.1 @127.0.0.1 test1.petr.god +short | grep '1.1.1.1'"
	rlRun "dig -b 127.0.0.1 @127.0.0.1 test1.petr.god +short | grep '2.2.2.1'"
	rlRun "dig -b 222.19.68.0 @127.0.0.1 test1.petr.god +short | grep '3.3.3.1'"

	rlRun "dig -b 4.3.2.1 +short @127.0.0.1 geo.petr.god TXT | grep 'geo A'"
	rlRun "dig -b 222.19.68.0 +short @127.0.0.1 geo.petr.god TXT | grep 'geo C'"
	rlRun "dig -b 127.0.0.1 +short @127.0.0.1 geo.petr.god TXT | grep 'geo B'"
    rlPhaseEnd

#for i in `seq 1 100000`;do dig -b 4.3.2.1 @127.0.0.1 test1.petr.god +short & dig -b 127.0.0.1 @127.0.0.1 test1.petr.god +short & dig -b 222.19.68.0 @127.0.0.1 test1.petr.god +short & done


    rlPhaseStartCleanup
        ip netns del blue
	rlFileRestore
	rlServiceRestore named
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
