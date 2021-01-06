#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/bind/Regression/bz1720703-Latest-bind-9-9-update-now-causes-zone-transfer
#   Description: Test for BZ#1720703 (Latest bind (9.9) update now causes zone transfer)
#   Author: Petr Mensik <pemensik@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2019 Red Hat, Inc.
#
#   This program is free software: you can redistribute it and/or
#   modify it under the terms of the GNU General Public License as
#   published by the Free Software Foundation, either version 2 of
#   the License, or (at your option) any later version.
#
#   This program is distributed in the hope that it will be
#   useful, but WITHOUT ANY WARRANTY; without even the implied
#   warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
#   PURPOSE.  See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program. If not, see http://www.gnu.org/licenses/.
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Include Beaker environment
. /usr/bin/rhts-environment.sh || exit 1
. /usr/share/beakerlib/beakerlib.sh || exit 1

PACKAGE="bind"
TIMEOUT=60

transfer_test()
{
	FILE=$1.db
	RECORDS=$2
	[ "$1" = '.' ] && FILE=root.db

	rlRun "rlWatchdog \"dig @localhost -t AXFR -q $1 > $FILE\" $TIMEOUT TERM" 0 "Transfer zone $1"
	rlRun "tail $FILE"
	rlRun "grep '^; Transfer failed' $FILE" 1 "Checking successful transfer"
	rlAssertGrep "^;; XFR size: ${RECORDS} records" "$FILE"
	rlRun "LINES=`grep -v '^;' $FILE | wc -l`" 0 "Count lines"
	rlAssertGreater "Checking enough records were fetched" $LINES $RECORDS
}

rlJournalStart
    rlPhaseStartSetup
        rlAssertRpm $PACKAGE
	rlAssertRpm $PACKAGE-utils

        rlRun "TmpDir=\$(mktemp -d)" 0 "Creating tmp directory"
	rlRun "rlFileBackup /etc/named.conf"
	rlRun "rlFileBackup /etc/sysconfig/named"
	rlRun "cp -f named.conf /etc/named.conf"
	rlRun "rlFileBackup --missing-ok /var/named/bigzone.zone"
	rlRun "cp -f bigzone.zone root.zone /var/named"
	if ! grep '^OPTIONS=' /etc/sysconfig/named
	then
		# Allow customization when testing, change only first time
		echo "OPTIONS='-d 7'" >> /etc/sysconfig/named
		rlLog "Changed default debug log level"
	fi
        rlRun "pushd $TmpDir"
	rlRun "rlServiceStart named"
    rlPhaseEnd

    rlPhaseStartTest
	rlRun -s "dig @localhost -t SOA -q xfr1.test" 0 "Checking zone is online"
	rlAssertGrep '^;.* status: NOERROR' "$rlRun_LOG"
	# do not translate IDN
	export IDN_DISABLE=1
	export CHARSET=ASCII
	transfer_test . 22492
	transfer_test xfr1.test 149653
	transfer_test xfr2.test 149653
    rlPhaseEnd

    rlPhaseStartCleanup
        rlRun "popd"
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
	rlFileRestore
	rlServiceRestore named
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
