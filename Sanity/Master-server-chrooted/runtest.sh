#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/tests/Sanity/Master-server-chrooted
#   Description: Run basic empty named-chroot service and try to resolve localhost on it
#   Author: Petr Mensik <pemensik@redhat.com>
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

test_service()
{
    local SERVICE="$1"
	rlRun "rlServiceStart $SERVICE"
	rlRun "dig @localhost localhost | grep '^localhost'"
	rlRun "dig @localhost -x 127.0.0.1 | grep 'PTR[[:space:]]\+localhost.$'" 0 "Reverse address works"
	rlRun "rlServiceRestore $SERVICE"
}

rlJournalStart
    rlPhaseStartSetup
        rlAssertRpm bind
	rlAssertRpm bind-utils
	rlAssertRpm bind-chroot
    rlPhaseEnd

    rlPhaseStartTest "Testing named"
    	test_service named
    rlPhaseEnd

    rlPhaseStartTest "Testing named-chroot"
    	test_service named-chroot
    rlPhaseEnd

    rlPhaseStartTest "Testing named-sdb-chroot"
	    if rpm -q bind-sdb-chroot; then
		test_service named-sdb-chroot
	    else
		rlLog "bind-sdb-chroot not installed, skipping it"
	    fi
    rlPhaseEnd

    rlPhaseStartCleanup
	# noop
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
