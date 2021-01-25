#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/bind/Sanity/install-dependencies
#   Description: Test bind-dyndb-ldap is still installable
#   Author: Petr Mensik <pemensik@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2021 Red Hat, Inc.
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
. /usr/share/beakerlib/beakerlib.sh || exit 1

PACKAGE="bind"
# dnsperf 2.4.0 no longer depends on bind.
# But should be installable anyway.
DEPENDENCIES="bind-dyndb-ldap dnsperf" #  freeipa-server-dns

rlJournalStart
    rlPhaseStartSetup
        rlAssertRpm $PACKAGE
	rlRun "VERSION=$(rpm -q $PACKAGE)"
    rlPhaseEnd

    rlPhaseStartTest
	for DEP in $DEPENDENCIES
	do
		rlRun "rpm -q $DEP" 1-255 "Make sure $DEP is not yet installed"
		rlRun "dnf install --best -y $DEP" 0 "Install $DEP"
		rlAssertRpm $DEP
	done
	rlAssertEqual "$PACKAGE version is unchanged" "$VERSION" "$(rpm -q $PACKAGE)"
    rlPhaseEnd

    rlPhaseStartCleanup
	for DEP in $DEPENDENCIES
	do
		rlRun "dnf remove -y $DEP"
	done
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
