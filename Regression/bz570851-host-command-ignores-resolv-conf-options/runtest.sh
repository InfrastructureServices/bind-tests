#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/bind/Regression/bz570851-host-command-ignores-resolv-conf-options
#   Description: Test for bz570851 (host command ignores resolv.conf options)
#   Author: Alex Sersen <asersen@redhat.com>
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

NEW_RESOLV="options timeout:1 attempts:1
nameserver 10.0.0.1"

declare -i START
declare -i END

rlJournalStart
    rlPhaseStartSetup
        if rpm -q bind97; then
                rlAssertRpm bind97-chroot
                rlAssertRpm bind97-utils
        else
                rlAssertRpm bind-chroot
                rlAssertRpm bind-utils
        fi
	cat /etc/resolv.conf > /tmp/el8debug
	rlFileBackup --clean /etc/resolv.conf `readlink -f /etc/resolv.conf`
	rlRun "echo '${NEW_RESOLV}' > /etc/resolv.conf" 0 "Creating new resolv.conf"
	rlRun "START=`date +%s`"
	rlRun "host localhost" 1 "Running host on localhost"
	rlRun "END=`date +%s`"
	declare -i RESULT=`expr $END '-' $START`
	rlAssertGreater "(END-START)<=6" "6" "${RESULT}"
	cat /tmp/el8debug > /etc/resolv.conf
	rlFileRestore
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
