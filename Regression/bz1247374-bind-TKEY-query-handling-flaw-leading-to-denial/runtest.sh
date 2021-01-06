#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/bind/Regression/bz1247374-bind-TKEY-query-handling-flaw-leading-to-denial
#   Description: Test for BZ#1247374 (bind TKEY query handling flaw leading to denial of)
#   Author: Petr Sklenar <psklenar@redhat.com>
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
	rlServiceStart named
	rlRun "service named status"
	rpm -qa | grep python| grep dns || yum install -y python\*-dns\*
    rlPhaseEnd

    rlPhaseStartTest
	python='python3'
	rlIsRHEL '<8' && python='python2'
        rlRun "$python CVE-2015-5477.py 127.0.0.1 53 &> log"
	rlLog "`echo XXXXXXXXXXXXXXXXXXXXXXX;cat log;echo XXXXXXXXXXXXXXXXXXXXXX`"
	rlRun "service named status"
    rlPhaseEnd

    rlPhaseStartCleanup
	rlServiceRestore named
	rm -rf log
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
