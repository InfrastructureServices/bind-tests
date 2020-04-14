#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/bind/Regression/bz451450_chroot_path
#   Description: Test for bz451450 (bind_chroot update overwrites user supplied)
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
. /usr/share/beakerlib/beakerlib.sh || exit 1

rpm -q bind97-libs && PACKAGE="bind97-chroot" || PACKAGE="bind-chroot"

rlJournalStart
    rlPhaseStartSetup
	rngd -r /dev/urandom
        rlRun "TmpDir=\`mktemp -d\`" 0 "Creating tmp directory"
        rlRun "pushd $TmpDir"

        rlAssertRpm $PACKAGE

        rlRun "rlImport bind/bind-setup"
        #rlRun "wget --quiet http://nest.test.redhat.com/mnt/qa/scratch/mcermak/bind-setup.tar.gz && tar xvzf bind-setup.tar.gz > /dev/null && . bind-setup/bind-setup.sh" 0 "Imported bind-setup functions."

        bsBindSetupStart "" "on"
        bsBindSetupDone
        rlServiceStop "named"
    rlPhaseEnd

    rlPhaseStartTest
        rlRun "TEMPFILE=`mktemp`"
        rlRun "cp /etc/sysconfig/named $TEMPFILE"
        rlRun "MYCHROOT=\`mktemp -d\`"
        rlRun "echo \"ROOTDIR=$MYCHROOT\" > /etc/sysconfig/named"
        if rlIsFedora; then
            rlRun "dnf -y reinstall $PACKAGE"
        else
            rlRun "yum -y reinstall $PACKAGE"
        fi
        rlRun "[ \"`grep ROOTDIR=$MYCHROOT /etc/sysconfig/named | wc -l`\" == \"1\" ]"
        rlRun "cp -f $TEMPFILE /etc/sysconfig/named"
        if rlIsFedora; then
            rlRun "dnf -y reinstall $PACKAGE"
        else
            rlRun "yum -y reinstall $PACKAGE"
        fi
    rlPhaseEnd

    rlPhaseStartCleanup
        bsBindSetupCleanup
        rlRun "popd"
        rlRun "rm -rf $TmpDir" 0 "Removing tmp directory"
        rlRun "rm -rf $MYCHROOT"
    rlPhaseEnd
rlJournalEnd
