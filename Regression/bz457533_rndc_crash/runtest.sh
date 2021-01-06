#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/bind/Regression/bz457533_rndc_crash
#   Description: Test for bz457533 (named crashes on incorrect usage of rndc reload)
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

	zone "pokus.cz" IN {
	  type master;
	  file "pokus.cz.zone";
	  allow-update { none; };
	};
	AEND

	cat <<-BEND > /var/named/pokus.cz.zone
	\$ORIGIN pokus.cz.
	\$TTL 86400
	@     IN     SOA    alena.pokus.cz. petra.pokus.cz. (
			    661134094  ; serial
			    21600      ; refresh after 6 hours
			    3600       ; retry after 1 hour
			    604800     ; expire after 1 week
			    86400 )    ; minimum TTL of 1 day

	      IN     NS     alena.pokus.cz.

	      IN     MX     10     alena.pokus.cz.

		     IN     A       192.168.33.33

	alena IN    A       192.168.44.44
	petra IN    A       192.168.55.55
	BEND

	rlRun "[ ! -z \"$ROOTDIR\" ] && cp /etc/named.conf $ROOTDIR/etc/ && cp /var/named/pokus.cz.zone $ROOTDIR/var/named/ || true"
	rlRun "chown named:named /etc/named.conf $ROOTDIR/etc/named.conf /var/named/*zone $ROOTDIR/var/named/*zone"
	rlRun "restorecon /etc/named.conf $ROOTDIR/etc/named.conf /var/named/*zone $ROOTDIR/var/named/*zone"
        bsBindSetupDone
    rlPhaseEnd

    rlPhaseStartTest
	rlRun "dig @localhost +short petra.pokus.cz | grep \"192.168.55.55\""
	rlRun "rndc reload pokus.cz | cat"
	rlRun "dig @localhost +short petra.pokus.cz | grep \"192.168.55.55\""
	rlRun "rndc reload asdfXXX.pokus.cz | cat" 0-255
	rlRun "dig @localhost +short petra.pokus.cz | grep \"192.168.55.55\""
    rlPhaseEnd

    rlPhaseStartCleanup
        rlRun "rm /var/named/pokus.cz.zone"
        rlRun "rm $ROOTDIR/var/named/pokus.cz.zone"
        bsBindSetupCleanup
        rlRun "popd"
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
    rlPhaseEnd

rlJournalEnd
