#!/usr/bin/python3

import ply.yacc
import isc.parsetab

p_ver = ply.yacc.__tabversion__
i_ver = isc.parsetab._tabversion
print('tabversions: ply {p_ver} == isc {i_ver}: {result}'.format(
        p_ver=p_ver, i_ver=i_ver, result=(p_ver == i_ver)))
assert(p_ver == i_ver)
