#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/bind/Regression/bz441495_privileges
#   Description: Test for bz441495 (No reason for bind binaries to be protected)
#   Author: Martin Cermak <mcermak@redhat.com>
#
#   This test is a port of original written by psklenar to RHEL6.
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

PACKAGE="bind"

rlJournalStart
    rlPhaseStartSetup
        rlRun "TmpDir=\`mktemp -d\`" 0 "Creating tmp directory"
        rlRun "pushd $TmpDir"

        if rpm -q bind97; then
                rlAssertRpm bind97-chroot
                rlAssertRpm bind97-utils
        else
                rlAssertRpm bind-chroot
                rlAssertRpm bind-utils
        fi
    rlPhaseEnd

    rlPhaseStartTest
        rlLog "Checking privileges of executables..."
        for pkgitem in `rpm -ql bind | grep "/usr/sbin"`; do
            if [ -f $pkgitem ] && [ -x $pkgitem ]; then
                rlRun "ls -Hla $pkgitem | grep \"^-rwxr-xr-x\""
                rlRun "[ -u $pkgitem ]" 1
            fi
        done

        # Since rhel8 Thu Jul 12 2018 Petr Menšík <pemensik@redhat.com> - 32:9.11.3-15
        # Use new config file named-chroot.files for chroot setup (#1429656)
        ls -Hla /etc/named* | grep -v "\.key$" | grep "^-rw-r--r--.*named-chroot" > list2
        ls -Hla /etc/named* /etc/rndc.* | grep -v "\.key$" | grep "^-" > list1
        ls -Hla /etc/named* /etc/rndc.* | grep -v "\.key$" | grep "^-rw-r-----" >> list2
        rlRun "diff list1 list2" 0 "Checking privileges of configs, logs and other related files."

        ls -dHla /var/named | grep "^d" > list1
        ls -dHla /var/named | grep "^drwxr[w-]x--[T-]" > list2
        rlRun "diff list1 list2" 0 "Checking privileges of /var/named directory."

    rlPhaseEnd

    rlPhaseStartCleanup
        rlRun "popd"
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
    rlPhaseEnd
rlJournalEnd
