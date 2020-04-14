#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/bind/Regression/named-allocates-new-memory-on-each-reload
#   Description: Test for BZ#1790879 (named allocates new memory on each reload)
#   Author: Robin Hack <rhack@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2020 Red Hat, Inc.
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
        rlRun "TmpDir=\$(mktemp -d)" 0 "Creating tmp directory"
        rlRun "pushd $TmpDir"

        rlRun "rlImport bind/bind-setup"
        bsBindSetupStart
        bsBindSetupDone
    rlPhaseEnd

    rlPhaseStartTest
        rlRun "systemctl restart named"

        # number of files should not grow so we are ok with start like that
        pmap -x $(pidof named) > bind_mem_map

        declare -i GIP_FILES
        declare -i GIP_FILES_REPEAT

        GIP_FILES=$(grep -c "\.mmdb" bind_mem_map)
        rndc reload

        for ((p=0; p < 10; ++p)); do
            pmap -x $(pidof named) > bind_mem_map
            rndc reload

            GIP_FILES_REPEAT=$(grep -c "\.mmdb" bind_mem_map)
            rlLogInfo "Mapped files: $GIP_FILES_REPEAT"
            rlAssertEquals "Should be same" "$GIP_FILES" "$GIP_FILES_REPEAT"
        done

    rlPhaseEnd

    rlPhaseStartCleanup
        bsBindSetupCleanup
        rlRun "popd"
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
