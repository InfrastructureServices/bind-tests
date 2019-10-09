#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/bind/Sanity/Run-internal-BIND-test-suite
#   Description: Run internal BIND test suite
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
#
# Usable variables:
# override make target to start testing on more threads
# MAKE_TEST='-j4 test'
# Do not clean existing build if already built
# REUSE_BUILD=y
# Make retest faster, skip build if possible
# QUICK=y

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

	#pwd
	ORIG=`pwd`
	FOUNDERROR=`mktemp`
	SETUP_SOFTHSM=`readlink -f setup-named-softhsm.sh`
	FILTER=`readlink -f bind-systest-filter.sh`

	TAG=generic
	if [ -f /etc/os-release ]; then
		# extract platform tag
		VERSION_ID=`(source /etc/os-release && echo ${ID}-${VERSION_ID})`
		TAG=`(source /etc/os-release && echo ${PLATFORM_ID#platform:})`
	else
		rlIsRHEL '6' && TAG=el6
	fi

	if [ -f "knownerror.$VERSION_ID" ]; then
		KNOWNERROR=`readlink -f knownerror.$VERSION_ID`
	elif [ -f "knownerror.$TAG" ]; then
		KNOWNERROR=`readlink -f knownerror.$TAG`
	elif [ -f "knownerror" ]; then
		KNOWNERROR=`readlink -f knownerror`
	fi

	if [ -n "$QUICK" ]; then
		REUSE_BUILD=y
		MAKE_TEST='test -j4'
	fi

        #tempdir
        rlRun "TMPDIR=\`mktemp -d\`" 0 "Creating tmp directory"
        rlRun "pushd $TMPDIR"

	if rlIsRHEL 8 && dnf config-manager --help >/dev/null; then
		# Some build dependencies are not in repositories enabled
		# by default: libidn2-devel, softshm
		dnf config-manager --set-enabled rhel-buildroot
		#not checking return code: 1mt and beaker uses different names for repo
	fi

        # topdir
        if rlIsRHEL 3 || rlIsRHEL 4 || rlIsRHEL 5; then
                TOPDIR="/usr/src/redhat"
        else
                TOPDIR="/root/rpmbuild"
        fi

        # cleanup in topdir
        mkdir -p $TOPDIR/{BUILD,SOURCES,SPECS}
	if [ "$REUSE_BUILD" != y ]
	then
	        rlRun "rm -rf $TOPDIR/{BUILD,SOURCES,SPECS}/*"
	else
		rlLog "Not cleaning previous build"
	fi

        # download src rpm
        rlFetchSrcForInstalled "$PACKAGE"
	if ! ls bind*.src.rpm; then
		rlRun "yumdownloader --source bind" 0 "Trying alternative fetch from repository"
		rlRun "rpm -i bind*.src.rpm"
	fi
	
        rlRun "rpm --define '_topdir $TOPDIR' -Uvh *rpm &> $TMPDIR/install.txt"
        rlRun "cd $TOPDIR/SPECS" 

	# softhsm is no longer in normal repository. Enable idm module on RHEL8 to make softhsm module available
	if rlIsRHEL 8
	then
		rlRun "dnf -y module enable idm:DL1"
	fi

	if dnf builddep --help >/dev/null; then
		rlRun "dnf -y builddep --nobest *.spec"
	elif which yum-builddep; then
		rlRun "yum-builddep -y *.spec"
	else
		rlWarn "there is nor yum-utils neither dnf-utils for install dependencies, ENJOY!"
	fi

        # stop bind if it is running
        service named stop
    rlPhaseEnd

    rlPhaseStartTest
	if [ "$REUSE_BUILD" = y ] && ls -1 "$TOPDIR/BUILD"/bind* > /dev/null
	then
		rlLog "Skipping bind build"
	else
        	# rebuild from source
	        rlRun "rpmbuild -ba *.spec &> $TMPDIR/build.txt" 0 "Building bind"
	fi

        # the test
        rlRun "cd $TOPDIR/BUILD/bind*"

        rlLogInfo "Test takes place in `pwd`"

        rlRun "chown -R root ."

	if [ -x "$SETUP_SOFTHSM" ]; then
		rlRun "eval $(bash $SETUP_SOFTHSM -A)" 0 "Preparing PKCS#11 token slot"
		rlRun "pkcs11-tokens" 0 "Testing token slot availability"
	else
		rlLog "PKCS#11 not initialized"
	fi

	if [ -d build ]; then
		BUILD=build
	else
		BUILD=.
	fi

        rlRun "./bin/tests/system/ifconfig.sh up" 0 "Setup fake network interfaces."

	# required by idna test 
	export LC_ALL=en_US.UTF-8

        rlRun "pushd $BUILD"
	# keep separate results on 9.11+
	rlRun "sed -e 's/testsummary.sh/& -n/' -i bin/tests/system/Makefile" 0 "Modify to keep results"
	# dlz test is broken because specific build way we use. It is supported only by named-sdb
	# but that is not even tested by testsuite
	rlRun "sed -e 's/ dlz / /' -i bin/tests/system/Makefile" 0 "Skip always failing dlz test"

	# Try to fix tssgsig failures on some machines, do not use system kerberos configuration
	export KRB5_CONFIG=/dev/null
	# Allow speedup by defining MAKE_TEST='test -j4' on multiprocessor machines
        rlRun "make ${MAKE_TEST:-test} &> $TMPDIR/test.txt" 0-255 "Perform the test."
	export -n KRB5_CONFIG

	# This would catch just errors on 9.11+
	if [ -f bin/tests/system/testsummary.sh ]; then
		FAILED_TESTS=`grep '^R:[a-z0-9_-][a-z0-9_-]*:FAIL' $TMPDIR/test.txt | cut -d':' -f2 | sort | xargs echo`
		if [ -n "$FAILED_TESTS" ]; then
			rlLog "Failed tests: $FAILED_TESTS"
			rlRun "tar czf $TMPDIR/failed-artifacts.tar.gz -C bin/tests/system $FAILED_TESTS" 0 "Archiving failed artifacts in tests"
		else
			rlLog "No failed tests"
		fi
	else
		FAILED_TESTS=:any:
		rlRun "tar czf $TMPDIR/failed-artifacts.tar.gz bin/tests/system" 0 "Archiving all system tests"
	fi
        rlRun "popd"

        rlRun "grep -C 10 FAIL $TMPDIR/test.txt" 0-255 "Quickly show the test error (if any)."

        rlRun "./bin/tests/system/ifconfig.sh down" 0 "Remove fake network interfaces."


	#list of failures:
	rlRun "$FILTER $TMPDIR/test.txt" 0 "Showing unsuccessful tests"
	rlRun "$FILTER -s $TMPDIR/test.txt > $FOUNDERROR" 0
	rlRun "ls $KNOWNERROR $FOUNDERROR $TMPDIR/test.txt" 0 'check if there are needed files'
	rlLog "`echo list;cat $FOUNDERROR`"

	FAILED_FOUND="$(grep '^FAIL' $FOUNDERROR | wc -l)"
	FAILED_KNOWN="$(wc -l <$KNOWNERROR)"
	rlAssertLesserOrEqual "Checking number of found errors is in limits" "$FAILED_FOUND" "$FAILED_KNOWN"
        cat $FOUNDERROR | while read STATUS TEST ; do
		if [ "$STATUS" = FAIL ]; then
			rlRun "grep '$TEST' $KNOWNERROR" 0 "Check $TEST failure is expected"
		else
			rlLog "$STATUS $TEST"
		fi
        done

	if [ "$FAILED_TESTS" = ':any:' ] && [ "$FAILED_FOUND" -le "$FAILED_KNOWN" ]
	then
		# Newer version produces archive only when some error occured
		rlLog "No error found, not uploading artifacts"
		rm -f "$TMPDIR/failed-artifacts.tar.gz"
	fi
    rlPhaseEnd

   rlPhaseStartCleanup "`echo RESULT_ ;cat $FOUNDERROR|grep 'FAIL'`"
	#this phase is only due to report to webUI without needs of open file
	rlLog "`echo RESULT_ ;cat $FOUNDERROR|grep FAIL`"
   rlPhaseEnd

    rlPhaseStartCleanup
        rlBundleLogs "TEST_LOGS" "$TMPDIR/install.txt" "$TMPDIR/builddeps.txt" "$TMPDIR/build.txt" "$TMPDIR/test.txt"
	if [ -r "$TMPDIR/failed-artifacts.tar.gz" ]; then
		rlFileSubmit "$TMPDIR/failed-artifacts.tar.gz" failed-artifacts.tar.gz
	fi
        rlRun "popd"
        rlRun "rm -r $TMPDIR" 0 "Removing tmp directory"
	rlRun "rm -rf $FOUNDERROR"
    rlPhaseEnd
rlJournalEnd
