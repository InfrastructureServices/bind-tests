#!/usr/bin/python

from __future__ import print_function

from ctypes import *

lwres = CDLL("liblwres.so")
lwres.lwres_getrrsetbyname.argtypes = (c_char_p, c_int, c_int, c_int, c_void_p)

name = 3 * ("a" * 63 + ".") + "a" * 61
print("{0} ({1})".format(name, len(name)))
result = lwres.lwres_getrrsetbyname(name, 1, 1, 0, None)
print(result)
