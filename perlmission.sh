#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $SCRIPT_DIR

chmod 755 web/cgi-bin/horas
chmod 755 web/cgi-bin/missa
chmod 755 web/cgi-bin/horas/officium.pl
chmod 755 web/cgi-bin/horas/Pofficium.pl
chmod 755 web/cgi-bin/missa/missa.pl
chmod 755 web/cgi-bin/horas/kalendar.pl
