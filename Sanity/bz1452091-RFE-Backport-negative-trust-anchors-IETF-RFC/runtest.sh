#!/bin/bash
# vim: dict=/usr/share/rhts-library/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Author: Petr Sklenar <psklenar@redhat.com>
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

. /usr/bin/rhts-environment.sh
. /usr/share/rhts-library/rhtslib.sh


rlJournalStart
    rlPhaseStartSetup Setup
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
	touch $ROOTDIR/etc/dlv.key
	rlRun "wget -O dlv.isc.org.named.conf http://ftp.isc.org/www/dlv/dlv.isc.org.named.conf"
	rlRun "cp -f named.conf $ROOTDIR/etc/named.conf"
	rlRun "chown root.named $ROOTDIR/etc/named.conf"
	rlRun "service named start"
	sleep 1
	rlRun "rndc nta -remove dlv.isc.org" 0,1

	rlRun "dig @127.0.0.1 gov SOA +dnssec| grep 'ANSWER: [^0]'" 1
	

# 20 sec it will be unchecked:
rndc nta -dump
	rlRun "rndc nta -lifetime 20 dlv.isc.org" 0 "20 second it will be uncheck "
rndc nta -dump
        rlRun "dig @127.0.0.1 gov SOA +dnssec | grep 'ANSWER: [^0]'" 0
rndc nta -dump
	rlRun "rndc nta -dump|grep dlv|grep expiry"
rndc nta -dump
# this time it fails as rndc nta --dump is empty
	sleep 60
rndc nta -dump
	rlRun "rndc nta -dump|grep dlv|grep expired"
rndc nta -dump
	rlRun 'date +"%d-%b-%Y %T.000"'
        rlRun "dig @127.0.0.1 gov SOA +dnssec | grep 'ANSWER: [^0]'" 1
rndc nta -dump
	rlRun "rndc nta -remove dlv.isc.org" 0,1
rndc nta -dump

	rlRun "cp dlv.isc.org.named.conf $ROOTDIR/etc/dlv.key"
	rlRun "rlServiceStart named"
	sleep 1
	rlRun "dig @127.0.0.1 gov SOA +dnssec | grep 'ANSWER: [^0]'" 0

    rlPhaseEnd

    rlPhaseStartCleanup Cleanup
	rlRun "service named stop"
	rlRun "rm -rf $TmpDir $ROOTDIR/etc/named.conf $ROOTDIR/etc/dlv.key"
	rlFileRestore
	rlServiceRestore named
    rlPhaseEnd
rlJournalPrintText
