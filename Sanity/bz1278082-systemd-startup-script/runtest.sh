#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/bind/Sanity/bz1278082-systemd-startup-script
#   Description: it moves conf file into chroot environment and start via systemd
#   Author: Petr Sklenar <psklenar@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2016 Red Hat, Inc.
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

CONF="/etc/named.conf"

rlJournalStart
    rlPhaseStartSetup
        rlAssertRpm bind-chroot
        rlAssertRpm bind-sdb-chroot
#try smth temporary:
        /bin/cp -af /usr/share/doc/bind-*/named.conf.default $CONF
        rlFileBackup $CONF
        rlFileBackup --clean /var/named/chroot/$CONF /var/named/chroot_sdb/$CONF
	pkill named
	sleep 2
	rlServiceStop named-chroot
	rlServiceStop named-sdb-chroot
    rlPhaseEnd

    rlPhaseStartTest
        rlRun "cp -af $CONF /var/named/chroot/etc/."
        rlRun "rlServiceStart named-chroot"       
	rlServiceStop named-chroot 
        rlFileRestore
    rlPhaseEnd

    rlPhaseStartTest
        rlRun "cp -af $CONF /var/named/chroot_sdb/etc/."
        rlRun "rlServiceStart named-sdb-chroot"        
	rlServiceStop named-sdb-chroot
        rlFileRestore
    rlPhaseEnd

    rlPhaseStartCleanup
	restorecon -R /var/named
        rlServiceRestore named-chroot
        rlServiceRestore named-sdb-chroot
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
