#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/bind/Regression/bz1426626-The-named-sdb-utility-raises-an-abort
#   Description: Test for BZ#1426626 (The named-sdb utility raises an abort())
#   Author: Andrej Dzilsky <adzilsky@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2018 Red Hat, Inc.
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

rlJournalStart
    rlPhaseStartSetup
        rlFileBackup --clean /var/named/chroot
        rlFileBackup /etc/sysconfig/named
        rlRun "TmpDir=\`mktemp -d\`" 0 "Creating tmp directory"
        rlRun "pushd $TmpDir"

        rlRun "rlImport bind/bind-setup"
        bsBindSetupStart

        rlRun "rm -rf /etc/named.conf $ROOTDIR/etc/named.conf /var/named/*zone $ROOTDIR/var/named/*zone"
	cat <<-AEND > /etc/named.conf
options {
    listen-on port 53 { 127.0.0.1; };
    directory       "/var/named";
    dump-file       "/var/named/data/cache_dump.db";
    statistics-file "/var/named/data/named_stats.txt";
    allow-query     { localhost; };
};

# Using resources outside of RH is not good idea
# but it doesn't matter in this case, even if this source will be not available
zone "ldap.forumsys.com" {
    type master;
    database "ldap ldap://54.196.176.103/cn=read-only-admin,dc=example,dc=com 172800";
}; 
AEND

	rlRun "[ ! -z \"$ROOTDIR\" ] && cp /etc/named.conf $ROOTDIR/etc/|| true"
	rlRun "chown named:named /etc/named.conf $ROOTDIR/etc/named.conf"
	rlRun "restorecon /etc/named.conf $ROOTDIR/etc/named.conf"
        bsBindSetupDone
    rlPhaseEnd

    rlPhaseStartTest
        bsBindSetupCleanup
        cat /var/log/messages | tail -15 > log.named-service-stop
        rlAssertNotGrep "Saved core dump" log.named-service-stop
    rlPhaseEnd

    rlPhaseStartCleanup
        rlRun "rm log.named-service-stop" 0 "Removing log file"
        rlRun "popd"
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
    rlPhaseEnd
rlJournalEnd
