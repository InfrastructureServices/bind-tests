#!/bin/bash
# vim: dict=/usr/share/rhts-library/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/bind/Regression/bz481803-unowned-directory
#   Description: Test for bz481803 (Unowned directory in bind-9.3.4-10.P1.el5.src.rpm)
#   Author: Matej Susta <msusta@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2009 Red Hat, Inc. All rights reserved.
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
. /usr/share/rhts-library/rhtslib.sh

rlJournalStart
    rlPhaseStartSetup
        if rpm -q bind97; then
                rlAssertRpm bind97-chroot
                rlAssertRpm bind97-utils
        else
                rlAssertRpm bind-chroot
                rlAssertRpm bind-utils
        fi
    rlPhaseEnd

    rlPhaseStartTest
        if rpm -q bind97; then
                rlRun "A=`rpm -q bind97-chroot`" 0
        else
                rlRun "A=`rpm -q bind-chroot`" 0
        fi
	rlRun "B=`rpm -qf /var/named/chroot/var/log`" 0
	rlAssertEquals "Check if bind-chroot package equals to the package owning /var/named/chroot/var/log" "$A" "$B"
    rlPhaseEnd

    rlPhaseStartCleanup
    rlPhaseEnd
rlJournalEnd
