#!/usr/bin/python3

import re
import sys

path = "test.run"
verbose = False

class OffsetCounter:
    def __init__(self):
        self.offset = 0
        self.re_record = re.compile("^;[^; \t]")
        self.emptyline = False
        self.found = {}

    def addLine(self, line):
        if self.emptyline and line.rstrip() == '':
            return False
        else:
            if line.rstrip() == '':
                self.emptyline = True
            elif self.re_record.match(line):
                if verbose:
                    print('{0:6}: {1}'.format(self.offset, line),)
                self.found[self.offset] = line
            self.offset = self.offset + len(line)
            return True

if len(sys.argv)>1:
    path = sys.argv[1]

lines = {}

with open(path, "r") as f:
    counter = None
    for line in f:
        if line.startswith('received packet:'):
            if verbose:
                print("New Message")
            counter = OffsetCounter()
        elif counter != None:
            if not counter.addLine(line):
                lines.update(counter.found)
                counter = None
                if verbose:
                    print("End message")


def printLine(k, data=lines, prefix=''):
        print('{0}{1:6} {2}'.format(prefix, k, lines[k]),)
    

print("Found offsets")
prev = None
start = None
for k in sorted(lines.keys()):
    if prev==None or prev != k-1:
        if start != None and False:
            if True:
                print('Range: {0}-{1}'.format(start, k))
            else:
                printLine(start, lines, 'started at ')
                printLine(k, lines,     'ended at   ')
        start = k
        if verbose:
            printLine(k, lines)
    else:
        prev = k
    print('{0:5d}'.format(k))
    prev = k
