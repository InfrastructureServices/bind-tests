#!/bin/sh

# Copyright (c) 2006 Red Hat, Inc. All rights reserved. This copyrighted material 
# is made available to anyone wishing to use, modify, copy, or
# redistribute it subject to the terms and conditions of the GNU General
# Public License v.2.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
# PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# Author: Jan Hutar <jhutar@redhat.com>

# source the test script helpers
. /usr/bin/rhts-environment.sh

set -o pipefail

exec 5>&1 6>&2
exec >> ${OUTPUTFILE} 2>&1

RESULT=FAIL
SCORE=0




# Just to ensure named is stopped
service named stop &>/dev/null
umount /var/named/chroot/proc &> /dev/null

# Create our own simple configuration
rhts-backup /var/named/chroot/etc/named.conf
ips=$( grep "^nameserver" /etc/resolv.conf | sed "s/^nameserver[ \t]\+\([0-9.]\+\)/\1;/" )
cat > /var/named/chroot/etc/named.conf << EOC
options {
        forwarders { $ips };
        recursion yes;
};
EOC

echo "# Checking mounted /proc (should be mounted once)"
grep "/proc" /proc/mounts | tee proc_before
[ $? -ne 0 ] && SCORE=$( expr $SCORE + 1 )

echo "# Starting named"
service named start &> /dev/null && echo "# service named start ... OK"

echo "# Checking if bind works"
dig www.google.com +short @localhost
[ $? -ne 0 ] && SCORE=$( expr $SCORE + 1 )

echo "# Just listing mounted /proc"
grep "/proc" /proc/mounts | tee proc_while
# We do not want to check to carefully - new bind proc-mount are hidden
#[ $? -ne 0 ] && SCORE=$( expr $SCORE + 1 )

echo "# Stopping named"
service named stop &> /dev/null && echo "# service named stop ... OK"

echo "# Checking mounted /proc (again should be mounted only once)"
grep "/proc" /proc/mounts | tee proc_after
[ $? -ne 0 ] && SCORE=$( expr $SCORE + 1 )

echo "# Comparing 'before' and 'after' state"
diff -u proc_before proc_after
if cmp proc_before proc_after; then
  echo "# ... OK"
else
  echo "# ... NO (they differs!)"
  SCORE=$( expr $SCORE + 1 )
fi

[ $SCORE -eq 0 ] && RESULT=PASS
echo "===== $RESULT ($SCORE) ====="

exec 1>&5 2>&6





rm -rf /etc/rndc.key
rm -rf /var/named/chroot/etc/named.conf
rm -rf /var/named/data/named.run

report_result $TEST $RESULT $SCORE
