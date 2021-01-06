#!/bin/bash
#   runtest.sh of /CoreOS/bind/Regression/bz692758-When-named-is-started-the-working-directory-is
#   Description: Test for bz692758 (When named is started, "the working directory is)
#   Author: Juraj Marko <jmarko@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2011 Red Hat, Inc. All rights reserved.
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
. /usr/bin/rhts-environment.sh
. /usr/lib/beakerlib/beakerlib.sh

rpm -q bind97-libs && PACKAGE="bind97-chroot" || PACKAGE="bind-chroot"

rlJournalStart
    rlPhaseStartSetup
        rlAssertRpm $PACKAGE
        rlRun "TmpDir=\$(mktemp -d)" 0 "Creating tmp directory"
        rlFileBackup --clean "/etc/named.conf" "/var/named/data/named.run" "/etc/rndc.key"
        rlRun " cp ./named.conf /etc/named.conf" 0 "copy named.conf"
        rlRun "pushd $TmpDir"
        rlServiceStop named
    rlPhaseEnd

    rlPhaseStartTest
        rlFileBackup /var/log/messages
        rlServiceStart named
        rlServiceStop named
        rlRun "tail -n 100 /var/log/messages | grep \"the working directory is not writable\"" 1 "working  directory is writable"
    rlPhaseEnd

    rlPhaseStartCleanup
        rlFileRestore
        rlServiceRestore named
        rlRun "popd"
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd

