#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
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

PACKAGE=""
rpm -q bind && PACKAGE="bind"
rpm -q bind97 && PACKAGE="bind97"

rlJournalStart
    rlPhaseStartSetup
        rpm -q perl-Net-DNS-Nameserver || yum install -y perl-Net-DNS-Nameserver
        rlLog "`rpm -q perl-Net-DNS-Nameserver`"
        # package assertions
        rlAssertRpm $PACKAGE 
        rlAssertRpm rpm-build

        #tempdir
        rlRun "TMPDIR=\`mktemp -d\`" 0 "Creating tmp directory"
	rlRun "tar -xf CVE-2018-5740.tar.xz"
	rlRun "cp -r CVE-2018-5740 $TMPDIR"
        rlRun "pushd $TMPDIR"

	if rlIsRHEL 8 && dnf config-manager --help >/dev/null; then
		# Some build dependencies are not in repositories enabled
		# by default: libidn2-devel
		rlRun "dnf config-manager --set-enabled rhel-buildroot"
	fi

        # topdir
        if rlIsRHEL 3 || rlIsRHEL 4 || rlIsRHEL 5; then
                TOPDIR="/usr/src/redhat"
        else
                TOPDIR="/root/rpmbuild"
        fi

        # cleanup in topdir
        mkdir -p $TOPDIR/{BUILD,SOURCES,SPECS}
        rm -rf $TOPDIR/{BUILD,SOURCES,SPECS}/*

        # download src rpm
        rlFetchSrcForInstalled "$PACKAGE" 
        rlRun "rpm --define '_topdir $TOPDIR' -Uvh *rpm &> $TMPDIR/install.txt"
        rlRun "cd $TOPDIR/SPECS" 

	if which yum-builddep; then
		rlRun "yum-builddep -y *.spec"
	elif dnf builddep --help >/dev/null; then
		rlRun "dnf -y builddep *.spec"
	else
		rlWarn "there is nor yum-utils neither dnf-utils for install dependencies, ENJOY!"
	fi

        # stop bind if it is running
        service named stop
    rlPhaseEnd

    rlPhaseStartTest
        # rebuild from source
        rlRun "rpmbuild -ba *.spec &> $TMPDIR/build.txt"

        # the test
        rlRun "cd $TOPDIR/BUILD/bind*"

        rlLogInfo "Test takes place in `pwd`"

        rlRun "chown -R root ."

        rlRun "./bin/tests/system/ifconfig.sh up" 0 "Setup fake network interfaces."
	rlRun "pushd $TMPDIR/CVE-2018-5740"
	rlRun "bash reproduce.sh > /tmp/log.me"
        rlRun "bash reproduce.sh >> /tmp/log.me"
        rlRun "grep exiting /tmp/log.me" 1
        rlRun "grep 'ANSWER: 1' /tmp/log.me" 0
	rlLog "`echo log;cat /tmp/log.me`"
	rlRun "popd" 0 "back from CVE testdir"
        rlRun "./bin/tests/system/ifconfig.sh down" 0 "Remove fake network interfaces."

    rlPhaseEnd

    rlPhaseStartCleanup
        rlRun "popd"
        rlRun "rm -r $TMPDIR /tmp/log.me" 0 "Removing tmp directory"
    rlPhaseEnd
rlJournalEnd
