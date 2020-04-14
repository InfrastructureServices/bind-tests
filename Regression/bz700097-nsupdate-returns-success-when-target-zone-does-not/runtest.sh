#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/bind/Regression/bz700097-nsupdate-returns-success-when-target-zone-does-not
#   Description: Test for bz700097 (nsupdate returns success when target zone does not)
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


rlJournalStart
# according to bz758397, this shouldn't be run against bind97:
if rpm -q bind97 &> /dev/null; then
        rlPhaseStartTest
                rlAssertRpm bind97
                rlLogInfo "This test is not intended to rin with bind97, skipping."
        rlPhaseEnd
else
        rlPhaseStartSetup
                rlAssertRpm bind-utils
        rlPhaseEnd

        rlPhaseStartTest
                rlRun "nsupdate -g nsupdate.cmd" 1,2 "nsupdate should fail"
                rlRun "nsupdate nsupdate.cmd" 2 "nsupdate should fail with exitcode 2"
        rlPhaseEnd
fi
rlJournalPrintText
rlJournalEnd
