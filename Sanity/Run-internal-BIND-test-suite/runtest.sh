#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of tests/Run-internal-BIND-test-suite
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

# Include rhts environment
. /usr/lib/beakerlib/beakerlib.sh

PACKAGE="bind"

# Set those variables to n to skip tests on variants
#DEFAULT_VARIANTS="normal pkcs11 sdb"
DEFAULT_VARIANTS="normal"
#TEST_VARIANTS="normal"

#
# Runs test suite and checks known errors
# Prepared to be repeated with another variants
run_testsuite()
{
	local RESULT_TEXT="$TMPDIR/test${NAMED_VARIANT}.txt"
	local FOUNDERROR=`mktemp found-XXXXXXXX.err`
	local KNOWNERROR=/dev/null

	if [ -f "$ORIG/knownerror${NAMED_VARIANT}.$TAG" ]; then
		KNOWNERROR=`readlink -f $ORIG/knownerror.$TAG`
	elif [ -f "$ORIG/knownerror${NAMED_VARIANT}" ]; then
		KNOWNERROR=`readlink -f $ORIG/knownerror`
	fi

	# Sometime it can fail. Report just failures that are not known
        rlRun "make test -j${CORES:-1} &> $RESULT_TEXT" 0-255 "Perform the test."
        rlRun "grep -C 10 FAIL $RESULT_TEXT" 0-255 "Quickly show the test error (if any)."

	rlRun "$FILTER $RESULT_TEXT" 0 "Showing unsuccessful tests"
	rlRun "$FILTER -s $RESULT_TEXT > $FOUNDERROR" 0
	rlRun "ls $KNOWNERROR $FOUNDERROR $RESULT_TEXT" 0 'check if there is needed files'
	rlLog "`cat $FOUNDERROR`"

	rlAssertLesserOrEqual "Checking number of found errors is in limits" "$(grep '^FAIL' $FOUNDERROR | wc -l)" "$(wc -l <$KNOWNERROR)"
        cat $FOUNDERROR | while read STATUS TEST ; do
		if [ "$STATUS" = FAIL ]; then
			rlRun "grep '$TEST' $KNOWNERROR" 0 "Check $TEST failure is expected"
		else
			rlLog "$STATUS $TEST"
		fi
        done
}

rlJournalStart
    rlPhaseStartSetup
        # package assertions
        rlAssertRpm $PACKAGE 
        rlAssertRpm rpm-build
        rlAssertRpm perl-Net-DNS-Nameserver

	#pwd
	ORIG=`pwd`
	SETUP_SOFTHSM=`readlink -f setup-named-softhsm.sh`
	FILTER=`readlink -f bind-systest-filter.sh`
	CORES=`grep 'processor\s*:' /proc/cpuinfo | wc -l`

	TAG=generic
	if [ -f /etc/os-release ]; then
		# extract platform tag
		TAG=`(source /etc/os-release && echo ${PLATFORM_ID#platform:})`
	fi

        #tempdir
        rlRun "TMPDIR=\`mktemp -d\`" 0 "Creating tmp directory"
        rlRun "pushd $TMPDIR"

        # topdir
	TOPDIR=`rpm -E '%{_topdir}'`

        # cleanup in topdir
        mkdir -p $TOPDIR/{BUILD,SOURCES,SPECS}
        rm -rf $TOPDIR/{BUILD,SOURCES,SPECS}/*

        # download src rpm
	if ! ls bind*.src.rpm; then
		rlRun "dnf --enablerepo='*-source' download --source bind" 0 "Fetch source from repository"
		rlRun "rpm -i bind*.src.rpm"
	fi
	
        rlRun "rpm --define '_topdir $TOPDIR' -Uvh *rpm &> $TMPDIR/install.txt"
        rlRun "cd $TOPDIR/SPECS" 

	rlRun "dnf -y builddep *.spec"

        # stop bind if it is running
        rlServiceStop named
    rlPhaseEnd

    rlPhaseStartTest
        # rebuild from source
        rlRun "rpmbuild -ba *.spec &> $TMPDIR/build.txt"

        # the test
        rlRun "cd $TOPDIR/BUILD/bind*"

        rlLogInfo "Test takes place in `pwd`"

        rlRun "chown -R root ."

	if [ -x "$SETUP_SOFTHSM" ]; then
		rlRun "eval \"$(bash $SETUP_SOFTHSM -A)\"" 0 "Preparing PKCS#11 token slot"
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

	if echo "${TEST_VARIANTS:-$DEFAULT_VARIANTS}" | grep -q normal; then
		rlLog "Running normal variant"
		export NAMED_VARIANT= DNSSEC_VARIANT=
		run_testsuite
		rlLog "Finished normal variant"
	fi

	if echo "${TEST_VARIANTS:-$DEFAULT_VARIANTS}" | grep -q sdb; then
		rlLog "Running sdb variant"
		export NAMED_VARIANT=-sdb DNSSEC_VARIANT=
		run_testsuite
		rlLog "Finished sdb variant"
	fi

	if echo "${TEST_VARIANTS:-$DEFAULT_VARIANTS}" | grep -q pkcs11; then
		rlLog "Running pkcs11 variant"
		# Unfortunately, PKCS11 variant uses shared key storage
		# It cannot use more threads for that reason
		export NAMED_VARIANT=-pkcs11 DNSSEC_VARIANT=-pkcs11
		CORES=1 run_testsuite
		rlLog "Finished pkcs11 variant"
	fi

        rlRun "popd"

        rlRun "./bin/tests/system/ifconfig.sh down" 0 "Remove fake network interfaces."

    rlPhaseEnd

    rlPhaseStartCleanup
        rlBundleLogs "BUILD_LOGS" "$TMPDIR/install.txt" "$TMPDIR/builddeps.txt" "$TMPDIR/build.txt"
        rlBundleLogs "TEST_LOGS" "$TMPDIR"/test*.txt
        rlRun "popd"
        rlRun "rm -r $TMPDIR" 0 "Removing tmp directory"
    rlPhaseEnd
rlJournalEnd
