#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/bind/Regression/nslookup-doesn-t-try-to-search-the-search-in
#   Description: Test for BZ#1743572 (nslookup doesn't try to search the search in)
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

PACKAGE="bind-utils"

rlJournalStart
    rlPhaseStartSetup
	cat /etc/resolv.conf > /etc/resolv.conf.BAK
	echo 'search XXX' >> /etc/resolv.conf
	rlLog "`ls -la /etc/resolv.conf;cat /etc/resolv.conf`"
	rlRun "nslookup -debug n.x | grep XXX"
	rlRun "host -d nx.test | grep 'XXX'"
	rlRun "dig +showsearch nx.test | grep 'XXX'"
	cat /etc/resolv.conf.BAK > /etc/resolv.conf
	rlLog "`ls -la /etc/resolv.conf;cat /etc/resolv.conf`"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
