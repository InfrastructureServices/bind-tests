#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/bind/Regression/bz559524-host-should-return-non-zero-status-in-case-of
#   Description: Test for bz559524 (host should return non-zero status in case of)
#   Author: Martin Cermak <mcermak@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2010 Red Hat, Inc. All rights reserved.
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

# Include rhts environment
. /usr/bin/rhts-environment.sh
. /usr/lib/beakerlib/beakerlib.sh

rlJournalStart
    rlPhaseStartSetup
        if rpm -q bind97; then
                rlAssertRpm bind97-chroot
                rlAssertRpm bind97-utils
        else
                rlAssertRpm bind-chroot
                rlAssertRpm bind-utils
        fi

        service named stop
    rlPhaseEnd

    rlPhaseStartTest
        rlRun "host -l foo.bar 127.0.0.1" 1 "Ensure the bug is fixed"
    rlPhaseEnd

    rlPhaseStartCleanup
        #rlServiceRestore named
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
