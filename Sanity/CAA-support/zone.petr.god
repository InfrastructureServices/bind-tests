$ORIGIN petr.god.
@  1D  IN  SOA ns1.petr.god. hostmaster.petr.god. (
  2002022401 ; serial
  3H ; refresh
  15 ; retry
  1w ; expire
  3h ; minimum
 )
   IN  NS     ns1.petr.god. ; in the domain

ns1    IN A      192.168.122.178     
www    IN A      192.168.122.123
ftp    IN CNAME  www.petr.god.

caa01		3600	IN	CAA	0 issue "ca.petr.god\; policy=ev"
caa02		3600	IN	CAA	128 tbs "Unknown"
caa03		3600	IN	CAA	128 tbs ""
caa6       CAA 0 policy "policy"
caa6       CAA 128 path "path"
caa6       CAA 128 issuewild "issuewild"
caa6       CAA 128 iodef "iodef"
caa6       CAA 128 tbs "tbs"
caa6       CAA 128 auth "auth"
