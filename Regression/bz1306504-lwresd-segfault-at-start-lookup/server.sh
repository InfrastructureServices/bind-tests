#!/bin/bash

lwresd -g -d 100 -c <(echo 'options { forwarders {  '$1'; }; }; lwres { search { a; }; };')
