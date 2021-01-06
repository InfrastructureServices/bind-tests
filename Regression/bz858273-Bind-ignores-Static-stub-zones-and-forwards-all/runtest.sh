#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/bind/Regression/bz858273-Bind-ignores-Static-stub-zones-and-forwards-all
#   Description: Test for BZ#858273 (Bind ignores Static stub zones and forwards all)
#   Author: Branislav Blaskovic <bblaskov@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2012 Red Hat, Inc. All rights reserved.
#
#   This copyrighted material is made available to anyone wishing
#   to use, modify, copy, or redistribute it subject to the terms
#   and conditions of the GNU General Public License version 2.
#
#   This program is distributed in the hope that it will be
#   useful, but WITHOUT ANY WARRANTY; without even the implied
#   warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
#   PURPOSE. See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public
#   License along with this program; if not, write to the Free
#   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
#   Boston, MA 02110-1301, USA.
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Include Beaker environment
. /usr/bin/rhts-environment.sh || exit 1
. /usr/share/beakerlib/beakerlib.sh || exit 1

PACKAGE="bind"

rlJournalStart
    rlPhaseStartSetup
        rlAssertRpm $PACKAGE
        rlFileBackup --clean "/etc/named.conf" "/etc/rndc.key" "/var/named/data/named.run"
        rlRun "TmpDir=\$(mktemp -d)" 0 "Creating tmp directory"
        rlRun "cp named.conf $TmpDir/named.conf"
        rlRun "pushd $TmpDir"
        rlRun "cp named.conf /etc/named.conf"
    rlPhaseEnd

    rlPhaseStartTest
        rlRun "service named restart" 0 "Service named started successfully with forwarders"
    rlPhaseEnd

    rlPhaseStartCleanup
        rlServiceStop "named"
        rlRun "popd"
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
        rlFileRestore
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
