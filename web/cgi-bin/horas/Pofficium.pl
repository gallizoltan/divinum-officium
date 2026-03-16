#!/usr/bin/perl
use FindBin qw($Bin);

eval {
    local $SIG{ALRM} = sub { die "Timeout\n" };
    alarm 20;
    require "$Bin/officium.pl";
    alarm 0;
};
