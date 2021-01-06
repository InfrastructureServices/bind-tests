#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/bind/Regression/bz669163-empty-search-option-in-etc-resolv-conf-causes
#   Description: bz669163-empty-search-option-in-etc-resolv-conf-causes
#   Author: Martin Cermak <mcermak@redhat.com>
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

# Include rhts environment
. /usr/bin/rhts-environment.sh
. /usr/lib/beakerlib/beakerlib.sh

RESOLV="/etc/resolv.conf"

function testResolver() {
        rlRun "host $NSFQDN"
        rlRun "dig $NSFQDN +short"
}

rlJournalStart
    rlPhaseStartSetup
        rlAssertRpm "$( rpm -qf /usr/bin/dig )"
	cat /etc/resolv.conf > /tmp/a
        rlFileBackup "$RESOLV"

        # I'll rely on this:
        if ping -c 1 ns1.redhat.com; then
                rlRun "NSFQDN=ns1.redhat.com"
                rlRun "NSIP=$(host ns1.redhat.com | awk '{print $4}')"
        elif ping -c 1 ns2.redhat.com; then
                rlRun "NSFQDN=ns2.redhat.com"
                rlRun "NSIP=$(host ns2.redhat.com | awk '{print $4}')"
        elif ping -c 1 ns3.redhat.com; then
                rlRun "NSFQDN=ns3.redhat.com"
                rlRun "NSIP=$(host ns3.redhat.com | awk '{print $4}')"
        else
                rlRun "false" 0 "No nameserver reachable"
        fi

        rlRun "cat /etc/resolv.conf" 0 "SHOW INITIAL RESOLVER SETTINGS"

        rlLogInfo "Testcase 1"
cat > $RESOLV <<EOF
search
nameserver $NSIP
EOF
        rlRun "cat $RESOLV"
        testResolver

        rlLogInfo "Testcase 2"
cat > $RESOLV <<EOF
search foo.com
nameserver $NSIP
EOF
        rlRun "cat $RESOLV"
        testResolver

        rlLogInfo "Testcase 3"
cat > $RESOLV <<EOF
search

nameserver $NSIP
EOF
        rlRun "cat $RESOLV"
        testResolver

        rlFileRestore
	cat /tmp/a > /etc/resolv.conf
    rlPhaseEnd
rlJournalEnd
