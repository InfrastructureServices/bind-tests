#!/bin/bash
# vim: dict=/usr/share/rhts-library/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/bind/Regression/bz491655-unknown-DLV-alghorithms-handling
#   Description: Test for bz491655 (bind doesn't handle unknown DLV algorithms well)
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
# rpm -Uvh http://nest.test.redhat.com/mnt/qa/scratch/pmuller/rhtslib/rhtslib.rpm

. /usr/bin/rhts-environment.sh
. /usr/share/rhts-library/rhtslib.sh

PACKAGE=""
rpm -q bind && PACKAGE="bind"
rpm -q bind97 && PACKAGE="bind97"


rlJournalStart
    rlPhaseStartSetup Setup
        rlAssertRpm $PACKAGE
	rlAssertRpm $PACKAGE-chroot
	. /etc/sysconfig/named
	rlServiceStop named
    rlFileBackup --clean /etc/named.conf /var/named/data/named.run /etc/rndc.key
	if [ -e $ROOTDIR/etc/named.conf ]; then
		rlFileBackup --clean $ROOTDIR/etc/named.conf 
		#BACKED=1
	fi
        rlRun "TmpDir=\`mktemp -d\`" 0 "Creating tmp directory"
	rlRun "chmod 777 $TmpDir" 0 "Chmodding Tmp"
    rlPhaseEnd

    rlPhaseStartTest Testing
        rlAssertExists $TmpDir
	rlRun "wget -O $ROOTDIR/etc/dlv.key http://ftp.isc.org/www/dlv/dlv.isc.org.named.conf" 0 "Downloading actual DLV key"
		cat $ROOTDIR/etc/dlv.key
	rlRun "cp -f named.conf $ROOTDIR/etc/named.conf" 0 "Inserting our named.conf"
	rlRun "chown root.named $ROOTDIR/etc/named.conf" 0 "Chowning"
		cat $ROOTDIR/etc/named.conf

	rlRun "service named start" 0 "Starting BIND"
		tail /var/log/messages

sleep 10
	rlRun "dig @127.0.0.1 gov SOA +dnssec >$TmpDir/output" 0 "Reproducer: Querying for .gov"
	rlLog "Query details in TESTOUT"
		echo "===== DIG output ====="
		cat $TmpDir/output
	rlAssertNotGrep "SERVFAIL" "$TmpDir/output"
	rlRun "service named stop" 0 "Stoping BIND"
    rlPhaseEnd

    rlPhaseStartCleanup Cleanup
	rlRun "rm -rf $TmpDir $ROOTDIR/etc/named.conf $ROOTDIR/etc/dlv.key" 0 "Cleaning up"
	#(($BACKED)) && rlFileRestore
	rlFileRestore
	rlServiceRestore named
    rlPhaseEnd
rlJournalPrintText
