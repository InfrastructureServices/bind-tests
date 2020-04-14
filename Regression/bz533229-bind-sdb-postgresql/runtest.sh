#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/bind/Regression/bz533229-bind-sdb-postgresql
#   Description: bz533229-bind-sdb-postgresql
#   Author: Martin Cermak <mcermak@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2011 Red Hat, Inc. All rights reserved.
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

rlJournalStart
    rlPhaseStartSetup
        rlAssertRpm 'bind'
        rlAssertRpm 'bind-sdb'
        rlAssertRpm 'bind-utils'
        rlAssertRpm 'postgresql'
        rlAssertRpm 'postgresql-server'
        rlFileBackup --clean "/var/lib/pgsql/data" "/etc/rndc.key" "/var/lib/pgsql/data/pg_hba.conf" "/etc/pg_hba.conf" "/etc/named.conf" "/etc/sysconfig/named"
        rlRun "TmpDir=\`mktemp -d\`" 0 "Creating tmp directory"
        rlRun "chmod a+rx $TmpDir"
        rlRun "ORIGPWD=`pwd`"
        rlRun "pushd $TmpDir"
    rlPhaseEnd

    rlPhaseStartTest
        rlRun "service postgresql initdb" 0,1
        rlRun "service postgresql restart"
cat > create.sql <<EOFA
DROP DATABASE IF EXISTS test;
DROP ROLE IF EXISTS test;
CREATE ROLE test WITH SUPERUSER LOGIN PASSWORD 'test';
CREATE DATABASE test WITH OWNER test;
EOFA
        rlRun "cat create.sql"
sleep 1m
        rlRun "su - postgres -c \"psql -f $TmpDir/create.sql \""
sleep 1m
        rlRun "service postgresql stop"
sleep 1m
        rlRun "test -f /var/lib/pgsql/data/pg_hba.conf"
sleep 1m
        rlRun "touch /etc/pg_hba.conf" # this may be changed after bz554280 is resolved...
        rlRun "ln -sf /var/lib/pgsql/data/pg_hba.conf /etc/pg_hba.conf"
cat > /etc/pg_hba.conf <<EOFB
local   all         all                               md5
host    all         all         127.0.0.1/32          md5
host    all         all         ::1/128               md5
EOFB
        rlRun "cat /etc/pg_hba.conf"
        rlRun "service postgresql start"

        rlRun "export PGUSER=test"
        rlRun "export PGPASSWORD=test"

cat > testing.zone <<EOFC
\$TTL 1H
@       SOA     localhost.      root.localhost. (       1
                                                3H
                                                1H
                                                1W
                                                1H )
        NS      localhost.
host1   A       192.168.2.1
host2   A       192.168.2.2
host3   A       192.168.2.3
EOFC
	sleep 2
        rlRun "zonetodb pgdb.net. testing.zone test test"
        # load the zone into the DB

        # some visual checking of the table contents
        rlRun "echo 'SELECT * FROM test;' | psql test"

        # configure bind
        rlRun "service named stop"

cat > /etc/named.conf <<EOFD
options {
        listen-on port 53 { 127.0.0.1; };
        allow-query     { localhost; };
        recursion no;
};

zone "pgdb.net." IN {
        type master;
        database "pgsql  test        test     localhost test   test";
        #                ^- DB name  ^-Table  ^-host    ^-user ^-password
};
EOFD

cat > /etc/sysconfig/named <<EOFE
ENABLE_SDB=yes
EOFE


        if rlIsRHEL "<7";then
            rlServiceStart named
        else
            rlServiceStart named-sdb
        fi

        # test it all together
        for i in `seq 1 3`; do
                rlRun "dig @localhost host$i.pgdb.net +short | grep \"192.168.2.$i\""
        done
        rlLogInfo "Following record is note defined:"
        rlRun "dig @localhost host4.pgdb.net +short | grep \"192.168.2.4\"" 1
    rlPhaseEnd

    rlPhaseStartCleanup
        rlServiceStop named
        rlServiceStop named-sdb
        rlServiceStop postgresql
        rlFileRestore
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
