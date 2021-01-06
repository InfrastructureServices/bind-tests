#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/bind/Regression/bz1592872-rpm-V-bind-bind-chroot-shows-some-file
#   Description: Test for BZ#1592872 (rpm -V bind bind-chroot shows some file)
#   Author: Ondrej Mejzlik <omejzlik@redhat.com>
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

PACKAGE=${PACKAGE:-bind}
CHROOTPKG="$PACKAGE-chroot"
SERVICE="named${CHROOTPKG#bind}"

rlJournalStart
    rlPhaseStartSetup
        rlAssertRpm $PACKAGE
        if [ $? -ne 0  ]; then
            rlDie "Package $PACKAGE not installed"
        fi
        rlAssertRpm $CHROOTPKG
        if [ $? -ne 0  ]; then
            rlDie "Package $CHROOTPKG not installed"
        fi
        rlLog "PC name: $(hostname)"
        rlRun "TmpDir=\$(mktemp -d)" 0 "Creating tmp directory"
        rlRun "pushd $TmpDir"
    rlPhaseEnd

    rlGetTestState && {
    rlPhaseStartTest
        # RHEL8 changes creation of devices to on demand when service is started. It needs to be
        # checked with service started and stopped.
        # rpm -V returns 0 if the output is empty.
        rlRun "rpm -V $CHROOTPKG >& output-clean.txt" 0 "Getting rpm -V bind-chroot output"
        rlServiceStart $SERVICE
        sleep 1
        rlRun "rpm -V $CHROOTPKG >& output-running.txt" 0
        rlServiceStop $SERVICE
        sleep 1
        rlRun "rpm -V $CHROOTPKG >& output-stopped.txt" 0

        for OUTPUT in output-clean.txt output-running.txt output-stopped.txt; do
            rlRun "test -s $OUTPUT" 1 "There should be nothing in the $OUTPUT"
            ls -l $OUTPUT
            cat $OUTPUT
        done
	
    rlPhaseEnd
    }

    rlPhaseStartCleanup
	rlServiceRestore $SERVICE
        #rlBundleLogs $PACKAGE output-clean.txt output-running.txt output-stopped.txt
        rlRun "popd"
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
